CREATE OR REPLACE PROCEDURE VMSCMS.sp_update_limits_debit
  (
    p_instcode            IN NUMBER ,
    p_pancode             IN VARCHAR2 ,
    p_mbrnumb             IN VARCHAR2 ,
    p_remark              IN VARCHAR2 ,
    p_rsncode             IN NUMBER ,
    p_atmofflinelimit     IN NUMBER ,
    p_atmonlinelimit      IN NUMBER ,
    p_posofflinelimit     IN NUMBER ,
    p_posonlinelimit      IN NUMBER ,
    p_paymentofflinelimit IN NUMBER,
    p_paymentonlinelimit  IN NUMBER,
    p_flag                IN VARCHAR2, -- 2 indicate the process used, U - upload, S - Screen
    p_lupduser            IN NUMBER ,
    p_errmsg OUT VARCHAR2 )
AS
  v_cap_prod_catg      VARCHAR2(2) ;
  v_mbrnumb            VARCHAR2(3) ;
  v_dum                NUMBER ;
  v_cap_card_stat      CHAR (1) ;
  v_cap_cafgen_flag    CHAR(1) ;
  v_online_aggr_Limit  NUMBER(10);
  v_offline_aggr_Limit NUMBER(10);
  v_cap_atmOnline_lmt  NUMBER(10);
  v_cap_posOnline_lmt  NUMBER(10);
  v_cap_payment_offline_limit CMS_APPL_PAN.cap_panmast_param1%type ;
  v_cap_payment_online_limit CMS_APPL_PAN.cap_panmast_param1%type ;
  v_cap_acct_no             cms_appl_pan.cap_acct_no%type;
  v_insta_check             CMS_INST_PARAM.cip_param_value%type;
  v_savepoint NUMBER DEFAULT 0;
   v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;

 
BEGIN --Main begin starts
  v_mbrnumb := p_mbrnumb;
  /*IF v_mbrnumb IS NULL  THEN
  v_mbrnumb := '000';
  END IF;
  ---commented as member number is compulsory-----
  */
  p_errmsg    := 'OK';

--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(p_pancode);
EXCEPTION
WHEN OTHERS THEN
p_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
  RETURN ;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(p_pancode);
EXCEPTION
WHEN OTHERS THEN
p_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
  RETURN ;
