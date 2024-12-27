create or replace
PROCEDURE        VMSCMS.SP_MAS_BATCH_PROFILE_UPDATE (
   pfilename IN VARCHAR2          --removed In variable not used on 29/06/2013
                        --removed response out variable not used on 26/06/2013
   )
AS
   /*************************************************
        * Created  By      : NAILA UZMA
        * Created  Date    : 20-06-2013
        * REASON           : MEDAGATE HOST BATCHUPLOAD PROFILE UPDATE MVHOST : 394
        * Reviewer         : Dhiraj
        * Reviewed Date    : 25-06-2013
        * Release Number   : RI0024.2_B0008
        * Modified By      : Ramesh A
        * Modified Date    : 26-06-2013
        * REASON           : Exception handling and removed unwanted codes and added code for calling gpr_status procedure
        * Reviewer         : Dhiraj
        * Reviewed Date    : 27-06-2013
        * Build Number     : RI0024.2_B0009

       * Modified By      : Ramesh
       * Modified Date    : 28-Jun-2013
       * Modified for     : defect id :  0011432
       * Modified Reason  : BATCH UPLOAD- PROFILE UPLOAD THE MESSAGE 'Error while inserting mailing addr for custcode
                            Removed ptrandate and ptrantime , and added V_TRAN_DATE and V_TRAN_TIME
       * Reviewer         :
       * Reviewed Date    :
       * Build Number     : RI0024.2_B0011

       * Modified By      : Ramesh
       * Modified Date    : 04-July-2013
       * Modified for     : defect id :  11441
       * Modified Reason  : Batch Upload - Details in Transactiong log table and Transaction log detail table is incorrect
       * Reviewer         :
       * Reviewed Date    :
       * Build Number     : RI0024.3_B0003

        * Modified By      :Siva Kumar M
       * Modified Date    : 17-July-2013
       * Modified for     : defect id :  11441
       * Modified Reason  : Batch Upload - Details in Transactiong log table and Transaction log detail table is incorrect
       * Reviewer         :
       * Reviewed Date    :
       * Build Number     : RI0024.3_B0004

       * Modified By      :Naila
       * Modified Date    : 05-Aug-2013
       * Modified for     : defect id :11403 and 11451(Review Comments Changes)
       * Modified Reason  :
       * Reviewer         : Dhiraj
       * Reviewed Date    : 05-Aug-2013
       * Build Number     : RI0024.4_B0001

       * Modified By      : Ramesh A
       * Modified Date    : 12-DEC-2014
       * Modified Reason  : FSS-1961(Melissa)
       * Reviewer         : Spankaj
       * Build Number     : RI0027.5_B0002

        * Modified By      : Ramesh A
        * Modified Reason  : Perf changes
        * Modified Date    : 06/MAR/2015
        * Reviewer         : Saravanakumar
        * Reviewed Date    : 06/MAR/2015
        * Build Number     : 2.5

        * Modified by      :Spankaj
        * Modified Date    : 07-Sep-15
        * Modified For     : FSS-2321
        * Reviewer         : Saravanankumar
        * Build Number     : VMSGPRHOSTCSD3.2
        
        * Modified by       :T.Narayanaswamy
       * Modified Date    : 24-March-17
       * Modified For     : JIRA-FSS-4647 (AVQ Status issue)
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_17.03_B0003
	   
	   
	   	* Modified By      : Vini Pushkaran
    * Modified Date    : 14-MAY-2018
    * Purpose          : VMS 207 - Added new field to VMS_AUDITTXN_DTLS.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST_R01

    *************************************************/
   v_errmsg                      VARCHAR2 (300);
   v_appl_code                   cms_appl_mast.cam_appl_code%TYPE;
   v_respcode                    VARCHAR2 (5);
   v_rrn_count                   NUMBER;
   v_cust_code                   cms_cust_mast.ccm_cust_code%TYPE;
   v_age_check                   DATE;
   v_mailaddr_cnt                NUMBER (4);
   v_state_code                  gen_state_mast.gsm_state_code%TYPE;
   v_curr_code                   gen_cntry_mast.gcm_curr_code%TYPE;
   v_cntry_code                  gen_cntry_mast.gcm_cntry_code%TYPE;
   V_ACCT_NUMBER                 CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
   exp_reject_record             EXCEPTION;
   exp_main_reject_record        EXCEPTION;
   -- rec  CMS_BATCHUPLOAD_DETL%ROWTYPE;
   v_tran_desc                   VARCHAR2 (300);
   V_ACCT_BAL                    NUMBER (20, 3);
   V_LEDGER_BAL                  NUMBER (20, 3);
   V_HASH_PAN                    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
   V_ENCR_PAN                    CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
   v_txn_type                    VARCHAR (3);            --ADDED ON 29-07-2013
   v_cust_cnrty_phy              VARCHAR (3);           -- ADDED ON 06-08-2013
   v_cust_cnrty_mail             VARCHAR (3);           -- ADDED ON 06-08-2013
   v_savepoint                   NUMBER DEFAULT 0;
   --Added variables for calling gpr_status procedure on 26/06/2013
   V_PAN_NO                      VARCHAR2 (40);
   v_status_chk                  NUMBER;
   v_expry_date                  DATE;
   v_delivery_channel            NUMBER DEFAULT '05';
   v_applpan_cardstat            cms_appl_pan.cap_card_stat%TYPE;
   v_msg                         VARCHAR2 (4) DEFAULT '0200';
   v_prod_code                   cms_prod_mast.cpm_prod_code%TYPE;
   v_prod_cattype                cms_prod_cattype.cpc_card_type%TYPE;
   V_TRAN_DATE                   VARCHAR2 (8); --Added for logging data and time on 29/06/2013
   V_TRAN_TIME                   VARCHAR2 (8); --Added for logging data and time on 29/06/2013
   --Added for FSS-1961(Melissa)
   v_phys_switch_state_code      cms_addr_mast.cam_state_switch%TYPE;
   v_mailing_switch_state_code   cms_addr_mast.cam_state_switch%TYPE;
   V_AVQ_STATUS                  VARCHAR2 (1);
   V_CUST_ID                     CMS_CUST_MAST.CCM_CUST_ID%TYPE;
   V_FULL_NAME                   CMS_CUST_MAST.CCM_FIRST_NAME%TYPE;
   V_MAILADDR_LINEONE            VARCHAR2 (40);
   V_MAILADDR_LINETWO            VARCHAR2 (40);
   V_MAILADDR_CITY               VARCHAR2 (40);
   V_MAILADDR_ZIP                VARCHAR2 (40);
   V_MAILADDR_STATE              NUMBER (3);
   v_update_excp                 EXCEPTION;
   v_gprhash_pan                 CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
   v_gprencr_pan                 CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;

   --END Added for FSS-1961(Melissa)
   CURSOR batchPU
   IS
      SELECT *
        FROM CMS_BATCHUPLOAD_DETL
       WHERE CBD_FILE_NAME = pfilename AND CBD_RESPONSE_CODE = '00';
