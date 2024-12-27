create or replace PROCEDURE        vmscms.sp_card_renew_pan_debit
(
prm_inst_code	IN  NUMBER,
prm_ins_date	IN  DATE,
prm_pancode	  IN  VARCHAR2,
prm_mbrnumb   IN  VARCHAR2,
--prm_disp_name	IN  VARCHAR2,
prm_remark	  IN  VARCHAR2,
prm_rsncode	  IN  NUMBER,
prm_workmode	IN  VARCHAR2,
prm_lupd_user	IN  NUMBER,
prm_errmsg	  OUT VARCHAR2
)
as

/*************************************************************************************************
    
    * Modified By      : MageshKumar S
    * Modified Date    : 18/07/2017
    * Purpose          : FSS-5157
    * Reviewer         : Saravanan/Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
 *************************************************************************************************/
   v_errmsg                  VARCHAR2(300);
   v_hsm_mode                CMS_INST_PARAM.cip_param_value%type;
   v_renew_param             CMS_INST_PARAM.cip_param_value%type;
   v_expiryparam             CMS_INST_PARAM.cip_param_value%type;
   v_cap_prod_catg           cms_appl_pan.cap_prod_catg%TYPE;
   v_cap_cafgen_flag         cms_appl_pan.cap_cafgen_flag%TYPE;
   v_from_date               DATE;
   v_to_date                 DATE;
   v_expry_date              DATE;
   v_record_exist            CHAR (1)      := 'Y';
   v_caffilegen_flag         CHAR (1)      := 'N';
   v_issuestatus             VARCHAR2 (2);
   v_pinmailer               VARCHAR2 (1);
   v_cardcarrier             VARCHAR2 (1);
   v_pinoffset               VARCHAR2 (16);
   v_rec_type				         VARCHAR2 (1);
   v_emboss_flag             CMS_APPL_PAN.cap_embos_flag%type;
   v_renew_reccnt            NUMBER DEFAULT 0;
   v_rencaf_fname            VARCHAR2(90);
   v_check_failed_rec        NUMBER;
   v_pan_code                CMS_PAN_ACCT.cpa_pan_code%type;
   v_cap_prod_code           CMS_APPL_PAN.cap_prod_code%type;
   v_cap_card_type           CMS_APPL_PAN.cap_card_type%type;
   v_cardtype_profile_code   CMS_PROD_CATTYPE.cpc_profile_code%TYPE;
   v_profile_code            CMS_PROD_MAST.cpm_profile_code%TYPE;
   v_expryparam              CMS_BIN_PARAM.cbp_param_value%TYPE;
   v_validity_period		     CMS_BIN_PARAM.cbp_param_value%type;
   v_cap_card_stat           cms_appl_pan.cap_card_stat%type;
   v_cap_acct_no             cms_appl_pan.cap_acct_no%type;
   v_insta_check             CMS_INST_PARAM.cip_param_value%type;
   v_filter_count            NUMBER;

      v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
 v_exp_date_exemption cms_prod_cattype.cpc_exp_date_exemption%type;
begin                                                             --<< main begin start >>--

prm_errmsg := 'OK';


