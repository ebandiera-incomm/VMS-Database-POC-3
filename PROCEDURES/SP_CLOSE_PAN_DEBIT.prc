CREATE OR REPLACE PROCEDURE VMSCMS.sp_close_pan_debit
  (
    p_instcode IN NUMBER ,
    p_pancode  IN VARCHAR2 ,
    p_mbrnumb  IN VARCHAR2 ,
    p_rsncode  IN NUMBER ,
    p_remark   IN VARCHAR2 ,
    p_lupduser IN NUMBER ,
    p_workmode IN NUMBER,
    p_errmsg OUT VARCHAR2 )
AS
  dum               NUMBER ;
  v_mbrnumb         VARCHAR2(3) ;
  v_cap_prod_catg   VARCHAR2(2) ;
  v_cap_cafgen_flag CHAR(1) ;
  v_record_exist        CHAR (1) := 'Y';
  v_caffilegen_flag    CHAR (1) := 'N';
  v_issuestatus            VARCHAR2 (2);
  v_pinmailer                VARCHAR2 (1);
  v_cardcarrier            VARCHAR2 (1);
  v_pinoffset                VARCHAR2 (16);
  v_rec_type                VARCHAR2 (1);
  v_cap_card_stat   cms_appl_pan.cap_card_stat%type;
  v_cap_acct_no     cms_appl_pan.cap_acct_no%type;
  v_insta_check     CMS_INST_PARAM.cip_param_value%type;
   v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;

  --Excp_main  EXCEPTION;
BEGIN --Main begin starts
  p_errmsg     := 'OK';
  
--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(p_pancode);
EXCEPTION
WHEN OTHERS THEN
p_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
  RETURN;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(p_pancode);
EXCEPTION
WHEN OTHERS THEN
p_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
  RETURN;
