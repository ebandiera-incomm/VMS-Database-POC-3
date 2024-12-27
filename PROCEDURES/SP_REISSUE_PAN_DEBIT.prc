CREATE OR REPLACE PROCEDURE VMSCMS.SP_REISSUE_PAN_DEBIT
  (
    prm_instcode     IN NUMBER,
    prm_old_pancode  IN VARCHAR2,
    prm_old_product  IN VARCHAR2,
    prm_remark       IN VARCHAR2,
    prm_rsncode      IN NUMBER,
    prm_spprt_key    IN VARCHAR2,
    prm_new_prodcode IN VARCHAR2,
    prm_new_cardtype IN VARCHAR2,
    prm_new_dispname IN VARCHAR2,
    prm_lupduser     IN NUMBER,
    prm_reissue_dupflg OUT VARCHAR2,
    prm_newpan OUT VARCHAR2,
    prm_err_msg OUT VARCHAR2 )
AS
  v_dup_rec_count   NUMBER (3);
  v_cap_prod_catg   VARCHAR2 (2);
  v_mbrnumb         VARCHAR2 (3);
  dum               NUMBER (1);
  v_cap_cafgen_flag CHAR (1);
  v_cap_card_stat   CHAR (1);
  software_pin_gen  CHAR (1);
  v_check_bin       NUMBER (1);
  v_old_bin         NUMBER (1);
  v_acct_no CMS_APPL_PAN.cap_acct_no%TYPE;
  v_tran_code VARCHAR2(2);
  v_tran_mode VARCHAR2(1);
  v_tran_type VARCHAR2(1);
  v_delv_chnl VARCHAR2(2);
  v_feetype_code CMS_FEE_MAST.cfm_feetype_code%TYPE;
  v_fee_code CMS_FEE_MAST.cfm_fee_code%TYPE;
  v_fee_amt NUMBER(4);
  v_cust_code CMS_CUST_MAST.ccm_cust_code%TYPE;
  v_acct_id CMS_APPL_PAN.cap_acct_id%TYPE;
  v_errmsg_debit    VARCHAR2(300);
  v_reissue_check   NUMBER;
  v_record_exist    CHAR (1) := 'Y';
  v_caffilegen_flag CHAR (1) := 'N';
  v_issuestatus     VARCHAR2 (2);
  v_pinmailer       VARCHAR2 (1);
  v_cardcarrier     VARCHAR2 (1);
  v_pinoffset       VARCHAR2 (16);
  v_rec_type        VARCHAR2 (1);
  crdstat_cnt       NUMBER(2);
  v_insta_check CMS_INST_PARAM.cip_param_value%type;
  v_cro_oldcard_reissue_stat cms_reissue_oldcardstat.cro_oldcard_reissue_stat%type;
  v_reissue_dup_check cms_inst_param.cip_param_value%type;
  v_reissue_dupflag CHAR(1);                                         --added on 7th oct'10
  v_crd_reissue_dupflag cms_reissue_detail.CRD_REISSUE_DUPFLAG%type; --added on 7th oct'10
  v_crd_process_flag cms_reissue_detail.crd_process_flag%type;
  v_succ_process_flg cms_reissue_detail.crd_process_flag%type;
   v_hash_pan	CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
    v_encr_pan	CMS_APPL_PAN.cap_pan_code_encr%TYPE;
 v_hash_new_pan	CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
        v_encr_new_pan	CMS_APPL_PAN.cap_pan_code_encr%TYPE;
  --this cursor finds the addon cards which were attached to the previousPAN so that they can be pointed towards the PAN being reissued
  CURSOR c1
  IS
    SELECT cap_pan_code,
      cap_mbr_numb
    FROM cms_appl_pan
    WHERE cap_addon_link = v_hash_pan--prm_old_pancode
    AND cap_addon_stat   = 'A'
    AND cap_inst_code    = prm_instcode;
BEGIN --Main begin
  v_errmsg_debit := 'OK';
  prm_reissue_dupflg:=NULL;
  
--SN CREATE HASH PAN 
BEGIN
	v_hash_pan := Gethash(prm_old_pancode);
EXCEPTION
WHEN OTHERS THEN
prm_err_msg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RETURN;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
	v_encr_pan := Fn_Emaps_Main(prm_old_pancode);
