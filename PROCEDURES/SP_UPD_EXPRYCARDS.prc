CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Upd_Exprycards (errmsg OUT VARCHAR2)
IS
   CURSOR c1
   IS
      SELECT cap_pan_code, cap_mbr_numb, cap_inst_code, cap_lupd_user,
      cap_prod_catg
      FROM CMS_APPL_PAN, CMS_BIN_MAST, CMS_PROD_MAST
--**       WHERE TO_CHAR (cap_expry_date, 'mm-yy') < TO_CHAR (SYSDATE, 'mm-yy');
   WHERE cap_expry_date < LAST_DAY(ADD_MONTHS(SYSDATE,-1)) + 1 
   AND cap_card_stat = '1'  
   AND cap_prod_catg = 'D' 
   AND cbm_inst_bin = SUBSTR(cap_pan_Code,1,6)
   AND cbm_inst_code = 1
   AND cpm_inst_code = cap_inst_code
   AND cpm_prod_code = cap_prod_code
   AND cpm_switch_prod IN ('VD','MD')
   AND ROWNUM < 19000; --** Rama PrabhuR 270906 - ICICI CR176 - 001
   v_proc_flag   CHAR (1);       --** Rama PrabhuR 270906 - ICICI CR176 - 002
     v_expcount NUMBER; -- shyam for onetime updation 181206
     v_savepoint NUMBER := 1; -- shyam added furing Cr 170 bug fix 261006    
     exp_reject_record    EXCEPTION;
     exp_succ_record    EXCEPTION;
     exp_nocaf_record   EXCEPTION;
     acctcnt NUMBER; -- for not generating CAF for cards without acct
BEGIN                                                            ---Main Begin
   errmsg := 'OK';
--** Rama PrabhuR 270906 - ICICI CR 176 - 003
BEGIN
   SELECT cip_param_value
   INTO v_proc_flag
   FROM CMS_INST_PARAM
   WHERE cip_inst_code = 1 
   AND cip_param_key = 'EXPCLOSEPROC';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    errmsg := 'Parameter not defined in Master';
    RETURN;
END;
   IF v_proc_flag = 'Y'
   THEN
      errmsg := 'Process Already executed';
   END IF;