--SN CREATE HASH PAN
BEGIN
	v_hash_pan := Gethash(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RETURN;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
	v_encr_pan := Fn_Emaps_Main(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RETURN;
END;
--EN create encr pan

 BEGIN
      SELECT cap_prod_catg, cap_cafgen_flag, cap_prod_code,cap_card_type,cap_card_stat, cap_acct_no
        INTO v_cap_prod_catg, v_cap_cafgen_flag, v_cap_prod_code, v_cap_card_type,v_cap_card_stat,v_cap_acct_no
        FROM CMS_APPL_PAN
       WHERE cap_inst_code = prm_inst_code
       AND cap_pan_code    = v_hash_pan--prm_pancode
       AND cap_mbr_numb    = prm_mbrnumb;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg := 'Pan Number  not avialable';
         return;
      WHEN OTHERS
      THEN
         prm_errmsg := 'Error while selecting the product category,acc no,cust code ' || substr(SQLERRM,1,200);
         return;
   END;




----------Sn start insta card check----------  /*added by amit on 24 Sep'10 for not to allow any supprt func on insta card.*/
   BEGIN
   select cip_param_value
   into v_insta_check
   from cms_inst_param
   where cip_param_key='INSTA_CARD_CHECK'
   and cip_inst_code=prm_inst_code;

   IF v_insta_check ='Y' THEN
    sp_gen_insta_check(
                        v_cap_acct_no,
                        v_cap_card_stat,
                        prm_errmsg
                      );
      IF prm_errmsg <>'OK' THEN
        RETURN;
      END IF;
   END IF;

   EXCEPTION WHEN OTHERS THEN
   prm_errmsg:='Error while checking the instant card validation. '||substr(sqlerrm,1,200);
   return;
   END;
  ----------En start insta card check----------

-----------------------------Start to get HSM details-------------------------
    BEGIN
        SELECT CIP_PARAM_VALUE
        INTO v_hsm_mode
        FROM CMS_INST_PARAM
        WHERE cip_param_key ='HSM_MODE'
        AND cip_inst_code   = prm_inst_code;
        IF v_hsm_mode       ='Y' THEN
          v_emboss_flag    :='Y'; -- i.e. generate embossa file.
        ELSE
          v_emboss_flag:='N'; -- i.e. don't generate embossa file.
        END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_hsm_mode   :='N';
        v_emboss_flag:='N'; -- i.e. don't generate embossa file.
      END;
-----------------------------End to get HSM details-------------------------

----------------------------Start get expiry parameter-------------------------
    /*BEGIN
      SELECT cip_param_value
      INTO v_expiryparam
      FROM CMS_INST_PARAM
      WHERE cip_param_key = 'CARD EXPRY'
      AND cip_inst_code   = prm_inst_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      prm_errmsg := 'Expiry parameter not defined in master';
      RETURN;
    WHEN OTHERS THEN
      prm_errmsg := 'Error while selecting expry parameter from master' || SUBSTR(sqlerrm,1,150);
      RETURN;
    END;*/
----------------------------End get expiry parameter----------------------------
-----------------------Start to get profile code attached to card type--------------------
    BEGIN
          SELECT cpm_profile_code, cpc_profile_code,cpc_exp_date_exemption
            INTO v_profile_code,v_cardtype_profile_code,v_exp_date_exemption
            FROM CMS_PROD_CATTYPE, CMS_PROD_MAST
           WHERE cpc_inst_code = prm_inst_code
             AND cpc_prod_code = v_cap_prod_code
             AND cpc_card_type = v_cap_card_type
             AND cpm_prod_code = cpc_prod_code;
       EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
             prm_errmsg :='Profile code not defined for product code '|| v_cap_prod_code|| 'card type '|| v_cap_card_type;
             RETURN;
          WHEN OTHERS
          THEN
             prm_errmsg :='Error while selecting profile attached to card type'|| SUBSTR (SQLERRM, 1, 300);
             RETURN;
    END;
-----------------------End to get profile code for card type--------------------

---------------------Start to get validty for profile----------------------------

      
    
            
---------------------End to get validity for profile----------------------------


-------------------------------Start set date---------------------------------
    v_from_date  := last_day(add_months(prm_ins_date , -1)) + 1;
    v_to_date    := last_day(prm_ins_date);
    --v_expry_date := LAST_DAY(ADD_MONTHS(prm_ins_date, v_expiryparam));

        BEGIN
            vmsfunutilities.get_expiry_date(prm_inst_code,v_cap_prod_code,
            v_cap_card_type,v_cardtype_profile_code,v_expry_date,prm_errmsg);
            if prm_errmsg<>'OK' then
               return;
            end if;
        exception
            WHEN others THEN
                prm_errmsg:='Error while calling vmsfunutilities.get_expiry_date'||substr(sqlerrm,1,200);
                RETURN;
        END;


    BEGIN
        SELECT cip_param_value
        INTO v_renew_param
        FROM CMS_INST_PARAM
        WHERE cip_param_key = 'RENEWCAF'
        AND cip_inst_code   = prm_inst_code;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        prm_errmsg := 'No of parameter for renewal CAF not defined in master';
        RETURN;
      WHEN OTHERS THEN
        prm_errmsg := 'Error while selecting renewal CAF parameter from master' || SUBSTR(sqlerrm,1,150);
        RETURN;
      END;
-------------------------End get no of renewcaf details----------------------------
IF v_cap_prod_catg= 'P' THEN  --Sn if prepaid
    null;
ELSE
-----------------------Start generate a renewcaf file name--------------------------------
    IF v_renew_reccnt = 0 THEN
      Sp_Create_Rencaffname(
                            prm_inst_code,
                            prm_lupd_user,
                            v_rencaf_fname,
                            v_errmsg
                            );
      IF v_errmsg  != 'OK' THEN
        prm_errmsg := 'Error while creating filename -- '||v_errmsg;
        RETURN;
      END IF;
    END IF;
-------------------------End generate a renewcaf file name-------------------------------
END IF; --En if prepaid
-----------------Sn to renew the pan-----------------------

        BEGIN
               SELECT COUNT (1)
                 INTO v_filter_count
                 FROM CMS_REN_PAN_TEMP
                WHERE crp_pan_code = v_hash_pan; --prm_pancode;

               IF v_filter_count > 0
               THEN
                  prm_errmsg:='The card is filtered for the renewal process.';
                  RETURN;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
         END;
-----------------Sn to renew the pan-----------------------

-----------------------------Sn check failed records for duplicate processig------------------
    BEGIN
      SELECT COUNT(*)
      INTO v_check_failed_rec
      FROM CMS_CARDRENEWAL_ERRLOG
      WHERE cce_pan_code    = v_hash_pan--prm_pancode
      AND cce_inst_code     = prm_inst_code;
    IF v_check_failed_rec > 0 THEN
      prm_errmsg:= 'Record alredy failed in renew process ';
      RETURN;
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
      prm_errmsg := 'Error while checking record in history table' || SUBSTR(sqlerrm,1,200);
      RETURN;
    END;
------------------------End check failed record for duplicate processing-----------------------

----------------------------------Start check account information-----------------------------
    BEGIN
      SELECT DISTINCT CPA_PAN_CODE
      INTO v_pan_code
      FROM CMS_PAN_ACCT
      WHERE cpa_inst_code = prm_inst_code
      AND cpa_pan_code    = v_hash_pan;
      --prm_pancode;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      prm_errmsg := 'Account not found in master ';
      RETURN;
    WHEN OTHERS THEN
      prm_errmsg := 'Error while selecting acct details '|| SUBSTR(sqlerrm,1,200);
      RETURN;
    END;
------------------------------End check account information-------------------------------------

----------------------------------Sn update expry date-------------------------------------
    BEGIN
      IF (v_hsm_mode = 'N') THEN
        UPDATE CMS_APPL_PAN
        SET cap_expry_date   = v_expry_date,
          cap_next_bill_date = v_to_date,
          cap_lupd_date      = SYSDATE
        WHERE cap_inst_code  = prm_inst_code
        AND cap_pan_code     = v_hash_pan --prm_pancode
        AND cap_mbr_numb     = prm_mbrnumb ;
      ELSE
        UPDATE CMS_APPL_PAN
        SET cap_expry_date   = v_expry_date,
          cap_next_bill_date = v_to_date,
          cap_lupd_date      = SYSDATE,
          cap_embos_flag     = 'Y'
        WHERE cap_inst_code  = prm_inst_code
        AND cap_pan_code     = v_hash_pan --prm_pancode
        AND cap_mbr_numb     = prm_mbrnumb;
      END IF;

      IF SQL%rowcount = 0 THEN
        prm_errmsg:= 'Error while updating expry date ';
        RETURN;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      prm_errmsg :='Error while updating card dates for renewing' || SUBSTR (SQLERRM,1, 200);
      RETURN;
    END;
-----------------------------------En update expry date-------------------------------------
-------------------------------Start Insert Details in Pan support-------------------------
    BEGIN
      INSERT INTO CMS_PAN_SPPRT
                (cps_inst_code, cps_pan_code, cps_mbr_numb,
                 cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                 cps_func_remark, cps_ins_user, cps_lupd_user,
                 cps_cmd_mode,cps_pan_code_encr
                )
         VALUES (prm_inst_code, --prm_pancode
         v_hash_pan, prm_mbrnumb,
                 v_cap_prod_catg, 'RENEW', prm_rsncode,
                 prm_remark, prm_lupd_user, prm_lupd_user,
                 prm_workmode,v_encr_pan
                );
    EXCEPTION
    WHEN OTHERS THEN
      prm_errmsg := 'Error while inserting in pan support' || substr(SQLERRM,1,200);
      RETURN;
    END;
-------------------------------End Insert Details in Pan support----------------------
IF v_cap_prod_catg= 'P' THEN  --Sn if prepaid
    null;
ELSE
------------------------------------Start Refresh caf----------------------------------
    BEGIN
      BEGIN
          SELECT   cci_file_gen, cci_seg12_issue_stat,
                   cci_seg12_pin_mailer, cci_seg12_card_carrier,
                   cci_pin_ofst, cci_rec_typ
              INTO v_caffilegen_flag, v_issuestatus,
                   v_pinmailer, v_cardcarrier,
                   v_pinoffset,v_rec_type
              FROM CMS_CAF_INFO
             WHERE cci_inst_code = prm_inst_code
               AND cci_pan_code = v_hash_pan--DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
                                 --19,prm_pancode)---RPAD (prm_pancode, 19, ' ')
               AND cci_mbr_numb = prm_mbrnumb
               AND cci_file_gen ='N'
              GROUP BY cci_file_gen,
                       cci_seg12_issue_stat,
                       cci_seg12_pin_mailer,
                       cci_seg12_card_carrier,
                       cci_pin_ofst,
                       cci_rec_typ;

          EXCEPTION
         WHEN NO_DATA_FOUND THEN
            v_record_exist := 'N';
         WHEN OTHERS THEN
            prm_errmsg := 'Error while getting data from CAF' || substr(SQLERRM,1,200);
            RETURN;
      END;

      DELETE FROM CMS_CAF_INFO
                WHERE cci_inst_code = prm_inst_code
                  AND cci_pan_code = v_hash_pan --DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
                                 --19,prm_pancode)--RPAD (prm_pancode, 19, ' ')
                  AND cci_mbr_numb = prm_mbrnumb;

       -----------call to sp_caf_rfrsh----------------------
      Sp_Caf_Rfrsh(
                    prm_inst_code,
                   prm_pancode,-- v_hash_pan
                    prm_mbrnumb,
                    SYSDATE,
                    'C',
                    NULL,
                    'RENEW',
                    prm_lupd_user,
                    v_encr_pan,
                    prm_errmsg
                  );
      IF prm_errmsg <> 'OK' THEN
			   RETURN;
			END IF;
      -----------End call to sp_caf_rfrsh----------------------
      IF v_rec_type = 'A'
      THEN
        v_issuestatus := '00';                -- no pinmailer no embossa.
        v_pinoffset := RPAD ('Z', 16, 'Z');        -- keep original pin .
      END IF;
      IF /*prm_workmode = 0 AND*/ v_record_exist = 'Y'
      THEN
        UPDATE CMS_CAF_INFO
          SET --cci_file_gen = 'E',
              cci_file_name=v_rencaf_fname,
              cci_seg12_issue_stat = v_issuestatus,
              cci_seg12_pin_mailer = v_pinmailer,
              cci_seg12_card_carrier = v_cardcarrier,
              cci_pin_ofst = v_pinoffset,
              cci_file_gen = 'R' ---added on 02 Nov'10 for renewcards no pingeneration
        WHERE cci_inst_code = prm_inst_code
          AND cci_pan_code = v_hash_pan--DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
                             --19,prm_pancode)--RPAD (prm_pancode, 19, ' ')
          AND cci_mbr_numb = prm_mbrnumb;
        IF SQL%ROWCOUNT = 0 THEN
           prm_errmsg := 'Error while updating card data in CAF for offline mode';
           RETURN;
        END IF;
      ELSE
        UPDATE cms_caf_info
        SET cci_file_name = v_rencaf_fname, --added by amit 24 sep'10
            cci_file_gen  = 'R'            --added on 02 Nov'10 for renewcards no pin genereation
        WHERE cci_inst_code = prm_inst_code
        AND cci_pan_code =v_hash_pan --DECODE(LENGTH (prm_pancode),16, prm_pancode || '   ',19, prm_pancode)        --RPAD (k.cap_pan_code, 19, ' ')
        AND cci_mbr_numb = prm_mbrnumb;

        IF SQL%ROWCOUNT = 0 THEN
          prm_errmsg :='Error while updating renewcaf file name';
          RETURN;
        END IF;
      END IF;

      /*IF prm_workmode = 0 AND v_record_exist = 'N'
      THEN
         UPDATE CMS_CAF_INFO
            SET cci_file_gen = 'Y'
            WHERE cci_inst_code = prm_inst_code
            AND cci_pan_code = DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
                                      19,prm_pancode)--RPAD (prm_pancode, 19, ' ')
            AND cci_mbr_numb = prm_mbrnumb;
        IF SQL%ROWCOUNT = 0 THEN
           prm_errmsg := 'Error while updating card data in CAF for offline mode';
           RETURN;
        END IF;
      END IF;*/
    EXCEPTION
      WHEN OTHERS
      THEN
        prm_errmsg := 'Error while refreshing caf - ' || substr(SQLERRM,1,200);
        RETURN;
    END;
-------------------------------------End Refresh caf---------------------------------------
END IF; --En if prepaid
EXCEPTION                                                              --<< main exception >>--
WHEN OTHERS
   THEN
      prm_errmsg := 'Main Error while renewing pan --' ||substr(SQLERRM,1,200);
      RETURN;
end;                                                                  --<< main begin end >>--
/
show error