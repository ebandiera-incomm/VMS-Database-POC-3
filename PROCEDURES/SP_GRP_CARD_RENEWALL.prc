CREATE OR REPLACE PROCEDURE VMSCMS.sp_grp_card_renewall
  (
    prm_inst_code NUMBER,
    prm_ins_date DATE,
   prm_branch_list renew_branch_array,
   prm_bin_list renew_bin_array,
    prm_remark VARCHAR2,
    prm_lupd_user NUMBER,
    prm_errmsg OUT VARCHAR2 )
IS
  /*************************************************
  * VERSION   :  1.0
  * Created Date  :  27/May/2010
  * Created By  :  Chinmaya Behera
  * PURPOSE   :  To handle all Renew Records
  * Modified By:  :
  * Modified Date  :
  ***********************************************/
  v_bran_cnt NUMBER;
  v_bin_cnt  NUMBER;
  v_rec_cnt  NUMBER DEFAULT 0;
  v_hsm_mode cms_inst_param.cip_param_value%TYPE;
  v_renew_param cms_inst_param.cip_param_value%TYPE;
  v_expiryparam cms_inst_param.cip_param_value%TYPE;
  v_from_date DATE;
  v_to_date DATE;
  v_expry_date DATE;
  v_emboss_flag cms_appl_pan.cap_embos_flag%TYPE;
  v_renew_reccnt     NUMBER DEFAULT 0;
  v_check_failed_rec NUMBER;
  v_renew_cnt        NUMBER;
  v_rencaf_fname     VARCHAR2 (90);
  v_errmsg           VARCHAR2 (300);
  v_pan_code cms_pan_acct.cpa_pan_code%TYPE;
  v_savepoint       NUMBER DEFAULT 0;
  --v_remark          VARCHAR2 (300) DEFAULT 'Renew';
  exp_reject_record EXCEPTION;
  v_record_exist    CHAR (1) := 'Y';
  v_caffilegen_flag CHAR (1) := 'N';
  v_issuestatus     VARCHAR2 (2);
  v_pinmailer       VARCHAR2 (1);
  v_cardcarrier     VARCHAR2 (1);
  v_pinoffset       VARCHAR2 (16);
  v_rec_type        VARCHAR2 (1);
  rec_cnt           NUMBER; 
  v_txn_code          VARCHAR2 (2);
  v_txn_type          VARCHAR2 (2);
  v_txn_mode          VARCHAR2 (2);
  v_del_channel       VARCHAR2 (2);                                      --added by amit on 07 Sep'10
  v_cardtype_profile_code CMS_PROD_CATTYPE.cpc_profile_code%TYPE; --added by amit on 08 Sep'10
  v_profile_code CMS_PROD_MAST.cpm_profile_code%TYPE;             --added by amit on 08 Sep'10
  v_expryparam CMS_BIN_PARAM.cbp_param_value%TYPE;                --added by amit on 08 Sep'10
  v_validity_period CMS_BIN_PARAM.cbp_param_value%type;           --added by amit on 08 Sep'10
  v_filter_count NUMBER;
  CURSOR c_renew_rec ( p_inst_code NUMBER, p_bran_code VARCHAR2, p_bin_code NUMBER, p_from_date DATE, p_to_date DATE )
  IS
    SELECT cap_pan_code,
      cap_card_stat,
      cap_prod_catg,
      cap_mbr_numb,
      cap_disp_name,
      cap_appl_bran,
      cap_expry_date,
      cap_acct_no,
      cap_prod_code,
      cap_card_type,
      cap_pan_code_encr
    FROM cms_appl_pan
    WHERE cap_inst_code              = p_inst_code
    AND TRUNC(cap_expry_date)       >= p_from_date
    AND TRUNC(cap_expry_date)       <= p_to_date
    AND cap_appl_bran                = p_bran_code
    AND SUBSTR (cap_pan_code, 1, 6) IN(p_bin_code)
    AND cap_prod_catg                in('D','A');