EXCEPTION
WHEN OTHERS THEN
prm_err_msg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RETURN;
END;
--EN create encr pan
  
  
  BEGIN
      SELECT cip_param_value
      INTO v_reissue_dup_check
      FROM cms_inst_param
      WHERE cip_inst_code= prm_instcode
      AND cip_param_key  ='DUP_REISSUE_CHECK';
    EXCEPTION
    WHEN OTHERS THEN
      prm_err_msg:='Error while getting details duplicate reissue check '||SUBSTR(sqlerrm,1,200);
      RETURN;
    END;
  
  IF prm_spprt_key='R' and v_reissue_dup_check='Y'  THEN  
    NULL;
--    -----Sn to check Duplicate reissuance pending-----------
--    BEGIN
--      SELECT crd_process_flag,
--        crd_reissue_dupflag
--      INTO v_crd_process_flag,
--        v_crd_reissue_dupflag
--      FROM cms_reissue_detail
--      WHERE crd_inst_code       = prm_instcode
--      AND crd_old_card_no       = prm_old_pancode
--      AND crd_process_flag NOT IN('S','E');
--    EXCEPTION
--    WHEN NO_DATA_FOUND THEN
--        v_crd_process_flag:='S';
--    WHEN OTHERS THEN
--      prm_err_msg:='Error while duplicate reissuance for pancode '||prm_old_pancode||'-'||SUBSTR(sqlerrm,1,200);
--      RETURN;
--    END;
--    prm_reissue_dupflg:=v_crd_reissue_dupflag;
--    -----Sn to check succesfull reissue-----------
--   
--    ----En to check succesfull reissue-----------
--    IF v_crd_process_flag='C' AND v_crd_reissue_dupflag='D' THEN
--      prm_err_msg       :='Card '||prm_old_pancode||' '||' is pending for duplicate reissuance approval.';
--      RETURN;
--    END IF;
--    
--    --sn to check duplicate reissuance--
--       IF  v_crd_process_flag='S' THEN
----            BEGIN
----              SELECT crd_process_flag
----              INTO v_succ_process_flg
----              FROM cms_reissue_detail
----              WHERE rowid=(select max(rowid)
----                           from cms_reissue_detail 
----                           WHERE crd_inst_code = prm_instcode
----                           AND crd_old_card_no = prm_old_pancode
----                           AND crd_process_flag='S')
----      ;
----            EXCEPTION
----            WHEN OTHERS THEN
----              prm_err_msg:='Error while getting successful reissuance count '||SUBSTR(sqlerrm,1,200);
----              RETURN;
----            END;
--            sp_dup_check_reissue( prm_instcode, prm_old_pancode, v_reissue_dupflag, prm_err_msg );
--            IF v_reissue_dupflag='D' THEN
--            prm_err_msg      :='Card '||prm_old_pancode ||' has been sent for Duplicate reissuance';
--            RETURN;
--            END IF;
--       END IF;
--      --En to check duplicate reissuance--
   ELSE
    --Sn check in reissue history table
    BEGIN
      SELECT 1
      INTO v_reissue_check
      FROM CMS_HTLST_REISU
      WHERE chr_inst_code = prm_instcode
      AND chr_pan_code    = v_hash_pan ; -- prm_old_pancode;
      
      prm_err_msg := ' Card ' || v_hash_pan || ' already reissued ';
      RETURN;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
    WHEN TOO_MANY_ROWS THEN
      prm_err_msg := ' More than one record found in hotlist reissue segment';
      RETURN;
    WHEN OTHERS THEN
      prm_err_msg := ' Error while getting reissue history data '|| SUBSTR(sqlerrm,1,150);
      RETURN;
    END;
    --En check in reissue history table
  END IF;
  --Sn check Bin specific detail for old card number
  SP_CHECK_BIN ( prm_instcode , prm_old_product , prm_err_msg );
  IF prm_err_msg <> 'OK' THEN
    RETURN;
  END IF;
  --En check BIN specific detail
  --Sn check Bin specific detail for New card number
  SP_CHECK_BIN ( prm_instcode , prm_new_prodcode , prm_err_msg );
  IF prm_err_msg <> 'OK' THEN
    RETURN;
  END IF;
  --En check Bin specific detail for New card number
  --Sn old pan details
  BEGIN --begin 1 starts
    SELECT cap_prod_catg,
      cap_cafgen_flag,
      cap_card_stat,
      cap_acct_no,
      cap_cust_code
    INTO v_cap_prod_catg,
      v_cap_cafgen_flag,
      v_cap_card_stat,
      v_acct_no,
      v_cust_code
    FROM CMS_APPL_PAN
    WHERE cap_pan_code = v_hash_pan--prm_old_pancode
    AND cap_inst_code  =prm_instcode;
  EXCEPTION --excp of begin 1
  WHEN NO_DATA_FOUND THEN
    prm_err_msg := prm_old_pancode ||' '|| 'Pan not found in master';
    RETURN;
  WHEN OTHERS THEN
    prm_err_msg := 'Error while selecting old PAN details ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --En old Pan details
  --Sn checking card status with respect to instcode--
  --En checking card status with respect to instcode--
  BEGIN
    SELECT cfm_txn_code,
      cfm_txn_mode,
      cfm_delivery_channel,
      CFM_TXN_TYPE
    INTO v_tran_code,
      v_tran_mode,
      v_delv_chnl,
      v_tran_type
    FROM CMS_FUNC_MAST
    WHERE cfm_inst_code = prm_instcode
    AND cfm_func_code   = 'REISSUE';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    prm_err_msg := 'Support function reissue not defined in master ' ;
    RETURN;
  WHEN TOO_MANY_ROWS THEN
    prm_err_msg := 'More than one record found in master for reissue support func ' ;
    RETURN;
  WHEN OTHERS THEN
    prm_err_msg := 'Error while selecting reissue fun detail ' || SUBSTR (SQLERRM, 1, 200);
    RETURN;
  END;
  ----------Sn start insta card check----------
  BEGIN
    SELECT cip_param_value
    INTO v_insta_check
    FROM cms_inst_param
    WHERE cip_param_key='INSTA_CARD_CHECK'
    AND cip_inst_code  =prm_instcode;
    IF v_insta_check   ='Y' THEN
      sp_gen_insta_check( v_acct_no, v_cap_card_stat, prm_err_msg );
      IF prm_err_msg<>'OK' THEN
        RETURN;
      END IF;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    prm_err_msg:='Error while checking the instant card validation. '||SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  ----------En start insta card check----------
  --Sn Fee details for reissue
  Sp_Calc_Fees_Offline_Debit ( prm_instcode , prm_old_pancode, v_tran_code , v_tran_mode , v_delv_chnl , v_tran_type , v_feetype_code, v_fee_code, v_fee_amt, prm_err_msg );
  IF prm_err_msg <> 'OK' THEN
    RETURN;
  END IF;
  --En fee details for reissue
  --Sn insert a record into charge detail
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
        CCD_PAN_CODE_encr
      )
      VALUES
      (
        prm_instcode,
        NULL,
       -- prm_old_pancode
       v_hash_pan,
        NULL,
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
    prm_err_msg := ' Error while inserting into charge dtl ' || SUBSTR
    (
      SQLERRM,1,200
    )
    ;
    RETURN;
  END;
  --En insert a record into charge detail
  --Sn update the old card status
  BEGIN
    SELECT COUNT(*)
    INTO crdstat_cnt
    FROM cms_reissue_validstat
    WHERE crv_inst_code  = prm_instcode
    AND crv_valid_crdstat= v_cap_card_stat
    AND crv_prod_catg    ='D';
  EXCEPTION
  WHEN OTHERS THEN
    prm_err_msg:='Error while validating the card status '||SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  IF crdstat_cnt =0 THEN
    prm_err_msg := 'Not a valid card status. Card cannot be reissued';
    RETURN;
  END IF;
  BEGIN
    SELECT cro_oldcard_reissue_stat
    INTO v_cro_oldcard_reissue_stat
    FROM cms_reissue_oldcardstat
    WHERE cro_inst_code = prm_instcode
    AND cro_oldcard_stat= v_cap_card_stat
    AND cro_spprt_key   = prm_spprt_key;
  EXCEPTION
  WHEN no_data_found THEN
    prm_err_msg:='Default old card status nor defined for institution '|| prm_instcode;
    RETURN;
  WHEN OTHERS THEN
    prm_err_msg:='Error while getting default old card status for institution '|| prm_instcode;
    RETURN;
  END;
  BEGIN --begin 5 starts
    UPDATE cms_appl_pan
    SET cap_card_stat   = v_cro_oldcard_reissue_stat,
      cap_lupd_user     = prm_lupduser
    WHERE cap_inst_code = prm_instcode
    AND cap_pan_code    = v_hash_pan ;  --prm_old_pancode;
    IF SQL%ROWCOUNT    != 1 THEN
      prm_err_msg      := 'Problem in updation of status for pan ' || v_hash_pan ;
      RETURN;
    END IF;
  EXCEPTION --excp of begin 5
  WHEN OTHERS THEN
    prm_err_msg := 'Problem in updation of status for pan ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --Sn find member number
  BEGIN
    SELECT cip_param_value
    INTO v_mbrnumb
    FROM CMS_INST_PARAM
    WHERE cip_inst_code = prm_instcode
    AND cip_param_key   = 'MBR_NUMB';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    prm_err_msg := 'Member number not defined for the institute' ;
    RETURN;
  WHEN OTHERS THEN
    prm_err_msg := 'Error while selecting member number from institute' ;
    RETURN;
  END;
  --En find member number
  --Sn generate CAF for old pan
  BEGIN
    /*SELECT COUNT (*)
    INTO dum
    FROM cms_caf_info
    WHERE cci_inst_code = prm_instcode
    AND cci_pan_code = RPAD (prm_old_pancode, 19, ' ');
    IF dum = 1
    THEN
    --that means there is a row in cafinfo for that pan but file is not generated
    DELETE FROM cms_caf_info
    WHERE cci_inst_code = prm_instcode
    AND cci_pan_code = RPAD (prm_old_pancode, 19, ' ');
    END IF;*/
    --call the procedure to insert into cafinfo
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
      AND cci_pan_code    =v_hash_pan -- DECODE(LENGTH(prm_old_pancode), 16,prm_old_pancode
--        || '   ', 19,prm_old_pancode)--RPAD (prm_old_pancode, 19, ' ')
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
      prm_err_msg := 'Error while selecting caf details '|| SUBSTR (SQLERRM, 1, 300);
      RETURN;
    END;
    --En get caf detail
    --Sn delete record from CAF
    DELETE
    FROM CMS_CAF_INFO
    WHERE cci_inst_code = prm_instcode
    AND cci_pan_code    = v_hash_pan --DECODE(LENGTH(prm_old_pancode), 16,prm_old_pancode
--      || '   ', 19,prm_old_pancode)--RPAD (prm_old_pancode, 19, ' ')
    AND cci_mbr_numb = v_mbrnumb;
    --En delete record from CAF
    
    BEGIN
--      sp_caf_rfrsh (prm_instcode, prm_old_pancode, v_mbrnumb, SYSDATE, 'C', prm_remark, 'REISU', prm_lupduser, v_errmsg_debit );
      sp_caf_rfrsh (prm_instcode, prm_old_pancode, v_mbrnumb, SYSDATE, 'C', prm_remark, 'REISU', prm_lupduser, prm_old_pancode,v_errmsg_debit );
      IF v_errmsg_debit != 'OK' THEN
        prm_err_msg     := 'Error while creating record in CAF -- ' || v_errmsg_debit;
        RETURN;
      END IF;
    END; 
    IF v_rec_type    = 'A' THEN
      v_issuestatus := '00';                -- no pinmailer no embossa.
      v_pinoffset   := RPAD ('Z', 16, 'Z'); -- keep original pin .
    END IF;
    --Sn update caf info
    IF v_record_exist = 'Y' THEN
      BEGIN
        UPDATE CMS_CAF_INFO
        SET cci_seg12_issue_stat = v_issuestatus,
          cci_seg12_pin_mailer   = v_pinmailer,
          cci_seg12_card_carrier = v_cardcarrier,
          cci_pin_ofst           = v_pinoffset -- rahul 10 Mar 05
        WHERE cci_inst_code      = prm_instcode
        AND cci_pan_code         = v_hash_pan --DECODE(LENGTH(prm_old_pancode), 16,prm_old_pancode
--          || '   ', 19,prm_old_pancode)--RPAD (prm_old_pancode, 19, ' ')
        AND cci_mbr_numb = v_mbrnumb;
      EXCEPTION
      WHEN OTHERS THEN
        prm_err_msg := 'Error updating CAF record ' || SUBSTR(sqlerrm,1,200);
        RETURN;
      END;
    END IF;
    --En update caf info
  EXCEPTION --Excp 7
  WHEN OTHERS THEN
    prm_err_msg := 'Error while creating record in CAF ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --En generate CAF for old pan
  --En update the old card status
  --Sn generate new pan code
  BEGIN
    sp_gen_reissuepan_cms ( prm_instcode, prm_old_pancode, prm_new_prodcode, prm_new_cardtype, prm_new_dispname, prm_lupduser, prm_newpan, v_errmsg_debit );
    IF v_errmsg_debit != 'OK' THEN
      prm_err_msg     := 'From reissue pan generation process-- ' || v_errmsg_debit;
      RETURN;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    prm_err_msg := 'From reissue pan generation process-- ' || v_errmsg_debit;
    RETURN;
  END;
  --En generate new pan code
  
  --SN CREATE HASH Pnew AN 
BEGIN
	v_hash_new_pan := Gethash(prm_newpan);
EXCEPTION
WHEN OTHERS THEN
prm_err_msg := 'Error while converting ew pan ' || SUBSTR(SQLERRM,1,200);
RETURN;
END;
--EN CREATE HASH new PAN

--SN create encr new pan
BEGIN
	v_encr_new_pan := Fn_Emaps_Main(prm_newpan);
EXCEPTION
WHEN OTHERS THEN
prm_err_msg := 'Error while converting new pan ' || SUBSTR(SQLERRM,1,200);
RETURN;
END;
--EN create encr new pan

  --Sn generate CAF for new pan
  /*
  BEGIN
    --call the procedure to insert into cafinfo
--    sp_caf_rfrsh (prm_instcode, prm_newpan, v_mbrnumb, SYSDATE, 'A', prm_remark, 'NEW', prm_lupduser, v_errmsg_debit );
        sp_caf_rfrsh (prm_instcode, prm_newpan, '000', SYSDATE, 'A', prm_remark, 'NEW', prm_lupduser, prm_newpan,v_errmsg_debit );
    IF v_errmsg_debit != 'OK' THEN
      prm_err_msg     := 'From caf refresh for new pan-- ' || v_errmsg_debit;
      RETURN;
    END IF;
  EXCEPTION --Excp 6
  WHEN OTHERS THEN
    prm_err_msg := 'Error while creating record in CAF ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;  */
  --En generate CAF for new pan
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
        cps_func_remark,
        cps_spprt_rsncode,
        cps_ins_user,
        cps_lupd_user,
        cps_cmd_mode,
        cps_pan_code_encr
      )
      VALUES
      (
        prm_instcode,
       -- prm_old_pancode
       v_hash_pan,
        v_mbrnumb,
        v_cap_prod_catg,
        'REISU',
        prm_remark,
        prm_rsncode,
        prm_lupduser,
        prm_lupduser,
        0,
        v_encr_pan
      );
  EXCEPTION --excp of begin 3
  WHEN OTHERS THEN
    prm_err_msg := 'Error while creating support detail record ' || SUBSTR
    (
      sqlerrm,1,200
    )
    ;
    RETURN;
  END;
  --En create a record in pan support
  --Sn create a record in hot list reissue
  BEGIN
    INSERT
    INTO CMS_HTLST_REISU
      (
        chr_inst_code,
        chr_pan_code,
        chr_mbr_numb,
        chr_new_pan,
        chr_new_mbr,
        chr_reisu_cause,
        chr_ins_user,
        chr_lupd_user,
        chr_pan_code_encr,
        chr_new_pan_encr
      )
      VALUES
      (
        prm_instcode,
       -- prm_old_pancode
       v_hash_pan,
        v_mbrnumb,
        --prm_newpan
        v_hash_new_pan,
        v_mbrnumb,
        'H',
        prm_lupduser,
        prm_lupduser,
        v_encr_pan,
        v_encr_new_pan
      );
  EXCEPTION --excp of begin 4
  WHEN OTHERS THEN
    prm_err_msg := 'Error while creating hot list reissuue record ' || SUBSTR
    (
      sqlerrm,1,200
    )
    ;
    RETURN;
  END;
  --En create a record in hotlist reissue
EXCEPTION --MAIN EXCEPTION
WHEN OTHERS THEN
  prm_err_msg := 'Error from main ' || SUBSTR
  (
    sqlerrm,1,200
  )
  ;
  RETURN;
END; --MAIN END
/


