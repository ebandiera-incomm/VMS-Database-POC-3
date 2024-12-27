CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Unblock_Pan_Debit
  (
    prm_instcode IN NUMBER,
    prm_pancode  IN VARCHAR2,
    prm_mbrnumb  IN VARCHAR2,
    prm_remark   IN VARCHAR2,
    prm_rsncode  IN NUMBER,
    prm_lupduser IN NUMBER,
    prm_workmode IN NUMBER,
    prm_errmsg OUT VARCHAR2 )
AS
  dum               NUMBER (1);
  v_cap_prod_catg   VARCHAR2 (2);
  --v_mbrnumb           VARCHAR2 (3);
  v_cap_cafgen_flag CHAR (1);
  v_record_exist    CHAR (1) := 'Y';
  v_caffilegen_flag CHAR (1) := 'N';
  v_issuestatus     VARCHAR2 (2);
  v_pinmailer       VARCHAR2 (1);
  v_cardcarrier     VARCHAR2 (1);
  v_pinoffset       VARCHAR2 (16);
  v_rec_type                VARCHAR2 (1);
  v_acct_no         CMS_APPL_PAN.cap_acct_no%TYPE;
  v_cap_card_stat   CMS_APPL_PAN.cap_card_stat%TYPE;
  v_txn_code        VARCHAR2 (2);
  v_txn_type        VARCHAR2 (2);
  v_txn_mode        VARCHAR2 (2);
  v_del_channel     VARCHAR2 (2);
  v_feetype_code    CMS_FEE_MAST.cfm_feetype_code%TYPE;
  v_fee_code        CMS_FEE_MAST.cfm_fee_code%TYPE;
  v_fee_amt         NUMBER(4);
  v_cust_code       CMS_CUST_MAST.ccm_cust_code%TYPE;
  v_acct_id         CMS_APPL_PAN.cap_acct_id%TYPE;
  v_insta_check         CMS_INST_PARAM.cip_param_value%type;
   v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
 v_isprepaid     boolean default false;