BEGIN --<< MAIN BEGIN >>
  --Sn get no of records in branch array
  v_bran_cnt := prm_branch_list.COUNT;
  DBMS_OUTPUT.put_line ('Branch count ' || v_bran_cnt);
  --En get no of records in branch array
  --Sn get no of records in BIN atrray
  v_bin_cnt := prm_bin_list.COUNT;
  DBMS_OUTPUT.put_line ('Bin count ' || v_bin_cnt);
  --En get no of records in BIN array
  --Sn get HSM detail
  --INSERT INTO RENEW_TEST VALUES(v_bran_cnt,v_bin_cnt,prm_ins_date);
  -- Rahul 28 Sep 05
  BEGIN
    SELECT cip_param_value
    INTO v_hsm_mode
    FROM cms_inst_param
    WHERE cip_param_key = 'HSM_MODE'
    AND cip_inst_code   = prm_inst_code;
    IF v_hsm_mode       = 'Y' THEN
      v_emboss_flag    := 'Y'; -- i.e. generate embossa file.
    ELSE
      v_emboss_flag := 'N'; -- i.e. don't generate embossa file.
    END IF;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_hsm_mode    := 'N';
    v_emboss_flag := 'N'; -- i.e. don't generate embossa file.
  END;
  --En get HSM detail
  --Sn get expiry parameter
  --BEGIN
  -- SELECT cip_param_value
  --     INTO v_expiryparam
  --    FROM cms_inst_param
  --WHERE cip_param_key = 'CARD EXPRY' AND cip_inst_code = prm_inst_code;
  --EXCEPTION
  --  WHEN NO_DATA_FOUND
  -- THEN
  --    prm_errmsg := 'Expiry parameter not defined in master';
  --    RETURN;
  -- WHEN OTHERS
  -- THEN
  --    prm_errmsg :=
  --           'Error while selecting expry parameter from master'
  --       || SUBSTR (SQLERRM, 1, 150);
  -- RETURN;
  --END;
  --En get expiry parameter
  --Sn get expiry parameter
  BEGIN
    SELECT cip_param_value
    INTO v_renew_param
    FROM cms_inst_param
    WHERE cip_param_key = 'RENEWCAF'
    AND cip_inst_code   = prm_inst_code;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    prm_errmsg := 'No of parameter for renewal CAF not defined in master';
    RETURN;
  WHEN OTHERS THEN
    prm_errmsg := 'Error while selecting renewal CAF parameter from master' || SUBSTR (SQLERRM, 1, 150);
    RETURN;
  END;
  --En get expiry parameter
  --Sn set date
  v_from_date := LAST_DAY (ADD_MONTHS (prm_ins_date, -1)) + 1;
  v_to_date   := LAST_DAY (prm_ins_date);
  --v_expry_date := LAST_DAY (ADD_MONTHS (prm_ins_date, v_expiryparam));
  --En set date
  --Sn Loop for branch
  rec_cnt:=0; --added by amit on 07 Sep'10
  FOR i  IN 1 .. v_bran_cnt
  LOOP
    DBMS_OUTPUT.put_line ('Branch No ' || prm_branch_list (i));
    --Sn loop for BIN
    FOR j IN 1 .. v_bin_cnt
    LOOP
      DBMS_OUTPUT.put_line ('BIN No ' || prm_bin_list (j));
      --Sn loop for no of cards
      INSERT
      INTO renew_test VALUES
        (
          prm_branch_list (i),
          prm_bin_list (j),
          prm_ins_date
        );
      
      FOR k IN c_renew_rec
      (
        prm_inst_code, prm_branch_list (i), prm_bin_list (j), v_from_date, v_to_date
      )
      LOOP
        REC_CNT:=REC_CNT+1; --added by amit on 07 Sep'10
        BEGIN               --<<CARD WISE LOOP>>
          v_savepoint := v_savepoint + 1;
          v_rec_cnt   := v_rec_cnt   + 1;
          SAVEPOINT v_savepoint;
          DBMS_OUTPUT.put_line
          (
            'Pan code ' || k.cap_pan_code
          )
          ;
          v_errmsg   := 'OK';
          prm_errmsg := 'OK';
          -------------------------------- Sn get Function Master----------------------------
               BEGIN
                  SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
                    INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
                    FROM cms_func_mast
                   WHERE cfm_func_code = 'RENEW' AND cfm_inst_code = prm_inst_code;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                               'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

          ------------------------------ En get Function Master----------------------------
          -----------------------Start to get profile code attached to card type--------------------------------------------------
          BEGIN
            SELECT cpm_profile_code,
              cpc_profile_code
            INTO v_profile_code,
              v_cardtype_profile_code
            FROM CMS_PROD_CATTYPE,
              CMS_PROD_MAST
            WHERE cpc_inst_code = prm_inst_code
            AND cpc_prod_code   = k.cap_prod_code
            AND cpc_card_type   = k.cap_card_type
            AND cpm_prod_code   = cpc_prod_code;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            prm_errmsg :='Profile code not defined for product code '|| k.cap_prod_code|| 'card type '|| k.cap_card_type;
            RAISE exp_reject_record;
          WHEN OTHERS THEN
            prm_errmsg :='Error while selecting profile attached to card type'|| SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
          END;
          -----------------------End to get profile code for card type---------------------------------------------------------------
          ---------------------Start to get validty for profile---------------------------------------------------------------------
          BEGIN
            SELECT cbp_param_value
            INTO v_expryparam
            FROM CMS_BIN_PARAM
            WHERE cbp_profile_code = v_cardtype_profile_code
            AND cbp_param_name     = 'Validity'
            AND cbp_inst_code      = prm_inst_code;
            IF v_expryparam       IS NULL THEN
              RAISE NO_DATA_FOUND;
            ELSE
              --Sn find validity period--
              BEGIN
                SELECT cbp_param_value
                INTO v_validity_period
                FROM CMS_BIN_PARAM
                WHERE cbp_profile_code = v_cardtype_profile_code
                AND cbp_param_name     = 'Validity Period'
                AND cbp_inst_code      = prm_inst_code;
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                prm_errmsg := 'Validity period is not defined for product cattype profile ' ;
                RAISE exp_reject_record;
              END;
              --En find validitty period--
            END IF;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            BEGIN
              SELECT cbp_param_value
              INTO v_expryparam
              FROM CMS_BIN_PARAM
              WHERE cbp_profile_code = v_profile_code
              AND cbp_param_name     = 'Validity'
              AND cbp_inst_code      = prm_inst_code;
              IF v_expryparam       IS NULL THEN
                RAISE NO_DATA_FOUND;
              ELSE
                --Sn find validity period--
                BEGIN
                  SELECT cbp_param_value
                  INTO v_validity_period
                  FROM CMS_BIN_PARAM
                  WHERE cbp_profile_code = v_profile_code
                  AND cbp_param_name     = 'Validity Period'
                  AND cbp_inst_code      = prm_inst_code;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  prm_errmsg := 'Validity period is not defined for product profile ' ;
                  RAISE exp_reject_record;
                END;
                --En find validitty period--
              END IF;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              prm_errmsg := 'No validity data found either product/product type profile ' ;
              RAISE exp_reject_record;
            WHEN OTHERS THEN
              prm_errmsg := 'Error while selecting validity data ' || SUBSTR(sqlerrm,1,200);
              RAISE exp_reject_record;
            END;
          WHEN OTHERS THEN
            prm_errmsg:='Error while selecting validity or validity period for profile '||SUBSTR(sqlerrm,1,200);
            RAISE exp_reject_record;
          END;
          ---------------------End to get validity for profile------------------------------------------------------------------------
          -------------------------------Start set date-------------------------------------------------------------------------------
          IF v_validity_period    = 'Hour' THEN
            v_expry_date         := sysdate + v_expryparam/24 ;
          ELSIF v_validity_period = 'Day' THEN
            v_expry_date         := sysdate + v_expryparam;
          ELSIF v_validity_period = 'Week' THEN
            v_expry_date         := sysdate + (7*v_expryparam);
          ELSIF v_validity_period = 'Month' THEN
            v_expry_date         := LAST_DAY (ADD_MONTHS (SYSDATE, v_expryparam - 1));
          ELSIF v_validity_period = 'Year' THEN
            v_expry_date         := LAST_DAY (ADD_MONTHS (SYSDATE, (12*v_expryparam) - 1));
          END IF;
          -------------------------------End set date----------------------------------------------------------------------------------
          --Sn generate a renewcaf file name
          IF v_renew_reccnt = 0 THEN
            sp_create_rencaffname (prm_inst_code, prm_lupd_user, v_rencaf_fname, v_errmsg );
            IF v_errmsg  != 'OK' THEN
              prm_errmsg := 'Error while creating filename -- ' || v_errmsg;
              RETURN;
            END IF;
          END IF;
          BEGIN
            SELECT COUNT (1)
            INTO v_filter_count
            FROM cms_ren_pan_temp
            WHERE crp_pan_code = k.cap_pan_code;
            IF v_filter_count  > 0 THEN
              v_errmsg:='Card '||k.cap_pan_code||' is filtered for the renewal process. ';
              RAISE exp_reject_record;
            END IF;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          END;
          --En generate a renewcaf file name
          --Sn check card status
          IF k.cap_card_stat <> '1' THEN
            v_errmsg         := 'Card is in not active ';
            RAISE exp_reject_record;
          END IF;
          --En check card status
          --Sn check failed records for duplicate processing
          BEGIN
            SELECT COUNT (*)
            INTO v_check_failed_rec
            FROM cms_cardrenewal_errlog
            WHERE cce_pan_code    = k.cap_pan_code
            AND cce_inst_code     = prm_inst_code;
            IF v_check_failed_rec > 0 THEN
              v_errmsg           := 'Record alredy failed in renew process ';
              RAISE exp_reject_record;
            END IF;
          EXCEPTION
          WHEN exp_reject_record THEN
            RAISE;
          WHEN OTHERS THEN
            v_errmsg := 'Error while checking record in history table' || SUBSTR (SQLERRM, 1, 150);
            RAISE exp_reject_record;
          END;
          --En check failed record for duplicate processing
          --Sn check account information
          BEGIN
            SELECT DISTINCT cpa_pan_code
            INTO v_pan_code
            FROM cms_pan_acct
            WHERE cpa_inst_code = prm_inst_code
            AND cpa_pan_code    = k.cap_pan_code;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_errmsg := 'Account not found in master ';
            RAISE exp_reject_record;
          WHEN OTHERS THEN
            v_errmsg := 'Error while selecting acct details ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
          END;
          --En check account information
          --Sn update expry date
          IF (v_hsm_mode = 'N') THEN
            UPDATE cms_appl_pan
            SET cap_expry_date   = v_expry_date,
              cap_next_bill_date = v_to_date,
              cap_lupd_date      = SYSDATE
            WHERE cap_inst_code  = prm_inst_code
            AND cap_pan_code     = k.cap_pan_code
            AND cap_mbr_numb     = k.cap_mbr_numb;
          ELSE
            UPDATE cms_appl_pan
            SET cap_expry_date   = v_expry_date,
              cap_next_bill_date = v_to_date,
              cap_lupd_date      = SYSDATE,
              cap_embos_flag     = 'Y'
            WHERE cap_inst_code  = prm_inst_code
            AND cap_pan_code     = k.cap_pan_code
            AND cap_mbr_numb     = k.cap_mbr_numb;
          END IF;
          --En update expry date
          IF SQL%ROWCOUNT = 0 THEN
            v_errmsg     := 'Error while updating expry date ';
            RAISE exp_reject_record;
          END IF;
          --Sn create a record in CAF
          /*DELETE
          FROM CMS_CAF_INFO
          WHERE cci_pan_code = DECODE(LENGTH(k.cap_pan_code), 16,k.cap_pan_code
          || '   ', 19,k.cap_pan_code)
          AND cci_mbr_numb  = k.cap_mbr_numb
          AND cci_inst_code = prm_inst_code;*/
          --Sn get caf detail
          BEGIN
            SELECT cci_rec_typ,
              cci_file_gen,
              cci_seg12_issue_stat,
              cci_seg12_pin_mailer,
              cci_seg12_card_carrier,
              cci_pin_ofst
            INTO v_rec_type,
              v_caffilegen_flag,
              v_issuestatus,
              v_pinmailer,
              v_cardcarrier,
              v_pinoffset
            FROM cms_caf_info
            WHERE cci_inst_code = prm_inst_code
            AND cci_pan_code    = DECODE (LENGTH (k.cap_pan_code), 16, k.cap_pan_code
              || '   ', 19, k.cap_pan_code ) --RPAD (prm_pancode, 19, ' ')
            AND cci_mbr_numb = k.cap_mbr_numb
            AND cci_file_gen = 'N'
              -- Only when a CAF is not generated
            GROUP BY cci_rec_typ,
              cci_file_gen,
              cci_seg12_issue_stat,
              cci_seg12_pin_mailer,
              cci_seg12_card_carrier,
              cci_pin_ofst;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_record_exist := 'N';
          WHEN OTHERS THEN
            prm_errmsg := 'Error while selecting caf details ' || SUBSTR (SQLERRM, 1, 300);
            RETURN;
          END;
          --En get caf detail
          --Sn delete record from CAF
          DELETE
          FROM cms_caf_info
          WHERE cci_inst_code = prm_inst_code
          AND cci_pan_code    = DECODE (LENGTH (k.cap_pan_code), 16, k.cap_pan_code
            || '   ', 19, k.cap_pan_code ) --RPAD (prm_pancode, 19, ' ')
          AND cci_mbr_numb = k.cap_mbr_numb;
          --En delete record from CAF
          sp_caf_rfrsh (prm_inst_code, k.cap_pan_code, '000', SYSDATE, 'C', NULL, 'RENEW', prm_lupd_user, k.cap_pan_code, v_errmsg );
          IF v_errmsg != 'OK' THEN
            v_errmsg  := 'Error while creating CAF record -- ' || v_errmsg;
            RAISE exp_reject_record;
          ELSE
            v_renew_reccnt   := v_renew_reccnt + 1;
            IF v_renew_reccnt = v_renew_param THEN
              v_renew_reccnt := 0;
            END IF;
            /*UPDATE CMS_CAF_INFO
            SET cci_file_name  = v_rencaf_fname
            WHERE cci_pan_code = DECODE(LENGTH(k.cap_pan_code), 16,k.cap_pan_code
            || '   ', 19,k.cap_pan_code)
            AND cci_mbr_numb  = k.cap_mbr_numb
            AND cci_inst_code = prm_inst_code;*/
            IF v_rec_type    = 'A' THEN
              v_issuestatus := '00'; -- no pinmailer no embossa.
              v_pinoffset   := RPAD ('Z', 16, 'Z');
              -- keep original pin .
            END IF;
            --Sn update caf info
            IF v_record_exist = 'Y' THEN
              BEGIN
                UPDATE cms_caf_info
                SET cci_seg12_issue_stat = v_issuestatus,
                  cci_seg12_pin_mailer   = v_pinmailer,
                  cci_seg12_card_carrier = v_cardcarrier,
                  cci_pin_ofst           = v_pinoffset,   -- rahul 10 Mar 05
                  cci_file_name          = v_rencaf_fname, --added by amit 20 sep'10
                  cci_file_gen           = 'R'            --added on 02 Nov'10 for renewcards no pin genereation
                WHERE cci_inst_code      = prm_inst_code
                AND cci_pan_code         = DECODE (LENGTH (k.cap_pan_code), 16, k.cap_pan_code
                  || '   ', 19, k.cap_pan_code ) --RPAD (k.cap_pan_code, 19, ' ')
                AND cci_mbr_numb = k.cap_mbr_numb;
                IF SQL%ROWCOUNT  = 0 THEN
                  v_errmsg      := 'Error while updating renewcaf file name';
                  RAISE exp_reject_record;
                END IF;
              EXCEPTION
              WHEN OTHERS THEN
                v_errmsg := 'Error updating CAF record ' || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
              END;
            ELSE
              UPDATE cms_caf_info
              SET cci_file_name   = v_rencaf_fname, --added by amit 20 sep'10
                  cci_file_gen    = 'R'            --added on 02 Nov'10 for renewcards no pin genereation
              WHERE cci_inst_code = prm_inst_code
              AND cci_pan_code    =DECODE(LENGTH (k.cap_pan_code),16, k.cap_pan_code
                || '   ',19, k.cap_pan_code) --RPAD (k.cap_pan_code, 19, ' ')
              AND cci_mbr_numb = k.cap_mbr_numb;
              IF SQL%ROWCOUNT  = 0 THEN
                v_errmsg      := 'Error while updating renewcaf file name';
                RAISE exp_reject_record;
              END IF;
            END IF;
            --En update caf info
          END IF;
          --En create a record in CAF
          --Sn create a record for successful record
          --Sn insert  record in ren tmp
          BEGIN
            INSERT
            INTO cms_ren_temp VALUES
              (
                k.cap_pan_code,
                k.cap_appl_bran,
                k.cap_card_stat,
                SUBSTR (k.cap_pan_code, 1, 6),
                'Y',
                TO_CHAR (v_from_date, 'MON-YYYY'),
                SYSDATE,
                prm_inst_code,
                prm_lupd_user,
                SYSDATE,
                prm_lupd_user,
                prm_remark,
                k.cap_pan_code_encr
              );
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'Error while inserting record in renewal temp' || SUBSTR
            (
              SQLERRM, 1, 200
            )
            ;
            RAISE exp_reject_record;
          END;
          --En insert a record in ren tmp
          --Sn create a record in pan support
          
          BEGIN
            INSERT
            INTO cms_pan_spprt
              (
                cps_inst_code,
                cps_pan_code,
                cps_mbr_numb,
                cps_prod_catg,
                cps_spprt_key,
                cps_spprt_rsncode,
                cps_func_remark,
                cps_ins_user,
                cps_lupd_user
              )
              VALUES
              (
                prm_inst_code,
                k.cap_pan_code,
                k.cap_mbr_numb,
                k.cap_prod_catg,
                'RENEW',
                1,
                prm_remark,
                prm_lupd_user,
                prm_lupd_user
              );
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'Error while inserting record in pan support' || SUBSTR
            (
              SQLERRM, 1, 200
            )
            ;
            RAISE exp_reject_record;
          END;
          --En create a record for successful record
          --Sn create a record in renew detail
          BEGIN
            INSERT
            INTO cms_renew_detail
              (
                crd_inst_code,
                crd_card_no,
                crd_file_name,
                crd_remarks,
                crd_msg24_flag,
                crd_process_flag,
                crd_process_msg,
                crd_process_mode,
                crd_ins_user,
                crd_ins_date,
                crd_lupd_user,
                crd_lupd_date
              )
              VALUES
              (
                prm_inst_code,
                k.cap_pan_code,
                NULL,
                prm_remark,
                'N',
                'S',
                'Successful',
                'G',
                prm_lupd_user,
                SYSDATE,
                prm_lupd_user,
                SYSDATE
              );
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'Error while inserting record in renew detail' || SUBSTR
            (
              SQLERRM, 1, 200
            )
            ;
            RAISE exp_reject_record;
          END;
          --En create a record in renew detail
          --Sn create a record in audit log
          BEGIN --8.
            INSERT
            INTO process_audit_log
              (
                pal_inst_code,
                pal_card_no,
                pal_activity_type,
                pal_transaction_code,
                pal_delv_chnl,
                pal_tran_amt,
                pal_source,
                pal_success_flag,
                pal_process_msg,
                PAL_SPPRT_TYPE,
                pal_ins_user,
                pal_ins_date,
                PAL_REMARKS
              )
              VALUES
              (
                prm_inst_code,
                k.cap_pan_code,
                'Renew',
                v_txn_code,
                v_del_channel,
                0,
                'HOST',
                'S',
                'Successful',
                'G',
                prm_lupd_user,
                SYSDATE,
                prm_remark
              );
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'Error while inserting record in audit detail' || SUBSTR
            (
              SQLERRM, 1, 200
            )
            ;
            RAISE exp_reject_record;
          END;
          --En create a record in audit log
        EXCEPTION --<<CARD WISE LOOP EXCEPTION>>
        WHEN exp_reject_record THEN
          ROLLBACK TO v_savepoint;
          sp_cardrenewal_errlog(
                                  prm_inst_code,
                                  k.cap_pan_code, 
                                  NULL,
                                  NULL,
                                  k.cap_disp_name, 
                                  k.cap_acct_no,
                                  k.cap_card_stat,
                                  k.cap_expry_date, 
                                  k.cap_appl_bran,
                                  'G',
                                  'E',
                                  v_txn_code,
                                  v_del_channel,
                                  v_errmsg,
                                  prm_lupd_user
                                );
        WHEN OTHERS THEN
          ROLLBACK TO v_savepoint;
          sp_cardrenewal_errlog(
                                  prm_inst_code, 
                                  k.cap_pan_code, 
                                  NULL,
                                  NULL,
                                  k.cap_disp_name,
                                  k.cap_acct_no, 
                                  k.cap_card_stat, 
                                  k.cap_expry_date, 
                                  k.cap_appl_bran, 
                                  'G', 
                                  'E',
                                  v_txn_code,
                                  v_del_channel, 
                                  v_errmsg, 
                                  prm_lupd_user
                              );
        END; --<<CARD WISE LOOP END>>
        --En generate a renewcaf file name
      END LOOP;
      --En loop for no of cards
    END LOOP;
    --En loop for BIN
  END LOOP;
  IF REC_CNT   =0 THEN --added by amit on 07 Sep'10
    prm_errmsg:='No record present for renewal process';
    RETURN;
  ELSE
    prm_errmsg := 'OK';
  END IF;
  --prm_errmsg := 'OK';
  --   IF v_rec_cnt = 0 THEN
  --      prm_errmsg := 'No record present for renewal process';
  --   ELSE
  --    prm_errmsg := 'OK';
  --   END IF;
  --En loop for branch
EXCEPTION --<< MAIN EXCEPTION >>
WHEN OTHERS THEN
  prm_errmsg := 'Error from main ' || SUBSTR
  (
    SQLERRM, 1, 200
  )
  ;
END; --<< MAIN END>>
/