--** Rama PrabhuR 270906 - ICICI CR 176 - 003 End
   FOR i IN c1
    LOOP
        BEGIN            --<< lOOP BEGIN>>
           SAVEPOINT v_savepoint; -- shyam 261006 -- CR 170
        errmsg :='OK'; 
        acctcnt:=0;
      BEGIN                                                       ----begin 1
        UPDATE CMS_APPL_PAN
        SET cap_card_stat = '9'
        WHERE cap_inst_code = i.cap_inst_code
        AND cap_pan_code = i.cap_pan_code
        AND cap_mbr_numb = i.cap_mbr_numb;
         IF SQL%ROWCOUNT != 1
        THEN
        errmsg :=
            'Problem in updation of status for pan '
            || i.cap_pan_code
            || '.';
        RAISE exp_reject_record;
    END IF;
      EXCEPTION                                             ---excp of begin 1
         WHEN OTHERS
         THEN
            errmsg := 'Excp 1 -- ' || SUBSTR(SQLERRM,1,250);
        RAISE exp_reject_record;
      END;                                                     ----End begin 1
    --  IF errmsg = 'OK' THEN
      BEGIN                                                        ----begin 2
         INSERT INTO CMS_PAN_SPPRT
                     (cps_inst_code, cps_pan_code, cps_mbr_numb,
                      cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                      cps_func_remark, cps_ins_user, cps_ins_date,
                      cps_lupd_user, cps_lupd_date, cps_cmd_mode
                     )
              VALUES (i.cap_inst_code, i.cap_pan_code, i.cap_mbr_numb,
                      i.cap_prod_catg, 'EXPRY', 1,
                      'CARD EXPIRED', i.cap_lupd_user, SYSDATE,
                      i.cap_lupd_user, SYSDATE, 0
                     );
      EXCEPTION                                              --excp of begin 2
         WHEN OTHERS
         THEN
             -- ROLLBACK TO v_savepoint;  -- shyam 261006 -- CR 170      
            errmsg := 'Excp 2 -- ' || SQLERRM;
        RAISE exp_succ_record;
      END;                                                      --begin 2 ends

      BEGIN -- not to generate CAF for cards which dont have account
    SELECT COUNT(cpa_acct_id)
    INTO    acctcnt
    FROM    CMS_PAN_ACCT 
    WHERE    cpa_inst_code = i.cap_inst_code
    AND cpa_pan_code = i.cap_pan_code
    AND cpa_mbr_numb = i.cap_mbr_numb;
      EXCEPTION    
      WHEN NO_DATA_FOUND THEN 
    errmsg:='No Accounts linked to PAN. Card Closed without CAF.';
    acctcnt:=0;
    RAISE exp_nocaf_record;
      END; -- not to generate CAF for cards which dont have account
     -- END IF;
     if acctcnt = 0 then
         errmsg:='No Accounts linked to PAN. Card Closed without CAF.';
        RAISE exp_nocaf_record;
     end if;
     
      IF errmsg = 'OK' AND acctcnt > 0 THEN -- not to generate CAF for cards which dont have account
        BEGIN                                                       -----begin 3
            DELETE FROM CMS_CAF_INFO
            WHERE cci_inst_code = i.cap_inst_code
            AND cci_pan_code = RPAD (i.cap_pan_code, 19, ' ')
            AND cci_mbr_numb = i.cap_mbr_numb;
        EXCEPTION
        WHEN OTHERS THEN
        errmsg := 'Error in deleting from Caf. Card closed without CAF';
        RAISE exp_succ_record;
        END;                            --End 3
    BEGIN                                --Begin -4
         Sp_Caf_Rfrsh (i.cap_inst_code,
                       i.cap_pan_code,
                       i.cap_mbr_numb,
                       SYSDATE,
                       'C',
                       NULL,
                       'EXPRY',
                       i.cap_lupd_user,
                       errmsg
                      );
    IF errmsg != 'OK'
        THEN
          --  ROLLBACK TO v_savepoint;  -- shyam 261006 -- CR 170      
        errmsg := 'From caf refresh -- Card closed without CAF' || errmsg;
        RAISE exp_succ_record;
    END IF;
      END;                                                    -----end begin 4
    END IF;
              v_savepoint := v_savepoint + 1 ;  -- shyam 261006 -- CR 170    ;
EXCEPTION
    WHEN exp_succ_record THEN
    --insert into temp table
    INSERT INTO CMS_EXPCRD_ERRLOG
        VALUES(i.cap_pan_code,errmsg);
    WHEN exp_nocaf_record THEN
    --insert into temp table
    INSERT INTO CMS_EXPCRD_ERRLOG
        VALUES(i.cap_pan_code,errmsg);
    WHEN exp_reject_record THEN
    ROLLBACK TO v_savepoint;
    INSERT INTO CMS_EXPCRD_ERRLOG
        VALUES(i.cap_pan_code,errmsg);
    --RETUEN;
    END;            --<< lOOP END>>
   END LOOP;
--** Rama PrabhuR 270906 - ICICI CR176 - 004
   --** shyam 181206 -- changes in expired cards closure process
      BEGIN
      SELECT COUNT(1) 
      INTO v_expcount
      FROM CMS_APPL_PAN, CMS_BIN_MAST, CMS_PROD_MAST
   WHERE cap_expry_date < LAST_DAY(ADD_MONTHS(SYSDATE,-1)) + 1 
   AND cap_card_stat = '1'  
   AND cap_prod_catg = 'D' 
   AND cbm_inst_bin = SUBSTR(cap_pan_Code,1,6)
   AND cbm_inst_code = 1
   AND cpm_prod_code = cap_prod_Code
   AND cpm_switch_prod IN ('VD','MD');
      EXCEPTION
      WHEN OTHERS THEN
                 v_expcount:=0;
      END;
      IF v_expcount = 0 THEN
          UPDATE CMS_INST_PARAM
         SET cip_param_value = 'Y'
           WHERE cip_inst_code = 1 
           AND cip_param_key LIKE 'EXPCLOSEPROC%';
      END IF;
      errmsg := 'OK';
--** Rama PrabhuR 270906 - ICICI CR176 - 004 END   
EXCEPTION                                                ---Excp of Main begin
   WHEN OTHERS
   THEN
      errmsg := 'MAIN EXCP-' || SQLCODE || ':-' || SQLERRM;
END;                                                        ----End main Begin
/