END;
--EN create encr pan

  IF p_mbrnumb IS NULL THEN
    p_errmsg   := ' Member number cannot be null';
    RETURN;
  ELSE
    v_mbrnumb := p_mbrnumb;
  END IF;
  BEGIN --begin 1 starts
    SELECT cap_prod_catg,
           cap_cafgen_flag,
           cap_card_stat,
            cap_acct_no
    INTO v_cap_prod_catg,
      v_cap_cafgen_flag,
      v_cap_card_stat,
      v_cap_acct_no
    FROM CMS_APPL_PAN
    WHERE cap_pan_code   = v_hash_pan--p_pancode
    AND cap_mbr_numb     = v_mbrnumb
    AND cap_inst_code    = p_instcode;
    IF v_cap_prod_catg= 'P' THEN 
    null;
    ELSIF v_cap_cafgen_flag = 'N' THEN
      p_errmsg          := 'CAF HAS TO BE GENERATED ATLEAST ONCE FOR THIS PAN';
      RETURN;
    END IF;
  EXCEPTION --excp of begin 1
  WHEN NO_DATA_FOUND THEN
    p_errmsg := 'No such pan found ';
    RETURN;
  WHEN OTHERS THEN
    p_errmsg := 'Error while selecting card detail ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --SAVEPOINT v_savepoint ;
  --begin 1 ends
  
  ----------Sn start insta card check----------  /*added by amit on 24 Sep'10 for not to allow any supprt func on insta card.*/
   BEGIN 
   select cip_param_value
   into v_insta_check
   from cms_inst_param
   where cip_param_key='INSTA_CARD_CHECK'
   and cip_inst_code=p_instcode;
   
   IF v_insta_check ='Y' THEN
    sp_gen_insta_check(
                        v_cap_acct_no,
                        v_cap_card_stat,
                        p_errmsg
                      );
      IF p_errmsg <>'OK' THEN
        RETURN;
      END IF;
   END IF;
   
   EXCEPTION WHEN OTHERS THEN
   p_errmsg:='Error while checking the instant card validation. '||substr(sqlerrm,1,200);
   return;
   END;
  ----------En start insta card check----------  
  
  BEGIN
    UPDATE CMS_APPL_PAN
    SET cap_card_stat  = 9 , -- to close card use card stat as 9
      cap_lupd_user    = p_lupduser
    WHERE cap_pan_code =v_hash_pan-- p_pancode
    AND cap_mbr_numb   = v_mbrnumb
    AND cap_inst_code  = p_instcode;
    IF SQL%ROWCOUNT   <> 1 THEN
      p_errmsg        := 'Problem in updation of status for pan '||p_pancode||'.';
      RETURN;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg := 'Error while changing card status ' || SUBSTR(sqlerrm,1, 200);
    RETURN;
  END;
  -------------------------------
  -- SN :INSERT INTO PAN SUPPORT
  -------------------------------
  BEGIN
    INSERT
    INTO CMS_PAN_SPPRT
      (
        CPS_INST_CODE ,
        CPS_PAN_CODE ,
        CPS_MBR_NUMB ,
        CPS_PROD_CATG ,
        CPS_SPPRT_KEY ,
        CPS_SPPRT_RSNCODE,
        CPS_FUNC_REMARK ,
        CPS_INS_USER ,
        CPS_LUPD_USER,
        CPS_CMD_MODE,
        cps_pan_code_encr
      )
      VALUES
      (
        p_instcode ,
        --p_pancode 
        v_hash_pan,
        v_mbrnumb ,
        v_cap_prod_catg ,
        'CARDCLOSE' ,
        p_rsncode ,
        p_remark,
        p_lupduser ,
        p_lupduser ,
        p_workmode,
        v_encr_pan
      );
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg := 'Error while adding record to support log';
    RETURN;
  END;
  -------------------------------
  -- EN :INSERT INTO PAN SUPPORT
  -------------------------------
  --Caf Refresh
  /*SELECT COUNT(1)
  INTO dum
  FROM CMS_CAF_INFO
  WHERE cci_inst_code = p_instcode
  AND cci_pan_code    = DECODE(LENGTH(p_pancode), 16,p_pancode
  || '   ', 19,p_pancode)
  AND cci_mbr_numb = v_mbrnumb;
  IF dum           = 1 THEN--that means there is a row in cafinfo for that pan but file is not generated
  BEGIN
  DELETE
  FROM CMS_CAF_INFO
  WHERE cci_inst_code = p_instcode
  AND cci_pan_code    = DECODE(LENGTH(p_pancode), 16,p_pancode
  || '   ', 19,p_pancode)
  AND cci_mbr_numb = v_mbrnumb;
  IF sql%rowcount  = 0 THEN
  p_errmsg      := 'Error while deleting record from caf, record not deleted ';
  RETURN;
  END IF;
  EXCEPTION
  WHEN OTHERS THEN
  p_errmsg := 'Error while deleting record from CAF' || SUBSTR(sqlerrm,1,200);
  RETURN;
  END;
  END IF;*/
  IF v_cap_prod_catg= 'P' THEN --Sn if prepaid
  null;
  ELSE
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
    FROM CMS_CAF_INFO
    WHERE cci_inst_code = p_instcode
    AND cci_pan_code    = v_hash_pan--DECODE(LENGTH(p_pancode), 16,p_pancode
    --  || '   ', 19,p_pancode)--RPAD (p_pancode, 19, ' ')
    AND cci_mbr_numb = v_mbrnumb
    AND cci_file_gen = 'N' -- Only when a CAF is not generated
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
    p_errmsg := 'Error while selecting caf details '|| SUBSTR (SQLERRM, 1, 300);
    RETURN;
  END;
  --En get caf detail
  --Sn delete record from CAF
    DELETE FROM CMS_CAF_INFO
    WHERE cci_inst_code = p_instcode
    AND cci_pan_code =v_hash_pan-- DECODE(LENGTH(p_pancode), 16,p_pancode || '   ',19,p_pancode)--RPAD (p_pancode, 19, ' ')
    AND cci_mbr_numb = v_mbrnumb;    
    --En delete record from CAF
  --call the procedure to insert into cafinfo
  
  BEGIN
  --  sp_caf_rfrsh(p_instcode,p_pancode, v_mbrnumb,SYSDATE,'C',NULL,'CLOSE',p_lupduser,p_errmsg) ;
    sp_caf_rfrsh(p_instcode,p_pancode, v_mbrnumb,SYSDATE,'C',NULL,'CLOSE',p_lupduser,p_pancode,p_errmsg) ;
    IF p_errmsg != 'OK' THEN
      p_errmsg  := 'From caf refresh -- '||p_errmsg;
      RETURN;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg := 'Error while deleting record from CAF' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;  
  IF v_rec_type = 'A' THEN
      v_issuestatus := '00';                -- no pinmailer no embossa.
      v_pinoffset := RPAD ('Z', 16, 'Z');        -- keep original pin .
  END IF;
     --Sn update caf info
     IF v_record_exist = 'Y' THEN
     BEGIN
        UPDATE CMS_CAF_INFO
        SET     cci_seg12_issue_stat = v_issuestatus,
         cci_seg12_pin_mailer = v_pinmailer,
         cci_seg12_card_carrier = v_cardcarrier,
         cci_pin_ofst = v_pinoffset                  -- rahul 10 Mar 05
        WHERE  cci_inst_code = p_instcode
        AND    cci_pan_code =v_hash_pan-- DECODE(LENGTH(p_pancode), 16,p_pancode || '   ',
                  --19,p_pancode)--RPAD (p_pancode, 19, ' ')
        AND cci_mbr_numb    = v_mbrnumb;
     EXCEPTION
     WHEN OTHERS THEN
      p_errmsg := 'Error updating CAF record ' || substr(sqlerrm,1,200);
      RETURN;
     END;
     END IF;
    --En update caf info
    END IF; --En if prepaid
EXCEPTION
  -- WHEN excp_main THEN
  --
  --  p_errmsg := p_errmsg ;
  --
  --  ROLLBACK TO v_savepoint ;
WHEN OTHERS THEN
  p_errmsg := 'MAIN EXCEPTION -- '|| SUBSTR(SQLERRM ,1, 100) ;
END;
/


show error