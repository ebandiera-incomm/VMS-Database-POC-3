CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Batch_Regen_Pin (v_lupduser IN  NUMBER,
                errmsg  OUT VARCHAR2) IS
v_cap_pin_off    VARCHAR2(10);
v_cap_pingen_date   DATE;
v_errmsg     VARCHAR2(100);
v_cardstat   CMS_APPL_PAN.cap_card_stat%TYPE;
v_cardstat_desc  VARCHAR2(10);

  CURSOR  cur_batch_pin  IS
     SELECT  cbp_file_name, cbp_pan_code ,CBP_FUNC_REMARK, ROWID -- Added by ajit 20 jun 03
   FROM   CMS_BATCH_PIN -- CBP_FUNC_REMARK added by abhijit 07 dec 04 to display remark from batch file in cms_pan_spprt
   WHERE  cbp_pin_regen = 'N';
BEGIN
    FOR   x IN cur_batch_pin
         LOOP
       BEGIN
         SELECT  cap_pin_off, cap_pingen_date  , cap_card_stat ,
          DECODE(cap_card_stat ,'1','OPEN','2','HOTLISTED','3','STOLEN','4','RESTRICTED','9','CLOSED','INVALID STATUS')
         INTO  v_cap_pin_off,v_cap_pingen_date ,v_cardstat  ,
          v_cardstat_desc
         FROM  CMS_APPL_PAN
         WHERE   cap_pan_code = x.cbp_pan_code;
   --DBMS_OUTPUT.PUT_LINE('FIRST CHECK'||V_CAP_PIN_OFF);
   --DBMS_OUTPUT.PUT_LINE('FIRST CHECK'||v_cap_pingen_date);
        IF   v_cardstat  = 1 THEN
           Sp_Regen_Pin( 1,
              x.cbp_pan_code,
            NULL,
            v_cap_pin_off,
            v_cap_pingen_date,
            1,
            x.CBP_FUNC_REMARK, -- added by abhijit 07 dec 04--
            v_lupduser,
			0,
            v_errmsg   );
        IF v_errmsg = 'OK' THEN
           UPDATE CMS_BATCH_PIN
           SET  cbp_pin_regen = 'Y'        ,  cbp_result = 'SUCCESSFULL'
       --WHERE  cbp_pan_code  = x.cbp_pan_code
       --AND  cbp_file_name = x.cbp_file_name;
           WHERE ROWID = X.ROWID;
        ELSE
           UPDATE CMS_BATCH_PIN
           SET  cbp_pin_regen = 'E'    , cbp_result  = v_errmsg
       --WHERE  cbp_pan_code  = x.cbp_pan_code
       --AND  cbp_file_name = x.cbp_file_name;
           WHERE ROWID = X.ROWID;       -- COMMENTED AND ADDED BY AJIT 20 JUN 03
       --dbms_output.put_line('MSG from  repin'||errmsg);
           END IF;
       ELSE
        errmsg:='Given Pan not available as open'||'Its Status is '||v_cardstat||'('||v_cardstat_desc||')';
         UPDATE CMS_BATCH_PIN
         SET  cbp_pin_regen = 'E'    , cbp_result  = errmsg
         WHERE ROWID = X.ROWID;
      --dbms_output.put_line('MSG from  repin'||errmsg);
  END IF  ;
 EXCEPTION
            WHEN NO_DATA_FOUND  THEN
        errmsg := 'No Data found in Pan Master';
         UPDATE CMS_BATCH_PIN
        SET  cbp_pin_regen = 'E'    , cbp_result  =  'NO PAN FOUND'
        WHERE ROWID = X.ROWID;
        Sp_Auton( NULL,
        x.cbp_pan_code,
        'NO DATA FOUND IN CMS_APPL_PAN FOR '||x.cbp_pan_code)    ;
      --dbms_output.put_line('MSG from  repin'||errmsg);
      WHEN  OTHERS  THEN
          errmsg := SQLERRM;
        UPDATE CMS_BATCH_PIN
        SET  cbp_pin_regen = 'E'    , cbp_result  = errmsg
        WHERE ROWID = X.ROWID;
        Sp_Auton( NULL,
        x.cbp_pan_code,
        SQLERRM)    ;
      --dbms_output.put_line('MSG from  repin'||errmsg);
  END;
  END LOOP;
 errmsg := 'OK';
END;
/


