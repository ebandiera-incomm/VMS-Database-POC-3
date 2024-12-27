CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Hotlist_Pan_Debit
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
  v_cap_prod_catg   VARCHAR2 (2);
  v_mbrnumb         VARCHAR2 (3);
  dum               NUMBER;
  v_cap_card_stat   CHAR (1);
  v_cap_cafgen_flag CHAR (1);
  v_record_exist    CHAR (1) := 'Y';
  v_caffilegen_flag CHAR (1) := 'N';
  v_issuestatus     VARCHAR2 (2);
  v_pinmailer       VARCHAR2 (1);
  v_cardcarrier     VARCHAR2 (1);
  v_pinoffset       VARCHAR2 (16);
  v_acctno          CMS_APPL_PAN.cap_acct_no%TYPE;
  v_rec_type  VARCHAR2 (1);
  v_tran_code VARCHAR2(2);
  v_tran_mode VARCHAR2(1);
  v_tran_type VARCHAR2(1);
  v_delv_chnl VARCHAR2(2);
  v_feetype_code CMS_FEE_MAST.cfm_feetype_code%TYPE;
  v_fee_code CMS_FEE_MAST.cfm_fee_code%TYPE;
  v_fee_amt NUMBER(4);
  v_cust_code CMS_CUST_MAST.ccm_cust_code%TYPE;
  v_acct_id CMS_APPL_PAN.cap_acct_id%TYPE;
  v_errmsg VARCHAR2(500);
  v_insta_check         CMS_INST_PARAM.cip_param_value%type;

  v_hash_pan                                                    CMS_APPL_PAN.CAP_PAN_CODE%TYPE; --aded on 030111
     v_encr_pan                CMS_APPL_PAN.cap_pan_code_encr%TYPE;