END;
--EN create encr pan
  


  IF p_remark IS NULL THEN
    p_errmsg  := 'PLEASE ENTER APPROPRIATE REMARK';
    RETURN ;
  END IF;
  BEGIN
    SELECT cap_prod_catg,
      cap_card_stat,
      cap_cafgen_flag,
      CAP_ATM_ONLINE_LIMIT,
      CAP_POS_ONLINE_LIMIT,
      cap_panmast_param1,
      cap_panmast_param2,
      cap_acct_no
    INTO v_cap_prod_catg,
      v_cap_card_stat,
      v_cap_cafgen_flag,
      v_cap_atmOnline_lmt,
      v_cap_posOnline_lmt,
      v_cap_payment_offline_limit,
      v_cap_payment_online_limit,
      v_cap_acct_no
    FROM CMS_APPL_PAN
    WHERE cap_pan_code = v_hash_pan--p_pancode
    AND cap_mbr_numb   = v_mbrnumb
    AND cap_inst_code  = p_instcode;
  EXCEPTION --excp of begin 1
  WHEN NO_DATA_FOUND THEN
    p_errmsg := 'NO SUCH PAN FOUND';
    RETURN ;
  WHEN OTHERS THEN
    p_errmsg := 'ERROR WHILE GETTING CARD DETAILS FROM PAN MASTER : '|| SUBSTR(SQLERRM, 1, 100 );
    RETURN ;
  END;
  SAVEPOINT v_savepoint ;
  
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
  IF p_flag <> 'U' THEN
    BEGIN
      INSERT
      INTO CMS_UPDATE_CRDLIMITS
        (
          CUC_PAN_CODE,
          CUC_OLDATM_LIMIT,
          CUC_NEWATM_LIMIT,
          CUC_OLDPOS_LIMIT,
          CUC_NEWPOS_LIMIT,
          CUC_PROCESS_DATE,
          CUC_PROCESS_USED,
          CUC_LUPD_USER ,
          CUC_UPDCRD_LIMIT_PARAM1,
          CUC_UPDCRD_LIMIT_PARAM2,
          CUC_PAN_CODE_encr
        )
        VALUES
        (
         -- p_pancode
          v_hash_pan,
          NVL(v_cap_atmOnline_lmt,0),
          NVL(p_atmonlinelimit,0),
          NVL(v_cap_posOnline_lmt,0),
          NVL(p_posonlinelimit,0),
          SYSDATE,
          'S',
          p_lupduser,
          NVL(v_cap_payment_online_limit,0) ,
          NVL(p_paymentonlinelimit,0),
          v_encr_pan
        );
    EXCEPTION
    WHEN OTHERS THEN
      p_errmsg:='Error while inserting data in update creditlimits-'||SUBSTR
      (
        SQLERRM,1,200
      )
      ;
      RETURN;
    END;
  ELSIF p_flag = 'U' THEN
    BEGIN
      UPDATE CMS_UPDATE_CRDLIMITS
      SET CUC_OLDATM_LIMIT      = v_cap_atmOnline_lmt,
        CUC_OLDPOS_LIMIT        = v_cap_posOnline_lmt,
        CUC_UPDCRD_LIMIT_PARAM1 = v_cap_payment_online_limit,
        CUC_PROCESS_USED        = 'U'
      WHERE CUC_PAN_CODE        = v_hash_pan--p_pancode
      AND CUC_DONE_FLAG         = 'P'
      AND cuc_inst_code         = p_instcode ;
    EXCEPTION
    WHEN OTHERS THEN
      p_errmsg:='Error while updating data in update creditlimits-'||SUBSTR(SQLERRM,1,200);
      RETURN;
    END;
  END IF;
  IF v_cap_cafgen_flag = 'N' THEN --cafgen if
    p_errmsg          := 'CAF HAS TO BE GENERATED ATLEAST ONCE FOR THIS PAN';
    --ROLLBACK TO v_savepoint ;
    RETURN ;
  ELSE
    IF v_cap_card_stat = 1 THEN
      BEGIN
        -- SN: BELOW IS THE BANK SPECIFIC PROCEDURE TO GET LIMITS
        SP_BANK_AGGR_LIMITS ( p_instcode , p_posonlinelimit , p_posofflinelimit, p_atmonlinelimit, p_atmofflinelimit, v_online_aggr_Limit, v_offline_aggr_Limit, p_errmsg ) ;
        IF p_errmsg <> 'OK' THEN
          --ROLLBACK TO v_savepoint ;
          p_errmsg := 'ERROR FROM PROCESS WHILE SETTING AGGREGATE LIMITS';
          RETURN ;
        END IF ;
        -- EN: BELOW IS THE BANK SPECIFIC PROCEDURE TO GET LIMITS
        v_online_aggr_Limit  := p_posonlinelimit  + p_atmonlinelimit;
        v_offline_aggr_Limit := p_posofflinelimit + p_atmofflinelimit ;
        UPDATE CMS_APPL_PAN
        SET cap_atm_offline_limit = p_atmofflinelimit ,
          cap_atm_online_limit    = p_atmonlinelimit ,
          cap_pos_offline_limit   = p_posofflinelimit ,
          cap_pos_online_limit    = p_posonlinelimit ,
          cap_online_aggr_limit   = v_online_aggr_limit ,
          cap_offline_aggr_limit  = v_offline_aggr_limit,
          cap_panmast_param1      = p_paymentofflinelimit,
          cap_panmast_param2      = p_paymentonlinelimit
        WHERE cap_inst_code       = p_instcode
        AND cap_pan_code          = v_hash_pan--p_pancode
        AND cap_mbr_numb          = v_mbrnumb ;
        IF SQL%ROWCOUNT          <> 1 THEN
          p_errmsg               := 'PROBLEM IN UPDATION OF STATUS FOR PAN '|| p_pancode ;
          --ROLLBACK TO v_savepoint ;
          RETURN ;
        END IF;
      END ;
    END IF;
    BEGIN
      INSERT
      INTO CMS_PAN_SPPRT
        (
          CPS_INST_CODE ,
          CPS_PAN_CODE ,
          CPS_MBR_NUMB ,
          CPS_PROD_CATG ,
          CPS_SPPRT_KEY ,
          CPS_SPPRT_RSNCODE ,
          CPS_FUNC_REMARK ,
          CPS_INS_USER ,
          CPS_LUPD_USER,
          cps_pan_code_encr
        )
        VALUES
        (
          p_instcode ,
         -- p_pancode 
         v_hash_pan,
          v_mbrnumb ,
          v_cap_prod_catg ,
          'LIMT' ,
          p_rsncode ,
          p_remark ,
          p_lupduser ,
          p_lupduser,
          v_encr_pan
        );
    EXCEPTION --excp of begin 3
    WHEN OTHERS THEN
      p_errmsg := 'ERROR WHILE INSERTION IN PAN SUPPORT '||SQLERRM;
      --ROLLBACK TO v_savepoint ;
      RETURN ;
    END; --begin 3 ends
    SELECT COUNT(*)
    INTO v_dum
    FROM CMS_CAF_INFO
    WHERE cci_inst_code     = p_instcode
--    AND TRUNC(cci_pan_code) = p_pancode
    AND cci_pan_code =v_hash_pan
    AND cci_mbr_numb        = v_mbrnumb ;
    IF v_dum                = 1 THEN--that means there is a row in cafinfo for that pan but file is not generated
      DELETE
      FROM CMS_CAF_INFO
      WHERE cci_inst_code     = p_instcode
      --AND TRUNC(cci_pan_code) = p_pancode
      AND cci_pan_code = v_hash_pan
      AND cci_mbr_numb        = v_mbrnumb ;
    END IF;
--    sp_caf_rfrsh(p_instcode,p_pancode,v_mbrnumb,SYSDATE,'C',p_remark,'LIMIT',p_lupduser,p_errmsg) ;
    sp_caf_rfrsh(p_instcode,p_pancode,v_mbrnumb,SYSDATE,'C',p_remark,'LIMIT',p_lupduser,v_encr_pan,p_errmsg) ;
    IF p_errmsg <> 'OK' THEN
      --ROLLBACK TO v_savepoint ;
      p_errmsg := 'FROM CAF REFRESH -- '||p_errmsg;
      RETURN ;
    END IF;
  END IF; --cafgen if
EXCEPTION --Excp of main begin
WHEN OTHERS THEN
  ROLLBACK TO v_savepoint ;
  p_errmsg := 'Error while updating limits-- '|| SUBSTR( SQLERRM , 1 , 100 ) ;
END; --Main begin ends
/


SHOW ERRORS