BEGIN
   -- OPEN batchPU;


   FOR rec IN batchPU
   LOOP
      -- EXIT WHEN batchPU%NOTFOUND;
      BEGIN
         v_errmsg := 'OK';
         v_respcode := '00';

         v_savepoint := v_savepoint + 1;
         SAVEPOINT v_savepoint;

         V_TRAN_DATE := TO_CHAR (SYSDATE, 'YYYYMMDD'); --Added for logging data and time on 29/06/2013
         V_TRAN_TIME := TO_CHAR (SYSDATE, 'HH24MISS'); --Added for logging data and time on 29/06/2013

             BEGIN
                SELECT CTM_TRAN_DESC,
                       TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1'))
                  INTO v_tran_desc, v_txn_type
                  FROM CMS_TRANSACTION_MAST
                 WHERE CTM_TRAN_CODE = rec.CBD_TRAN_CODE
                       AND CTM_DELIVERY_CHANNEL = '05';
             EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                   v_errmsg :=
                      'CTM_TRAN_DESC details not available in CMS_TRANSACTION_MAST';
                   v_respcode := '21';
                   RAISE exp_reject_record;
                WHEN OTHERS
                THEN
                   v_errmsg :=
                      'Error while fetching data from CMS_TRANSACTION_MAST '
                      || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.

                   v_respcode := '21';
                   RAISE exp_reject_record;
             END;

         BEGIN
            SELECT cap_cust_code, cap_appl_code, CAP_ACCT_NO --Modifid query on 26/06/2013
              INTO v_cust_code, v_appl_code, V_ACCT_NUMBER
              FROM cms_appl_pan
             WHERE     cap_inst_code = rec.CBD_INST_CODE
                   AND cap_proxy_number = rec.CBD_PROXY_NUMBER
                   AND ROWNUM = 1;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'PAN details not available in CMS_APPL_PAN';
               v_respcode := '21';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                  'Error while fetching data from pan master '
                  || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.

               v_respcode := '21';
               RAISE exp_reject_record;
         END;

         --St Modifid query on 26/06/2013
         BEGIN
            SELECT CAP_PAN_CODE,
                   CAP_PAN_CODE_ENCR,
                   fn_dmaps_main (cap_pan_code_encr),
                   cap_expry_date,
                   cap_card_stat,
                   cap_prod_code,
                   cap_card_type
              INTO V_HASH_PAN,
                   V_ENCR_PAN,
                   V_PAN_NO,
                   v_expry_date,
                   v_applpan_cardstat,
                   v_prod_code,
                   v_prod_cattype
              FROM CMS_APPL_PAN
             WHERE     CAP_PROXY_NUMBER = rec.CBD_PROXY_NUMBER
                   AND cap_inst_code = rec.CBD_INST_CODE
                   AND CAP_CARD_STAT NOT IN ('0', '9');
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  SELECT CAP_PAN_CODE,
                         CAP_PAN_CODE_ENCR,
                         fn_dmaps_main (cap_pan_code_encr),
                         cap_expry_date,
                         cap_card_stat,
                         cap_prod_code,
                         cap_card_type
                    INTO V_HASH_PAN,
                         V_ENCR_PAN,
                         V_PAN_NO,
                         v_expry_date,
                         v_applpan_cardstat,
                         v_prod_code,
                         v_prod_cattype
                    FROM CMS_APPL_PAN
                   WHERE     CAP_PROXY_NUMBER = rec.CBD_PROXY_NUMBER
                         AND cap_inst_code = rec.CBD_INST_CODE
                         AND CAP_CARD_STAT = '0';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     BEGIN
                        SELECT CAP_PAN_CODE,
                               CAP_PAN_CODE_ENCR,
                               fn_dmaps_main (cap_pan_code_encr),
                               cap_expry_date,
                               cap_card_stat,
                               cap_prod_code,
                               cap_card_type
                          INTO V_HASH_PAN,
                               V_ENCR_PAN,
                               V_PAN_NO,
                               v_expry_date,
                               v_applpan_cardstat,
                               v_prod_code,
                               v_prod_cattype
                          FROM CMS_APPL_PAN
                         WHERE     CAP_PROXY_NUMBER = rec.CBD_PROXY_NUMBER
                               AND cap_inst_code = rec.CBD_INST_CODE
                               AND CAP_CARD_STAT = '9'
                               AND ROWNUM < 2;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           V_RESPCODE := '165';
                           V_ERRMSG :=
                              'Invalid Proxy Number '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE EXP_MAIN_REJECT_RECORD;
                     END;
               END;
            WHEN OTHERS
            THEN
               V_RESPCODE := '165';
               V_ERRMSG := 'Invalid Proxy Number ' || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_MAIN_REJECT_RECORD;
         END;

         --En Modifid query on 26/06/2013
         
          --Sn Added for FSS-2321
            BEGIN
               INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
                    VALUES (rec.cbd_rrn, '05', rec.cbd_tran_code, v_cust_code,1);
            EXCEPTION
               WHEN OTHERS THEN
                  v_respcode := '21';
                  v_errmsg := 'Error while inserting audit dtls ' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;   
            --En Added for FSS-2321

         --Sn GPR Card status check on 26/06/2013
         BEGIN
            sp_status_check_gpr (rec.CBD_INST_CODE,
                                 V_PAN_NO,
                                 v_delivery_channel,
                                 v_expry_date,
                                 v_applpan_cardstat,
                                 rec.CBD_TRAN_CODE,
                                 '0',
                                 v_prod_code,
                                 v_prod_cattype,
                                 v_msg,
                                 V_TRAN_DATE, --Added for logging data and time on 29/06/2013
                                 V_TRAN_TIME, --Added for logging data and time on 29/06/2013
                                 NULL,
                                 NULL,
                                 NULL,
                                 V_RESPCODE,
                                 V_ERRMSG);

            IF ( (V_RESPCODE <> '1' AND V_ERRMSG <> 'OK')
                OR (V_RESPCODE <> '0' AND V_ERRMSG <> 'OK'))
            THEN
               RAISE exp_reject_record;
            ELSE
               v_status_chk := V_RESPCODE;
               V_RESPCODE := '00';  --Modified for defect : 11441 on 4/07/2013
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               V_RESPCODE := '21';
               V_ERRMSG :=
                  'Error from GPR Card Status Check '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En GPR Card status check
         IF v_status_chk = '1'
         THEN
            -- Expiry Check
            BEGIN
               IF TO_DATE (V_TRAN_DATE, 'YYYYMMDD') > --Added for logging data and time on 29/06/2013
                     LAST_DAY (TO_CHAR (v_expry_date, 'DD-MON-YY'))
               THEN
                  V_RESPCODE := '21';
                  V_ERRMSG := 'EXPIRED CARD';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  V_RESPCODE := '21';
                  V_ERRMSG :=
                     'ERROR IN EXPIRY DATE CHECK '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;

         -- End Expiry Check

         --En GPR Card status check on 26/06/2013

         BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL  --Modifid query on 26/06/2013
              INTO V_ACCT_BAL, V_LEDGER_BAL
              FROM CMS_ACCT_MAST
             WHERE CAM_ACCT_NO = V_ACCT_NUMBER;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'Account details not available in CMS_ACCT_MAST';
               v_respcode := '21';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                  'Error while fetching data from Account master '
                  || SUBSTR (SQLERRM, 1, 100); -- added sqlerrm on 05/Aug/2013 for review comments.

               v_respcode := '21';
               RAISE exp_reject_record;
         END;

         --- Master data Validation starts
         -- Physical state code check starts
         /*
           IF rec.CBD_PHYSTATE_CODE IS NOT NULL THEN --MODIFIED BY NAILA
          BEGIN
             SELECT  gsm_state_code  -- distinct has removerd  on 05/Aug/2013
               INTO v_state_code
               FROM gen_state_mast
              WHERE gsm_state_code = rec.CBD_PHYSTATE_CODE and GSM_INST_CODE = rec.CBD_INST_CODE  ;

          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                v_errmsg :=
                      'State code not available in master - Physical Address '
                   || rec.CBD_PHYSTATE_CODE;
                v_respcode := '21';
                RAISE exp_reject_record;
             WHEN OTHERS
             THEN
                v_errmsg :=
                      'Error while selecting state code - Physical Address'
                   || rec.CBD_PHYSTATE_CODE || SUBSTR(SQLERRM, 1, 200);  -- added sqlerrm on 05/Aug/2013 for review comments.

                v_respcode := '21';
                RAISE exp_reject_record;
          END;
        END IF;*/
         -- Modified Physical Address State Code check block to include Physical Address Country code condition ON 06-08-2013
         IF rec.CBD_PHYSTATE_CODE IS NOT NULL
         THEN
            IF rec.CBD_PHYCNTRY_CODE IS NULL
            THEN
               BEGIN
                  SELECT cam_cntry_code
                    INTO v_cust_cnrty_phy
                    FROM cms_ADDR_MAST
                   WHERE     cam_cust_code = v_cust_code
                         AND cam_inst_code = rec.CBD_INST_CODE
                         AND cam_addr_flag = 'P';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                        'Customer Code is not available in address mast - Customer Code '
                        || v_cust_code;
                     v_respcode := '21';
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        'Error while selecting Country Code from address master- Customer Code '
                        || v_cust_code
                        || SUBSTR (SQLERRM, 1, 200);

                     v_respcode := '21';
                     RAISE exp_reject_record;
               END;

               IF v_cust_cnrty_phy = '*' OR v_cust_cnrty_phy IS NULL
               THEN
                  v_errmsg :=
                     'Please specify country code for state -  Physical Address '
                     || rec.CBD_PHYSTATE_CODE;
                  v_respcode := '21';
                  RAISE exp_reject_record;
               ELSE
                  BEGIN
                     SELECT gsm_state_code
                       INTO v_state_code
                       FROM gen_state_mast
                      WHERE     gsm_state_code = rec.CBD_PHYSTATE_CODE
                            AND GSM_INST_CODE = rec.CBD_INST_CODE
                            AND gsm_cntry_code = v_cust_cnrty_phy;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                           'State code not available in master - Physical Address '
                           || rec.CBD_PHYSTATE_CODE;
                        v_respcode := '21';
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                           'Error while selecting state code - Physical Address'
                           || rec.CBD_PHYSTATE_CODE
                           || SUBSTR (SQLERRM, 1, 200);

                        v_respcode := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;

            IF rec.CBD_PHYCNTRY_CODE IS NOT NULL
            THEN
               BEGIN
                  SELECT gcm_cntry_code
                    INTO v_cntry_code
                    FROM gen_cntry_mast
                   WHERE gcm_inst_code = rec.CBD_INST_CODE
                         AND gcm_cntry_code = rec.CBD_PHYCNTRY_CODE;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                        'Country Code not available in the Master - Physical Address '
                        || rec.CBD_PHYCNTRY_CODE;
                     v_respcode := '21';
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'while fecthing Physical country code for cntry'
                        || rec.CBD_PHYCNTRY_CODE
                        || SUBSTR (SQLERRM, 1, 200);
                     v_respcode := '21';
                     RAISE exp_reject_record;
               END;

               BEGIN
                  SELECT gsm_state_code, GSM_SWITCH_STATE_CODE --Added for FSS-1961(Melissa)
                    INTO v_state_code, v_phys_switch_state_code --Added for FSS-1961(Melissa)
                    FROM gen_state_mast
                   WHERE     gsm_state_code = rec.CBD_PHYSTATE_CODE
                         AND GSM_INST_CODE = rec.CBD_INST_CODE
                         AND gsm_cntry_code = rec.CBD_PHYCNTRY_CODE;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                        'State code not available in master - Physical Address '
                        || rec.CBD_PHYSTATE_CODE;
                     v_respcode := '21';
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        'Error while selecting state code - Physical Address'
                        || rec.CBD_PHYSTATE_CODE
                        || SUBSTR (SQLERRM, 1, 200);

                     v_respcode := '21';
                     RAISE exp_reject_record;
               END;
            END IF;
         END IF;

         -- Physical state code check endz
         -- mailing address state code check starts
         /*IF rec.CBD_MLGSTATE_CODE  IS NOT NULL
         THEN
            BEGIN
               SELECT   gsm_state_code -- distinct has removerd  on 05/Aug/2013
                 INTO v_state_code
                 FROM gen_state_mast
                WHERE gsm_state_code = rec.CBD_MLGSTATE_CODE  and  gsm_cntry_code = rec.CBD_PHYCNTRY_CODE
                and GSM_INST_CODE = rec.CBD_INST_CODE ; --Modifid query on 26/06/2013

            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                        'State code not available in master -  Mailing address '
                     ||  rec.CBD_MLGSTATE_CODE;
                  v_respcode := '21';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting state  code - Mailing address:'
                     ||  rec.CBD_MLGSTATE_CODE || SUBSTR(SQLERRM, 1, 200);  -- added sqlerrm on 05/Aug/2013 for review comments.

                  v_respcode := '21';
                  RAISE exp_reject_record;
            END;
         END IF;
  */
         -- Modified Mailing Address State Code check block to include Mailing Address Country code condition ON 06-08-2013
         IF rec.CBD_MLGSTATE_CODE IS NOT NULL
         THEN
            IF rec.CBD_MLGCNTRY_CODE IS NULL
            THEN
               BEGIN
                  SELECT cam_cntry_code
                    INTO v_cust_cnrty_mail
                    FROM CMS_ADDR_MAST
                   WHERE     cam_cust_code = v_cust_code
                         AND cam_inst_code = rec.CBD_INST_CODE
                         AND cam_addr_flag = 'O';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                        'Please specify country code for state -  Mailing Address '
                        || rec.CBD_MLGSTATE_CODE;
                     v_respcode := '21';
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        'Error while selecting Country Code from address master- Customer Code '
                        || v_cust_code
                        || SUBSTR (SQLERRM, 1, 200);

                     v_respcode := '21';
                     RAISE exp_reject_record;
               END;

               IF v_cust_cnrty_mail = '*' OR v_cust_cnrty_mail IS NULL
               THEN
                  v_errmsg :=
                     'Please specify country code for state -  Mailing Address '
                     || rec.CBD_MLGSTATE_CODE;
                  v_respcode := '21';
                  RAISE exp_reject_record;
               ELSE
                  BEGIN
                     SELECT gsm_state_code, GSM_SWITCH_STATE_CODE --Added for FSS-1961(Melissa)
                       INTO v_state_code, v_mailing_switch_state_code --Added for FSS-1961(Melissa)
                       FROM gen_state_mast
                      WHERE     gsm_state_code = rec.CBD_MLGSTATE_CODE
                            AND GSM_INST_CODE = rec.CBD_INST_CODE
                            AND gsm_cntry_code = v_cust_cnrty_mail;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                           'State code not available in master - Mailing Address '
                           || rec.CBD_MLGSTATE_CODE;
                        v_respcode := '21';
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                           'Error while selecting state code - Mailing Address'
                           || rec.CBD_MLGSTATE_CODE
                           || SUBSTR (SQLERRM, 1, 200);

                        v_respcode := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;

            IF rec.CBD_MLGCNTRY_CODE IS NOT NULL
            THEN
               BEGIN
                  SELECT gcm_cntry_code
                    INTO v_cntry_code
                    FROM gen_cntry_mast
                   WHERE gcm_inst_code = rec.CBD_INST_CODE
                         AND gcm_cntry_code = rec.CBD_MLGCNTRY_CODE;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                        'Country Code not available in the Master - Mailing Address '
                        || rec.CBD_MLGCNTRY_CODE;
                     v_respcode := '21';
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        'while fecthing Mailing country code for cntry - Mailing Address '
                        || rec.CBD_MLGCNTRY_CODE
                        || SUBSTR (SQLERRM, 1, 200);

                     v_respcode := '21';
                     RAISE exp_reject_record;
               END;

               BEGIN
                  SELECT gsm_state_code
                    INTO v_state_code
                    FROM gen_state_mast
                   WHERE     gsm_state_code = rec.CBD_MLGSTATE_CODE
                         AND GSM_INST_CODE = rec.CBD_INST_CODE
                         AND gsm_cntry_code = rec.CBD_MLGCNTRY_CODE;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                        'State code not available in master - Mailing Address '
                        || rec.CBD_MLGSTATE_CODE;
                     v_respcode := '21';
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        'Error while selecting state code - Mailing Address'
                        || rec.CBD_MLGSTATE_CODE
                        || SUBSTR (SQLERRM, 1, 200);

                     v_respcode := '21';
                     RAISE exp_reject_record;
               END;
            END IF;
         END IF;

         -- mailing address state code check endz
         -- Country Code check starts
         IF rec.CBD_PHYCNTRY_CODE IS NOT NULL
         THEN                                              --MODIFIED BY NAILA
            BEGIN
               SELECT gcm_cntry_code  -- distinct has removerd  on 05/Aug/2013
                 INTO v_cntry_code
                 FROM gen_cntry_mast
                WHERE gcm_inst_code = rec.CBD_INST_CODE
                      AND gcm_cntry_code = rec.CBD_PHYCNTRY_CODE;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                     'Country Code not available in the Master - Physical Address '
                     || rec.CBD_PHYCNTRY_CODE;
                  v_respcode := '21';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'while fecthing Physical country code for cntry'
                     || rec.CBD_PHYCNTRY_CODE
                     || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.
                  v_respcode := '21';
                  RAISE exp_reject_record;
            END;
         END IF;

         IF rec.CBD_MLGCNTRY_CODE IS NOT NULL
         THEN
            BEGIN
               SELECT gcm_cntry_code  -- distinct has removerd  on 05/Aug/2013
                 INTO v_cntry_code
                 FROM gen_cntry_mast
                WHERE gcm_inst_code = rec.CBD_INST_CODE
                      AND gcm_cntry_code = rec.CBD_MLGCNTRY_CODE;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                     'Country Code not available in the Master - Mailing Address '
                     || rec.CBD_MLGCNTRY_CODE;
                  v_respcode := '21';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                     'while fecthing Mailing country code for cntry - Mailing Address '
                     || rec.CBD_MLGCNTRY_CODE
                     || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.

                  v_respcode := '21';
                  RAISE exp_reject_record;
            END;
         END IF;

         -- Country Code check endz

         -- Currency Code check starts
         IF rec.CBD_PHYCNTRY_CODE IS NOT NULL
         THEN
            BEGIN
               SELECT gcm_curr_code   -- distinct has removerd  on 05/Aug/2013
                 INTO v_curr_code
                 FROM gen_cntry_mast
                WHERE gcm_cntry_code = rec.CBD_PHYCNTRY_CODE
                      AND gcm_inst_code = rec.CBD_INST_CODE;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Currency code not available in master ';
                  v_respcode := '21';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                     'Error while selecting Currency Code - Physical Address'
                     || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.

                  v_respcode := '21';
                  RAISE exp_reject_record;
            END;
         END IF;

         IF rec.CBD_MLGCNTRY_CODE IS NOT NULL
         THEN
            BEGIN
               SELECT gcm_curr_code   -- distinct has removerd  on 05/Aug/2013
                 INTO v_curr_code
                 FROM gen_cntry_mast
                WHERE gcm_cntry_code = rec.CBD_MLGCNTRY_CODE
                      AND gcm_inst_code = rec.CBD_INST_CODE;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Currency code not available in master -';
                  v_respcode := '21';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                     'Error while selecting Currency Code - Physical Address'
                     || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.

                  v_respcode := '21';
                  RAISE exp_reject_record;
            END;
         END IF;

         -- Currency Code check ends
         -- Customer information update
         BEGIN
            BEGIN
               UPDATE cms_addr_mast
                  SET cam_add_one = NVL (rec.CBD_PHYADDR_LINE1, cam_add_one),
                      cam_add_two = NVL (rec.CBD_PHYADDR_LINE2, cam_add_two),
                      cam_city_name =
                         NVL (rec.CBD_PHYCITY_NAME, cam_city_name),
                      cam_pin_code =
                         NVL (rec.CBD_PHYPOSTAL_CODE, cam_pin_code),
                      cam_state_code =
                         NVL (rec.CBD_PHYSTATE_CODE, cam_state_code),
                      cam_cntry_code =
                         NVL (rec.CBD_PHYCNTRY_CODE, cam_cntry_code),
                      cam_phone_one =
                         NVL (rec.CBD_PHONE_NUMBER, cam_phone_one), --Added by sivakumar.M
                      cam_email = NVL (rec.CBD_EMAIL_ID, cam_email),
                      cam_mobl_one = NVL (rec.CBD_OTHER_PHNO, cam_mobl_one),
                      cam_state_switch =
                         NVL (v_phys_switch_state_code, cam_state_switch) --Added for FSS-1961(Melissa)
                WHERE     cam_cust_code = v_cust_code
                      AND cam_inst_code = rec.CBD_INST_CODE
                      AND cam_addr_flag = 'P';

               IF SQL%ROWCOUNT = 0
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                     'Update in Address master failed 1-- ' || v_cust_code;
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                        'ERROR IN ADDR MAST UPDATE FOR:- '
                     || v_cust_code
                     || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.
                  RAISE exp_reject_record;
            END;

            BEGIN
               UPDATE cms_cust_mast
                  SET ccm_birth_date =
                         NVL (rec.CDB_BIRTH_DATE, ccm_birth_date),
                      ccm_first_name =
                         NVL (rec.CBD_FIRST_NAME, ccm_first_name),
                      ccm_last_name = NVL (rec.CBD_LAST_NAME, ccm_last_name),
                      CCM_MID_NAME = NVL (rec.CBD_MIDDLE_NAME, CCM_MID_NAME)
                WHERE ccm_cust_code = v_cust_code
                      AND ccm_inst_code = rec.CBD_INST_CODE;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                     'Update in Customer master failed FOR -- '
                     || v_cust_code;
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                        'ERROR IN CUST MAST UPDATE FOR:- '
                     || v_cust_code
                     || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.
                  RAISE exp_reject_record;
            END;

            BEGIN
               SELECT COUNT (*)
                 INTO v_mailaddr_cnt
                 FROM cms_addr_mast
                WHERE     cam_inst_code = rec.CBD_INST_CODE
                      AND cam_cust_code = v_cust_code
                      AND cam_addr_flag = 'O';
            END;

            --   IF p_mailing_addr1 IS NOT NULL
            --  THEN
            IF v_mailaddr_cnt > 0
            THEN
               BEGIN
                  UPDATE cms_addr_mast
                     SET cam_add_one =
                            NVL (rec.CBD_MLGADDR_LINE1, cam_add_one),
                         cam_add_two =
                            NVL (rec.CBD_MLGADDR_LINE2, cam_add_two), --decode(p_mailing_addr2,null,cam_add_two,p_mailing_addr2),
                         cam_city_name =
                            NVL (rec.CBD_MLGCITY_NAME, cam_city_name), --decode(p_mailing_city,null,cam_city_name,p_mailing_city),
                         cam_pin_code =
                            NVL (rec.CBD_MLGPOSTAL_CODE, cam_pin_code), --decode(p_mailing_zip,null,cam_pin_code,p_mailing_zip),
                         cam_state_code =
                            NVL (rec.CBD_MLGSTATE_CODE, cam_state_code), --decode(p_mailing_state,null,cam_state_code,p_mailing_state) ,
                         cam_cntry_code =
                            NVL (rec.CBD_MLGCNTRY_CODE, cam_cntry_code), --decode(p_mailing_country,null,cam_cntry_code,p_mailing_country)
                         cam_phone_one =
                            NVL (rec.CBD_PHONE_NUMBER, cam_phone_one),
                         cam_mobl_one = NVL (rec.CBD_OTHER_PHNO, cam_mobl_one),
                         cam_state_switch =
                            NVL (v_mailing_switch_state_code,
                                 cam_state_switch) --Added for FSS-1961(Melissa)
                   WHERE     cam_inst_code = rec.CBD_INST_CODE
                         AND cam_cust_code = v_cust_code
                         AND cam_addr_flag = 'O';

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_respcode := '21';
                     v_errmsg :=
                        'Update in Address master failed FOR -- '
                        || v_cust_code;
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        'Error while updating mailing addr for custcode -- '
                        || v_cust_code
                        || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.

                     v_respcode := '21';
                     RAISE exp_reject_record;
               END;
            ELSE
               IF     rec.CBD_MLGADDR_LINE1 IS NOT NULL
                  AND rec.CBD_MLGCNTRY_CODE IS NOT NULL
                  AND rec.CBD_MLGCITY_NAME IS NOT NULL
               THEN              --Added for defect id : 0011432 on 28/06/2013
                  BEGIN
                     INSERT INTO cms_addr_mast (cam_inst_code,
                                                cam_cust_code,
                                                cam_addr_code,
                                                cam_add_one,
                                                cam_add_two,
                                                cam_city_name,
                                                cam_pin_code,
                                                cam_phone_one,
                                                cam_mobl_one,
                                                cam_cntry_code,
                                                cam_addr_flag,
                                                cam_state_code,
                                                cam_comm_type,
                                                cam_ins_user,
                                                cam_ins_date,
                                                cam_lupd_user,
                                                cam_lupd_date)
                          VALUES (rec.CBD_INST_CODE,
                                  v_cust_code,
                                  seq_addr_code.NEXTVAL,
                                  rec.CBD_MLGADDR_LINE1,
                                  rec.CBD_MLGADDR_LINE2,
                                  rec.CBD_MLGCITY_NAME,
                                  rec.CBD_MLGPOSTAL_CODE,
                                  rec.CBD_PHONE_NUMBER,
                                  rec.CBD_OTHER_PHNO,
                                  rec.CBD_MLGCNTRY_CODE,
                                  'O',
                                  rec.CBD_MLGSTATE_CODE,
                                  'R',
                                  1,
                                  SYSDATE,
                                  1,
                                  SYSDATE);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                           'Error while inserting mailing addr for custcode -- '
                           || v_cust_code
                           || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.

                        v_respcode := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE                              --Added for FSS-1961(Melissa)
                  BEGIN
                     INSERT INTO cms_addr_mast (cam_inst_code,
                                                cam_cust_code,
                                                cam_addr_code,
                                                cam_add_one,
                                                cam_add_two,
                                                cam_city_name,
                                                cam_pin_code,
                                                cam_phone_one,
                                                cam_mobl_one,
                                                cam_cntry_code,
                                                cam_addr_flag,
                                                cam_state_code,
                                                cam_comm_type,
                                                cam_ins_user,
                                                cam_ins_date,
                                                cam_lupd_user,
                                                cam_lupd_date)
                          VALUES (rec.CBD_INST_CODE,
                                  v_cust_code,
                                  seq_addr_code.NEXTVAL,
                                  rec.CBD_PHYADDR_LINE1,
                                  rec.CBD_PHYADDR_LINE2,
                                  rec.CBD_PHYCITY_NAME,
                                  rec.CBD_PHYPOSTAL_CODE,
                                  rec.CBD_PHONE_NUMBER,
                                  rec.CBD_OTHER_PHNO,
                                  rec.CBD_PHYCNTRY_CODE,
                                  'O',
                                  rec.CBD_PHYSTATE_CODE,
                                  'O',
                                  1,
                                  SYSDATE,
                                  1,
                                  SYSDATE);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                           'Error while inserting mailing addr for custcode -- '
                           || v_cust_code
                           || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.

                        v_respcode := '21';
                        RAISE exp_reject_record;
                  END;
               --END Added for FSS-1961(Melissa)
               END IF;
            END IF;              --Added for defect id : 0011432 on 28/06/2013
         END;

         --Added for FSS-1961(Melissa)
         BEGIN
            SELECT ccm_cust_id,
                   ccm_first_name || ' ' || ccm_last_name,
                   cam_add_one,
                   cam_add_two,
                   cam_city_name,
                   cam_state_switch,
                   cam_pin_code
              INTO V_CUST_ID,
                   V_FULL_NAME,
                   V_MAILADDR_LINEONE,
                   V_MAILADDR_LINETWO,
                   V_MAILADDR_CITY,
                   v_mailing_switch_state_code,
                   V_MAILADDR_ZIP
              FROM CMS_CUST_MAST, cms_addr_mast
             WHERE     cam_inst_code = ccm_inst_code
                   AND cam_cust_code = ccm_cust_code
                   AND CCM_INST_CODE = rec.CBD_INST_CODE
                   AND CCM_CUST_CODE = V_CUST_CODE
                   AND cam_addr_flag = 'O';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_respcode := '21';
               V_ERRMSG := 'Mailing Addess Not Found';
               RAISE EXP_MAIN_REJECT_RECORD;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               V_ERRMSG :=
                  'Error while selecting mailing address '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_MAIN_REJECT_RECORD;
         END;

         BEGIN
            SELECT COUNT (1)
              INTO V_AVQ_STATUS
              FROM CMS_AVQ_STATUS
             WHERE     CAS_INST_CODE = rec.CBD_INST_CODE
                   AND CAS_CUST_ID = V_CUST_ID
                   AND CAS_AVQ_FLAG = 'P';

            IF V_AVQ_STATUS = 1
            THEN
               UPDATE CMS_AVQ_STATUS
                  SET CAS_ADDR_ONE = NVL (V_MAILADDR_LINEONE, CAS_ADDR_ONE),
                      CAS_ADDR_TWO = NVL (V_MAILADDR_LINETWO, CAS_ADDR_TWO),
                      CAS_CITY_NAME = NVL (V_MAILADDR_CITY, CAS_CITY_NAME),
                      CAS_STATE_NAME =
                         NVL (v_mailing_switch_state_code, CAS_STATE_NAME),
                      CAS_POSTAL_CODE = NVL (V_MAILADDR_ZIP, CAS_POSTAL_CODE),
                      CAS_LUPD_USER = 1,
                      CAS_LUPD_DATE = SYSDATE
                WHERE     CAS_INST_CODE = rec.CBD_INST_CODE
                      AND CAS_CUST_ID = V_CUST_ID
                      AND CAS_AVQ_FLAG = 'P';
            -- SQL%ROWCOUNT =0 not required

            ELSE
               BEGIN
                  SELECT COUNT (1)
                    INTO V_AVQ_STATUS
                    FROM CMS_AVQ_STATUS
                   WHERE     CAS_INST_CODE = rec.CBD_INST_CODE
                         AND CAS_CUST_ID = V_CUST_ID
                         AND CAS_AVQ_FLAG = 'F';

                  IF V_AVQ_STATUS <> 0
                  THEN
                     BEGIN
                        SELECT cap_pan_code, cap_pan_code_encr
                          INTO v_gprhash_pan, v_gprencr_pan
                          FROM cms_appl_pan, cms_cardissuance_status
                         WHERE     cap_appl_code = ccs_appl_code
                               AND cap_pan_code = ccs_pan_code
                               AND cap_inst_code = ccs_inst_code
                               AND cap_inst_code = rec.CBD_INST_CODE
                               AND ccs_card_status = '17'
                               AND cap_cust_code = V_CUST_CODE
                               AND cap_startercard_flag = 'N';
                     EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        NULL;       
                        WHEN OTHERS
                        THEN
                           v_respcode := '21';
                           V_ERRMSG :=
                              'Error while selecting (gpr card)details from appl_pan :'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE EXP_MAIN_REJECT_RECORD;
                     END;
                  IF(v_gprhash_pan IS NOT NULL) THEN
                     INSERT INTO CMS_AVQ_STATUS (CAS_INST_CODE,
                                                 CAS_AVQSTAT_ID,
                                                 CAS_CUST_ID,
                                                 CAS_PAN_CODE,
                                                 CAS_PAN_ENCR,
                                                 CAS_CUST_NAME,
                                                 CAS_ADDR_ONE,
                                                 CAS_ADDR_TWO,
                                                 CAS_CITY_NAME,
                                                 CAS_STATE_NAME,
                                                 CAS_POSTAL_CODE,
                                                 CAS_AVQ_FLAG,
                                                 CAS_INS_USER,
                                                 CAS_INS_DATE)
                          VALUES (rec.CBD_INST_CODE,
                                  AVQ_SEQ.NEXTVAL,
                                  V_CUST_ID,
                                  V_HASH_PAN,
                                  V_ENCR_PAN,
                                  V_FULL_NAME,
                                  V_MAILADDR_LINEONE,
                                  V_MAILADDR_LINETWO,
                                  V_MAILADDR_CITY,
                                  v_mailing_switch_state_code,
                                  V_MAILADDR_ZIP,
                                  'P',
                                  1,
                                  SYSDATE);
                     END IF;

                  END IF;
               EXCEPTION
                  WHEN EXP_MAIN_REJECT_RECORD
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     V_RESPCODE := '21';
                     V_ERRMSG :=
                        'Exception while Inserting in CMS_AVQ_STATUS Table '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE EXP_MAIN_REJECT_RECORD;
               END;
            END IF;
         EXCEPTION
            WHEN EXP_MAIN_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               V_ERRMSG :=
                  'Error while updating mailing address(AVQ) '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_MAIN_REJECT_RECORD;
         END;

         --END Added for FSS-1961(Melissa)
         -- appl pan update starts
         BEGIN
            UPDATE CMS_APPL_PAN
               SET CAP_DISP_NAME = NVL (rec.CBD_FIRST_NAME, CAP_DISP_NAME) --MODIFIED BY NAILA
             WHERE CAP_INST_CODE = rec.CBD_INST_CODE
                   AND CAP_CUST_CODE = v_cust_code;

            IF SQL%ROWCOUNT = 0
            THEN
               v_respcode := '21';
               v_errmsg :=
                  'Display name in applpan not get updated for proxy number:'
                  || rec.CBD_PROXY_NUMBER;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                     'ERROR IN CMS_APPL_PAN UPDATE:- '
                  || v_cust_code
                  || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.
               RAISE exp_reject_record;
         END;

         -- appl pan update ends

         BEGIN
            UPDATE cms_caf_info_entry
               SET cci_kyc_flag = 'Y'
             WHERE cci_appl_code = v_appl_code
                   AND cci_inst_code = rec.CBD_INST_CODE;

            ---Added checks for quey update on 26/06/2013
            IF SQL%ROWCOUNT = 0
            THEN
               v_respcode := '21';
               v_errmsg := 'UPDATE NOT HAPPENED IN cms_caf_info_entry';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record             --Added exception on 26/06/2013
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_respcode := '09';
               v_errmsg :=
                     'ERROR WHILE UPDATING CMS_CAF_INFO_ENTRY FOR'
                  || '--'
                  || v_cust_code
                  || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.

               RAISE EXP_MAIN_REJECT_RECORD;
         END;

         --- CAF INFO ENTRY UPDATE END
         IF v_respcode <> '00' AND v_errmsg <> 'OK'
         THEN
            BEGIN
               UPDATE CMS_BATCHUPLOAD_DETL
                  SET CBD_RESPONSE_CODE = v_respcode,
                      CBD_RESPONSE_DESC = v_errmsg
                WHERE CBD_PROXY_NUMBER = rec.CBD_PROXY_NUMBER
                      AND CBD_RRN = rec.CBD_RRN;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_respcode := '21';
                  v_errmsg := 'UPDATE NOT HAPPENED IN CMS_BATCHUPLOAD_DETL';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                        'ERROR IN CMS_BATCHUPLOAD_DETL UPDATE:- '
                     || v_cust_code
                     || SUBSTR (SQLERRM, 1, 200); -- added sqlerrm on 05/Aug/2013 for review comments.
                  RAISE exp_reject_record;
            END;
         END IF;

         /*    This block has moved to starting of the procedure.
               BEGIN

                   SELECT CTM_TRAN_DESC into v_tran_desc
                   FROM CMS_TRANSACTION_MAST
                   WHERE CTM_TRAN_CODE=rec.CBD_TRAN_CODE AND CTM_DELIVERY_CHANNEL='05';

                   EXCEPTION
                 WHEN NO_DATA_FOUND
                 THEN
                 v_errmsg := 'CTM_TRAN_DESC details not available in CMS_TRANSACTION_MAST';
                 v_respcode := '21';
                    RAISE exp_reject_record;
                 WHEN OTHERS
                  THEN
                   v_errmsg :=
                    'Error while fetching data from CMS_TRANSACTION_MAST ';

                  v_respcode := '21';
                  RAISE exp_reject_record;
               END*/

         BEGIN
            INSERT INTO transactionlog (MSGTYPE,
                                        RRN,
                                        delivery_channel,
                                        date_time,
                                        txn_code,
                                        txn_mode,
                                        txn_status,
                                        response_code,
                                        business_date,
                                        business_time,
                                        instcode,
                                        error_msg,
                                        trans_desc,
                                        CUSTOMER_ACCT_NO,
                                        ACCT_BALANCE,
                                        LEDGER_BALANCE,
                                        CUSTOMER_CARD_NO,
                                        CUSTOMER_CARD_NO_ENCR,
                                        RESPONSE_ID,
                                        productid, --added for logging productid on 29-07-2013
                                        CATEGORYID --added for logging productid on 29-07-2013
                                                  )
                 VALUES ('0200',
                         rec.CBD_RRN,
                         '05',
                         SYSDATE,
                         rec.CBD_TRAN_CODE,
                         '0', -- Modified for review comments Changes on 05/Aug/2013.
                         DECODE (v_respcode, '00', 'C', 'F'),
                         v_respcode,
                         V_TRAN_DATE, --Added for logging data and time on 29/06/2013
                         V_TRAN_TIME, --Added for logging data and time on 29/06/2013
                         rec.CBD_INST_CODE,
                         v_errmsg,
                         v_tran_desc,
                         V_ACCT_NUMBER,
                         V_ACCT_BAL,
                         V_LEDGER_BAL,
                         V_HASH_PAN,
                         V_ENCR_PAN,
                         v_respcode,
                         v_prod_code, --added for logging productid on 29-07-2013
                         v_prod_cattype --added for logging productid on 29-07-2013
                                       );

            IF SQL%ROWCOUNT = 0
            THEN
               v_respcode := '21';
               v_errmsg :=
                  'INSERT IN TRANSACTIONLOG failed FOR -- ' || v_cust_code;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_respcode := '99';
               v_errmsg :=
                  'Problem while inserting data into transaction log '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                                 ctd_txn_code,
                                                 ctd_txn_type,
                                                 ctd_business_date,
                                                 ctd_business_time,
                                                 ctd_customer_card_no,
                                                 ctd_txn_amount,
                                                 ctd_txn_curr,
                                                 ctd_actual_amount,
                                                 ctd_fee_amount,
                                                 ctd_waiver_amount,
                                                 ctd_servicetax_amount,
                                                 ctd_cess_amount,
                                                 ctd_bill_amount,
                                                 ctd_bill_curr,
                                                 ctd_process_flag,
                                                 ctd_process_msg,
                                                 ctd_rrn,
                                                 ctd_system_trace_audit_no,
                                                 ctd_customer_card_no_encr,
                                                 ctd_msg_type,
                                                 ctd_cust_acct_number,
                                                 ctd_inst_code)
                 VALUES ('05',
                         rec.CBD_TRAN_CODE,
                         v_txn_type,                    -- ADDED ON 29-07-2013
                         V_TRAN_DATE,
                         V_TRAN_TIME, --Added for logging data and time on 29/06/2013
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         'Y',
                         'Successful',
                         rec.CBD_RRN,
                         NULL,      -- added messgae Successful on 05/Aug/2013
                         NULL,
                         NULL,
                         NULL,
                         rec.CBD_INST_CODE);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_respcode := '99';
               v_errmsg :=
                  'Problem while inserting data into  cms_transaction_log_dtl-1'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK TO v_savepoint;

            IF v_respcode <> '00' AND v_errmsg <> 'OK'
            THEN
               BEGIN
                  UPDATE CMS_BATCHUPLOAD_DETL
                     SET CBD_RESPONSE_CODE = v_respcode,
                         CBD_RESPONSE_DESC = v_errmsg
                   WHERE CBD_PROXY_NUMBER = rec.CBD_PROXY_NUMBER
                         AND CBD_RRN = rec.CBD_RRN;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_respcode := '21';
                     v_errmsg := 'UPDATE NOT HAPPENED IN CMS_BATCHUPLOAD_DETL';

                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_respcode := '21';
                     v_errmsg :=
                           'ERROR IN CMS_BATCHUPLOAD_DETL UPDATE:- '
                        || v_cust_code
                        || '--'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            END IF;

            BEGIN
               INSERT INTO transactionlog (MSGTYPE,
                                           RRN,
                                           delivery_channel,
                                           date_time,
                                           txn_code,
                                           txn_mode,
                                           txn_status,
                                           response_code,
                                           business_date,
                                           business_time,
                                           instcode,
                                           error_msg,
                                           trans_desc,
                                           CUSTOMER_ACCT_NO,
                                           ACCT_BALANCE,
                                           LEDGER_BALANCE,
                                           CUSTOMER_CARD_NO,
                                           CUSTOMER_CARD_NO_ENCR,
                                           RESPONSE_ID,
                                           productid, --added for logging productid on 29-07-2013
                                           CATEGORYID --added for logging productid on 29-07-2013
                                                     )
                    VALUES ('0200',
                            rec.CBD_RRN,
                            '05',
                            SYSDATE,
                            rec.CBD_TRAN_CODE,
                            '0', -- Modified for review comments Changes on 05/Aug/2013.
                            DECODE (v_respcode, '00', 'C', 'F'),
                            v_respcode,
                            V_TRAN_DATE, --Added for logging data and time on 29/06/2013
                            V_TRAN_TIME, --Added for logging data and time on 29/06/2013
                            rec.CBD_INST_CODE,
                            v_errmsg,
                            v_tran_desc,
                            V_ACCT_NUMBER,
                            V_ACCT_BAL,
                            V_LEDGER_BAL,
                            V_HASH_PAN,
                            V_ENCR_PAN,
                            v_respcode,
                            v_prod_code, --added for logging productid on 29-07-2013
                            v_prod_cattype --added for logging productid on 29-07-2013
                                          );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_respcode := '99';
                  v_errmsg :=
                     'Problem while inserting data into transaction log '
                     || SUBSTR (SQLERRM, 1, 200);
            END;


            BEGIN
               INSERT
                 INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                               ctd_txn_code,
                                               ctd_txn_type,
                                               ctd_business_date,
                                               ctd_business_time,
                                               ctd_customer_card_no,
                                               ctd_txn_amount,
                                               ctd_txn_curr,
                                               ctd_actual_amount,
                                               ctd_fee_amount,
                                               ctd_waiver_amount,
                                               ctd_servicetax_amount,
                                               ctd_cess_amount,
                                               ctd_bill_amount,
                                               ctd_bill_curr,
                                               ctd_process_flag,
                                               ctd_process_msg,
                                               ctd_rrn,
                                               ctd_system_trace_audit_no,
                                               ctd_customer_card_no_encr,
                                               ctd_msg_type,
                                               ctd_cust_acct_number,
                                               ctd_inst_code)
               VALUES ('05',
                       rec.CBD_TRAN_CODE,
                       v_txn_type,                       --ADDED ON 29-07-2013
                       V_TRAN_DATE,
                       V_TRAN_TIME, --Added for logging data and time on 29/06/2013
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       'E',      -- Modified for defect id:11441 on 17/07/2013
                       v_errmsg,
                       rec.CBD_RRN,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       rec.CBD_INST_CODE);
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_respcode := '99';
                  v_errmsg :=
                     'Problem while inserting data into cms_transaction_log_dtl-2'
                     || SUBSTR (SQLERRM, 1, 200);
            END;
         WHEN OTHERS
         THEN
            ROLLBACK TO v_savepoint;
            -- v_errmsg := 'ERROR IN PROFILE UPDATE ' || SUBSTR (SQLERRM, 1, 200);
            v_errmsg := 'ERROR IN PROFILE UPDATE MAIN';

            v_respcode := '89';

            IF v_respcode <> '00' AND v_errmsg <> 'OK'
            THEN
               BEGIN
                  UPDATE CMS_BATCHUPLOAD_DETL
                     SET CBD_RESPONSE_CODE = v_respcode,
                         CBD_RESPONSE_DESC = v_errmsg
                   WHERE CBD_PROXY_NUMBER = rec.CBD_PROXY_NUMBER
                         AND CBD_RRN = rec.CBD_RRN;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_respcode := '21';
                     v_errmsg := 'UPDATE NOT HAPPENED IN CMS_BATCHUPLOAD_DETL';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_respcode := '21';
                     v_errmsg :=
                           'ERROR IN CMS_BATCHUPLOAD_DETL UPDATE:- '
                        || v_cust_code
                        || '--'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            END IF;

            BEGIN
               INSERT INTO transactionlog (MSGTYPE,
                                           RRN,
                                           delivery_channel,
                                           date_time,
                                           txn_code,
                                           txn_mode,
                                           txn_status,
                                           response_code,
                                           business_date,
                                           business_time,
                                           instcode,
                                           error_msg,
                                           trans_desc,
                                           CUSTOMER_ACCT_NO,
                                           ACCT_BALANCE,
                                           LEDGER_BALANCE,
                                           CUSTOMER_CARD_NO,
                                           CUSTOMER_CARD_NO_ENCR,
                                           RESPONSE_ID,
                                           productid, --added for logging productid on 29-07-2013
                                           CATEGORYID --added for logging productid on 29-07-2013
                                                     )
                    VALUES ('0200',
                            rec.CBD_RRN,
                            '05',
                            SYSDATE,
                            rec.CBD_TRAN_CODE,
                            '0', -- Modified for Review comments Changes on 05/Aug/2013
                            DECODE (v_respcode, '00', 'C', 'F'),
                            v_respcode,
                            V_TRAN_DATE, --Added for logging data and time on 29/06/2013
                            V_TRAN_TIME, --Added for logging data and time on 29/06/2013
                            rec.CBD_INST_CODE,
                            v_errmsg,
                            v_tran_desc,
                            V_ACCT_NUMBER,
                            V_ACCT_BAL,
                            V_LEDGER_BAL,
                            V_HASH_PAN,
                            V_ENCR_PAN,
                            v_respcode,
                            v_prod_code, --added for logging productid on 29-07-2013
                            v_prod_cattype --added for logging productid on 29-07-2013
                                          );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_respcode := '99';
                  v_errmsg :=
                     'Problem while inserting data into transaction log '
                     || SUBSTR (SQLERRM, 1, 200);
            END;


            BEGIN
               INSERT
                 INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                               ctd_txn_code,
                                               ctd_txn_type,
                                               ctd_business_date,
                                               ctd_business_time,
                                               ctd_customer_card_no,
                                               ctd_txn_amount,
                                               ctd_txn_curr,
                                               ctd_actual_amount,
                                               ctd_fee_amount,
                                               ctd_waiver_amount,
                                               ctd_servicetax_amount,
                                               ctd_cess_amount,
                                               ctd_bill_amount,
                                               ctd_bill_curr,
                                               ctd_process_flag,
                                               ctd_process_msg,
                                               ctd_rrn,
                                               ctd_system_trace_audit_no,
                                               ctd_customer_card_no_encr,
                                               ctd_msg_type,
                                               ctd_cust_acct_number,
                                               ctd_inst_code)
               VALUES ('05',
                       rec.CBD_TRAN_CODE,
                       v_txn_type,                       --ADDED ON 29-07-2013
                       V_TRAN_DATE,
                       V_TRAN_TIME, --Added for logging data and time on 29/06/2013
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       'E',      -- Modified for defect id:11441 on 17/07/2013
                       v_errmsg,
                       rec.CBD_RRN,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       rec.CBD_INST_CODE);
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_respcode := '99';
                  v_errmsg :=
                     'Problem while inserting data into cms_transaction_log_dtl-2'
                     || SUBSTR (SQLERRM, 1, 200);
            END;
      END;
      commit;
   END LOOP;
-- CLOSE batchPU;
END;
/

 SHOW ERROR