BEGIN --Main begin starts
  IF prm_mbrnumb IS NULL THEN
    prm_errmsg   := 'member number is not defined in master';
    RETURN;
  ELSE
    v_mbrnumb := prm_mbrnumb;
  END IF;
  prm_errmsg    := 'OK';
  IF prm_remark IS NULL THEN
    prm_errmsg  := 'Please enter appropriate remark';
    RETURN;
  END IF;

   --SN CREATE HASH PAN
                 BEGIN
                 v_hash_pan := Gethash(prm_pancode);
                  EXCEPTION
                     WHEN OTHERS THEN
                   v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
                RETURN;
             END;
    --EN CREATE HASH PAN

  --SN create encr pan
                  BEGIN
                 v_encr_pan := Fn_Emaps_Main(prm_pancode);
                 EXCEPTION
                 WHEN OTHERS THEN
                   v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
                RETURN;
                 END;
    --EN create encr pan

  BEGIN --begin 1 starts
    SELECT cap_prod_catg,
      cap_card_stat,
      cap_cafgen_flag,
      cap_acct_no,
      cap_cust_code --added by tejas 14mar06 for instant
    INTO v_cap_prod_catg,
      v_cap_card_stat,
      v_cap_cafgen_flag,
      v_acctno ,
      v_cust_code
    FROM CMS_APPL_PAN
    WHERE cap_pan_code = v_hash_pan --prm_pancode
    AND cap_mbr_numb   = v_mbrnumb
    AND cap_inst_code  = prm_instcode;
  EXCEPTION --excp of begin 1
  WHEN NO_DATA_FOUND THEN
    prm_errmsg := 'Pan number not found in master';
    RETURN;
  WHEN OTHERS THEN
    prm_errmsg := 'Error while selecting pan details' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;                            --begin 1 ends

  ----------Sn start insta card check----------  /*added by amit on 24 Sep'10 for not to allow any supprt func on insta card.*/
   BEGIN
   select cip_param_value
   into v_insta_check
   from cms_inst_param
   where cip_param_key='INSTA_CARD_CHECK'
   and cip_inst_code=prm_instcode;

   IF v_insta_check ='Y' THEN
    sp_gen_insta_check(
                        v_acctno,
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

 IF v_cap_prod_catg= 'P' THEN
   null;
 ELSIF v_cap_cafgen_flag = 'N' THEN --cafgen if
    prm_errmsg        := 'CAF has to be generated atleast once for this pan';
    RETURN;
  END IF;
  IF v_cap_card_stat != 1 THEN
    prm_errmsg       := 'Card is not available as open';
    RETURN;
  END IF;
  --Sn Check fees if any attached
  BEGIN
    SELECT cfm_txn_code,
      cfm_txn_mode,
      cfm_delivery_channel,
      cfm_txn_type
    INTO v_tran_code,
      v_tran_mode,
      v_delv_chnl,
      v_tran_type
    FROM CMS_FUNC_MAST
    WHERE cfm_func_code = 'HTLST'
    AND cfm_inst_code   = prm_instcode;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
    --RAISE exp_loop_reject_record;
    RETURN;
  END;
  Sp_Calc_Fees_Offline_Debit ( prm_instcode , prm_pancode
  , v_tran_code , v_tran_mode , v_delv_chnl , v_tran_type , v_feetype_code, v_fee_code, v_fee_amt, v_errmsg );
  IF v_errmsg  <> 'OK' THEN
    prm_errmsg := v_errmsg;
    RETURN;
  END IF;
  IF v_fee_amt > 0 THEN
    --Sn INSERT A RECORD INTO CMS_CHARGE_DTL
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
          --prm_pancode,
          v_hash_pan,
          v_mbrnumb,
          v_cust_code,
          v_acct_id,
          v_acctno,
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
      prm_errmsg := ' Error while inserting into charge dtl ' || SUBSTR
      (
        SQLERRM,1,200
      )
      ;
      RETURN;
    END;
    --En INSERT A RECORD INTO CMS_CHARGE_DTL
  END IF;
  --En check fees if amy  attched
  --update the card status in cms_appl_pan
  BEGIN --Begin 2 starts
    UPDATE CMS_APPL_PAN
    SET cap_card_stat   ='2'
    WHERE cap_inst_code = prm_instcode
    AND cap_pan_code    = v_hash_pan;
    --prm_pancode;
    IF SQL%ROWCOUNT    != 1 THEN
      prm_errmsg       := 'Problem in updation of status for pan ' || prm_pancode || '.';
      RETURN;
    END IF;
  EXCEPTION --excp of begin 2
  WHEN OTHERS THEN
    prm_errmsg := 'Error while updating pan status' || SUBSTR(sqlerrm,1,200) ;
    RETURN;
  END; --begin 2 ends
  --commented on 10-07-02 to allow multiple rows for hotlisting in cms_pan_spprt
  BEGIN --Begin 3 starts
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
       -- prm_pancode,
       v_hash_pan,
        v_mbrnumb,
        v_cap_prod_catg,
        'HTLST',
        prm_rsncode,
        prm_remark,
        prm_lupduser,
        prm_lupduser,
        prm_workmode,
        v_encr_pan
      );
  EXCEPTION
    --excp of begin 3
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting records for support detail' || SUBSTR
    (
      sqlerrm,1,200
    )
    ;
    RETURN;
  END; --begin 3 ends
  --commented on 10-07-02 to allow multiple rows for hotlisting in cms_pan_spprt
  ----------------------------------------------------------------------------------------------------------------
   IF v_cap_prod_catg= 'P' THEN
   null;
   ELSE
  --Caf Refresh
  BEGIN --Begin 5
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
      WHERE cci_inst_code = prm_instcode
      AND cci_pan_code    = v_hash_pan
      --DECODE(LENGTH(prm_pancode), 16,prm_pancode|| '   ', 19,prm_pancode)--RPAD (prm_pancode, 19, ' ')
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
      prm_errmsg := 'Error while selecting pan detail ' || SUBSTR(sqlerrm,1,200);
      RETURN;
    END;
    --------------------------- record should be deleted before calling sp_caf_rfrsh-----------------------------------
    DELETE
    FROM CMS_CAF_INFO
    WHERE cci_inst_code = prm_instcode
    AND cci_pan_code    =v_hash_pan
    -- DECODE(LENGTH(prm_pancode), 16,prm_pancode  || '   ', 19,prm_pancode)--RPAD (prm_pancode, 19, ' ')
    AND cci_mbr_numb = v_mbrnumb;

  --  Sp_Caf_Rfrsh (prm_instcode, prm_pancode, v_mbrnumb, SYSDATE, 'C', prm_remark, 'HTLST', prm_lupduser, prm_errmsg );

    Sp_Caf_Rfrsh (prm_instcode, prm_pancode, v_mbrnumb, SYSDATE, 'C', prm_remark, 'HTLST', prm_lupduser,prm_pancode, prm_errmsg );
    IF prm_errmsg != 'OK' THEN
      prm_errmsg  := 'From caf refresh -- ' || prm_errmsg;
      RETURN;
    END IF;
    DBMS_OUTPUT.put_line (prm_errmsg);
    ----------------- Rahul 1 apr 05 Update caf_info only if record was exist earlier-----------------
    ----------------- if this is the first support function we are performing on card-----------------------------
    --------------------- then make issue status =00 and pin offset 'Z'---------------------------
    IF v_rec_type    = 'A' THEN
      v_issuestatus := '00';                -- no pinmailer no embossa.
      v_pinoffset   := RPAD ('Z', 16, 'Z'); -- keep original pin .
    END IF;
    IF v_record_exist = 'Y' THEN
      UPDATE CMS_CAF_INFO
      SET cci_seg12_issue_stat = v_issuestatus,
        cci_seg12_pin_mailer   = v_pinmailer,
        cci_seg12_card_carrier = v_cardcarrier,
        cci_pin_ofst           = v_pinoffset -- rahul 10 Mar 05
      WHERE cci_inst_code      = 1
      AND cci_pan_code         = v_hash_pan
      --DECODE(LENGTH(prm_pancode), 16,prm_pancode  || '   ', 19,prm_pancode)--RPAD (prm_pancode, 19, ' ')
      AND cci_mbr_numb = v_mbrnumb;
    END IF;
  EXCEPTION --Excp 5
  WHEN OTHERS THEN
    prm_errmsg := 'Error while updating caf record ' || SUBSTR(SQLERRM,1,200);
    RETURN;
  END; --End of begin 5
  END IF;
  ---------------------------------------------------------------------------------------------------------------------
  DBMS_OUTPUT.put_line (prm_errmsg);
EXCEPTION --Excp of main begin
WHEN OTHERS THEN
  prm_errmsg := 'Main Exception -- ' || SUBSTR(SQLERRM,1,200);
END; --Main begin ends
/
SHOW ERRORS