BEGIN --Main begin starts
  /*IF mbrnumb IS NULL
  THEN
  v_mbrnumb := '000';
  ELSE
  v_mbrnumb:=mbrnumb;
  END IF;
  ----commented as passing member number mandatory---
  */
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



  BEGIN --begin 1 starts
    SELECT cap_prod_catg,
      cap_cafgen_flag,
      cap_acct_no,
      cap_card_stat,
      cap_cust_code
    INTO v_cap_prod_catg,
      v_cap_cafgen_flag,
      v_acct_no,
      v_cap_card_stat,
      v_cust_code
    FROM CMS_APPL_PAN
    WHERE cap_inst_code= prm_instcode
    AND cap_pan_code   =v_hash_pan -- prm_pancode
    AND cap_mbr_numb   = prm_mbrnumb;
  EXCEPTION --excp of begin 1
  WHEN NO_DATA_FOUND THEN
    prm_errmsg := 'Pan nuumber not found';
    RETURN;
  WHEN OTHERS THEN
    prm_errmsg := 'Error while selecting then prod category,acctno,cust code--' || SUBSTR(SQLERRM,1,200);
    RETURN;
  END; --begin 1 ends

  ----------Sn start insta card check----------
   BEGIN
   select cip_param_value
   into v_insta_check
   from cms_inst_param
   where cip_param_key='INSTA_CARD_CHECK'
   and cip_inst_code=prm_instcode;

   IF v_insta_check ='Y' THEN
    sp_gen_insta_check(
                        v_acct_no,
                        v_cap_card_stat,
                        prm_errmsg
                      );
      IF prm_errmsg<>'OK' THEN
        RETURN;
      END IF;
   END IF;

   EXCEPTION WHEN OTHERS THEN
   prm_errmsg:='Error while checking the instant card validation. '||substr(sqlerrm,1,200);
   return;
   END;
  ----------En start insta card check----------

  IF v_cap_card_stat <> '0' THEN
    prm_errmsg       := 'Not a valid card status for deblocking ';
    RETURN;
    --RAISE exp_main_reject_record;
  END IF;
   IF v_cap_prod_catg= 'P' THEN
   v_isprepaid:=true;
   END IF;

  IF (v_cap_cafgen_flag = 'N' AND NOT v_isprepaid) THEN --cafgen if
    prm_errmsg        := 'CAF has to be generated atleast once for this pan';
    RETURN;
  ELSE
    ---------------------Sn Check fees if any attached----------------------
    -------------------------------- Sn get Function Master----------------------------
    BEGIN
      SELECT cfm_txn_code,
        cfm_txn_mode,
        cfm_delivery_channel,
        cfm_txn_type
      INTO v_txn_code,
        v_txn_mode,
        v_del_channel,
        v_txn_type
      FROM CMS_FUNC_MAST
      WHERE cfm_func_code = 'UNBLOKSPRT'
        AND cfm_inst_code= prm_instcode;
    EXCEPTION
    WHEN OTHERS THEN
      prm_errmsg :='Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
      --RAISE exp_loop_reject_record;
      RETURN;
    END;
    ------------------------------ En get Function Master----------------------------
    Sp_Calc_Fees_Offline_Debit ( prm_instcode , prm_pancode, v_txn_code , v_txn_mode , v_del_channel , v_txn_type , v_feetype_code, v_fee_code, v_fee_amt, prm_errmsg );
    IF prm_errmsg <> 'OK' THEN
      RETURN;
    END IF;
    IF v_fee_amt > 0 THEN
      ---------Sn INSERT A RECORD INTO CMS_CHARGE_DTL---------------
      BEGIN
        INSERT
        INTO CMS_CHARGE_DTL
          (
            CCD_INST_CODE ,
            CCD_FEE_TRANS ,
            CCD_PAN_CODE ,
            CCD_MBR_NUMB ,
            CCD_CUST_CODE ,
            CCD_ACCT_ID ,
            CCD_ACCT_NO ,
            CCD_FEE_FREQ ,
            CCD_FEETYPE_CODE ,
            CCD_FEE_CODE ,
            CCD_CALC_AMT ,
            CCD_EXPCALC_DATE ,
            CCD_CALC_DATE ,
            CCD_FILE_DATE ,
            CCD_FILE_NAME ,
            CCD_FILE_STATUS ,
            CCD_INS_USER ,
            CCD_INS_DATE ,
            CCD_LUPD_USER ,
            CCD_LUPD_DATE ,
            CCD_PROCESS_ID ,
            CCD_PLAN_CODE,
            ccd_pan_code_encr
          )
          VALUES
          (
            prm_instcode,
            NULL,
           -- prm_pancode
            v_hash_pan,
            prm_mbrnumb,
            v_cust_code,
            v_acct_id,
            v_acct_no,
            'R',
            v_feetype_code,
            v_fee_code,
            v_fee_amt,
            SYSDATE,
            SYSDATE,
            NULL,
            NULL,
            NULL,
            prm_lupduser,
            SYSDATE,
            prm_lupduser,
            SYSDATE,
            NULL,
            NULL,
            v_encr_pan
          );
      EXCEPTION
      WHEN OTHERS THEN
        prm_errmsg := ' Error while inserting into charge detail ' || SUBSTR
        (
          SQLERRM,1,200
        )
        ;
        RETURN;
      END;
      ----------------En INSERT A RECORD INTO CMS_CHARGE_DTL-----------------
    END IF;
    -----------start update cms appl pan table to unblock the card----------------
    BEGIN
      UPDATE CMS_APPL_PAN
      SET cap_card_stat  = '1'
      WHERE cap_pan_code = v_hash_pan --prm_pancode
      AND cap_inst_code  = prm_instcode;
      IF SQL%ROWCOUNT   <> 1 THEN
        prm_errmsg      := 'Error while updating card status';
        -- RAISE exp_main_reject_record;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      prm_errmsg :='Error while updating card status'|| SUBSTR (SQLERRM, 1, 200);
      RETURN;
      --RAISE exp_main_reject_record;
    END;
    -----------end update cms appl pan table to unblock the card----------------
    ------------- start Insert reords in pan support after successful----------------
    BEGIN
      INSERT
      INTO CMS_PAN_SPPRT
        (
          cps_inst_code,
          cps_pan_code,
          cps_mbr_numb,
          cps_prod_catg,
          cps_spprt_key,
          cps_spprt_rsncode,
          cps_func_remark,
          cps_ins_user,
          cps_lupd_user,
          cps_cmd_mode,
          cps_pan_code_encr
        )
        VALUES
        (
          prm_instcode,
          --prm_pancode
          v_hash_pan,
          prm_mbrnumb,
          v_cap_prod_catg,
          'UNBLOCK',
          prm_rsncode,
          prm_remark,
          prm_lupduser,
          prm_lupduser,
          prm_workmode,
          v_encr_pan
        );
    EXCEPTION
    WHEN OTHERS THEN
      prm_errmsg := 'Error while inserting in PAN support -- ' || SUBSTR
      (
        SQLERRM,1,200
      )
      ;
      RETURN;
    END;
    ------------- end Insert reords in pan support after successful----------------
    IF(NOT v_isprepaid) THEN -- not isprepaid             --Sn if not v_isprepaid
    ----------------start of Caf Refresh------------------------------------
    BEGIN
      BEGIN
        SELECT cci_file_gen,
          cci_seg12_issue_stat,
          cci_seg12_pin_mailer,
          cci_seg12_card_carrier,
          cci_pin_ofst, cci_rec_typ
        INTO v_caffilegen_flag,
          v_issuestatus,
          v_pinmailer,
          v_cardcarrier,
          v_pinoffset,
          v_rec_type
        FROM CMS_CAF_INFO
        WHERE cci_inst_code = prm_instcode
        AND cci_pan_code    = v_hash_pan --DECODE(LENGTH(prm_pancode), 16,prm_pancode
         -- || '   ', 19,prm_pancode)
          -- RPAD (prm_pancode, 19, ' ')
        AND cci_mbr_numb = prm_mbrnumb
        AND cci_file_gen = 'N'
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
        prm_errmsg := 'Error while selecting caf details '|| SUBSTR (SQLERRM, 1, 300);
      RETURN;
      END;

      DELETE
        FROM CMS_CAF_INFO
        WHERE cci_inst_code = prm_instcode
        AND cci_pan_code    = v_hash_pan --DECODE(LENGTH(prm_pancode), 16,prm_pancode
        --  || '   ', 19,prm_pancode) --RPAD (prm_pancode, 19, ' ')
        AND cci_mbr_numb = prm_mbrnumb;
      --call the procedure to insert into cafinfo
     -- Sp_Caf_Rfrsh (prm_instcode, prm_pancode, prm_mbrnumb, SYSDATE, 'C', NULL, 'DBLOK', prm_lupduser, prm_errmsg );
      Sp_Caf_Rfrsh (prm_instcode, prm_pancode, prm_mbrnumb, SYSDATE, 'C', NULL, 'DBLOK', prm_lupduser, prm_pancode,prm_errmsg );
      IF prm_errmsg != 'OK' THEN
        prm_errmsg  := 'From caf refresh -- ' || prm_errmsg;
        RETURN;
      END IF;
      IF v_rec_type = 'A' THEN
         v_issuestatus := '00';                -- no pinmailer no embossa.
         v_pinoffset := RPAD ('Z', 16, 'Z');        -- keep original pin .
      END IF;
      -- Update caf_info only if record was exist earlier
      IF /*prm_workmode = 1 AND*/ v_record_exist = 'Y' THEN
        UPDATE CMS_CAF_INFO
        SET cci_file_gen         = v_caffilegen_flag,
          cci_seg12_issue_stat   = v_issuestatus,
          cci_seg12_pin_mailer   = v_pinmailer,
          cci_seg12_card_carrier = v_cardcarrier,
          cci_pin_ofst           = v_pinoffset
        WHERE cci_inst_code      = prm_instcode
        AND cci_pan_code         = v_hash_pan --DECODE(LENGTH(prm_pancode), 16,prm_pancode
         -- || '   ', 19,prm_pancode)--RPAD (prm_pancode, 19, ' ')
        AND cci_mbr_numb = prm_mbrnumb;
      END IF;
      /*IF prm_workmode = 1 AND v_record_exist = 'N' THEN
        UPDATE CMS_CAF_INFO
        SET cci_file_gen    = 'Y'
        WHERE cci_inst_code = prm_instcode
        AND cci_pan_code    = DECODE(LENGTH(prm_pancode), 16,prm_pancode
          || '   ', 19,prm_pancode)--RPAD (prm_pancode, 19, ' ')
        AND cci_mbr_numb = prm_mbrnumb;
      END IF;*/
    EXCEPTION
    WHEN OTHERS THEN
      prm_errmsg := 'Error from caf refreshing -- ' || SUBSTR(SQLERRM,1,200);
      RETURN;
    END;
    ----------------------------End of caf refresh------------------------------
    END IF;                                               --En if not v_isprepaid
  END IF; --cafgen if
EXCEPTION
WHEN OTHERS THEN
  prm_errmsg := 'Error while unblocking the PAN -- ' || SUBSTR(SQLERRM,1,200);
  RETURN;
END;
/
SHOW ERRORS

