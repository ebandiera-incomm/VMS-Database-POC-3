CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Delink_Acct_debit
  (
    prm_instcode IN NUMBER,
    prm_acctid   IN NUMBER,
    prm_pancode  IN VARCHAR2,
    prm_acctno   IN CMS_APPL_PAN.cap_acct_no%type,
    prm_mbrnumb  IN VARCHAR2,
    prm_rsncode  IN NUMBER,
    prm_remark   IN VARCHAR2,
    prm_lupduser IN NUMBER,
    prm_workmode IN NUMBER,
    prm_custcode IN CMS_APPL_PAN.cap_cust_code%type,
    --prm_acctposn   OUT       VARCHAR2,
    prm_errmsg OUT VARCHAR2 )
AS
  dum               NUMBER;
  v_mbrnumb         VARCHAR2 (3);
  v_cap_prod_catg   VARCHAR2 (2);
  v_cap_cafgen_flag CHAR (1);
  v_record_exist    CHAR (1) := 'Y';
  v_caffilegen_flag CHAR (1) := 'N';
  v_issuestatus     VARCHAR2 (2);
  v_pinmailer       VARCHAR2 (1);
  v_cardcarrier     VARCHAR2 (1);
  v_pinoffset       VARCHAR2 (16);
  v_rec_type                VARCHAR2 (1);
  v_cardstat        CHAR (1);
  record_exist      NUMBER;
  v_newacct         VARCHAR2 (20);
  v_accseq          NUMBER (10);
  excp_acct_dlink   EXCEPTION;
  dum1              NUMBER;
  v_acct_no CMS_APPL_PAN.cap_acct_no%TYPE;
  v_txn_code CMS_FUNC_MAST.cfm_txn_code%TYPE;
  v_txn_type CMS_FUNC_MAST.cfm_txn_code%TYPE;
  v_txn_mode CMS_FUNC_MAST.cfm_txn_code%TYPE;
  v_del_channel CMS_FUNC_MAST.cfm_txn_code%TYPE;
  v_feetype_code CMS_FEE_MAST.cfm_feetype_code%TYPE;
  v_fee_code CMS_FEE_MAST.cfm_fee_code%TYPE;
  v_fee_amt NUMBER(4);
  v_cust_code CMS_CUST_MAST.ccm_cust_code%TYPE;
  v_acct_id CMS_APPL_PAN.cap_acct_id%TYPE;
  v_addr_updmode CMS_INST_PARAM .cip_param_value%type;
  v_no_rec NUMBER;
  v_filegen CMS_APPL_PAN.cap_cafgen_flag%type;
  v_insta_check     CMS_INST_PARAM.cip_param_value%type;
 v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;

 
  CURSOR c1
  IS
    SELECT cpa_pan_code,
      cpa_mbr_numb,
      cpa_acct_posn,cpa_pan_code_encr
    FROM CMS_PAN_ACCT
    WHERE cpa_inst_code = prm_instcode
    AND cpa_pan_code    = v_hash_pan --prm_pancode
    AND cpa_mbr_numb    = prm_mbrnumb
    AND cpa_acct_id     = prm_acctid;
BEGIN --<< MAIN BEGIN >>
--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
   return;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
   return;
END;
--EN create encr pan

  ----------Sn start insta card check----------  /*added by amit on 24 Sep'10 for not to allow any supprt func on insta card.*/
   BEGIN 
     select cip_param_value
     into v_insta_check
     from cms_inst_param
     where cip_param_key='INSTA_CARD_CHECK'
     and cip_inst_code=prm_instcode;
   
   IF v_insta_check ='Y' THEN
      sp_gen_insta_check(
                        prm_acctno=>prm_acctno,
                        prm_errmsg=>prm_errmsg
                      );
      IF prm_errmsg <>'OK' THEN
        prm_errmsg:='Can not dellink the account linked to instant card.';
         RETURN;
      END IF;
   END IF;
   
   EXCEPTION WHEN OTHERS THEN
   prm_errmsg:='Error while checking the instant card validation. '||substr(sqlerrm,1,200);
   return;
   END;
  ----------En start insta card check----------  
  --sn transaction detail
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
    WHERE cfm_func_code = 'DLINK1'
    AND cfm_inst_code   = prm_instcode;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Function Master Not Defined for Delink' || SUBSTR (SQLERRM, 1, 200);
    RETURN;
  END;
  --en transaction detail.
  --Sn calculate offline fees
  BEGIN
    Sp_Calc_Fees_Offline_Debit ( prm_instcode , prm_pancode, v_txn_code , v_txn_mode , v_del_channel , v_txn_type , v_feetype_code, v_fee_code, v_fee_amt, prm_errmsg );
    IF prm_errmsg <> 'OK' THEN
      RETURN;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := ' From fee calculation process ' || SUBSTR(SQLERRM,1,200);
    RETURN;
  END;
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
          --prm_pancode
          v_hash_pan,
          prm_mbrnumb,
          prm_custcode,
          v_acct_id,
          prm_acctno,
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
  --En calculate offline fees
  --Sn check address update
  BEGIN
    SELECT cip_param_value
    INTO v_addr_updmode
    FROM CMS_INST_PARAM
    WHERE cip_inst_code = prm_instcode
    AND cip_param_key   = 'ADDUPDATE_MODE';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    prm_errmsg := ' Address update flag is not set in master ' ;
    RETURN;
  WHEN OTHERS THEN
    prm_errmsg := ' Error while selecting address update flag ' || SUBSTR(SQLERRM,1,200);
    RETURN;
  END;
  --En check in address update
  FOR x IN c1
  LOOP    --<< PAN ACCT LOOP >>
    BEGIN --<< LOOP X  BEGIN>>
      --Sn check no of rec in pan_acct
      BEGIN
        SELECT COUNT(*)
        INTO v_no_rec
        FROM CMS_PAN_ACCT
        WHERE cpa_inst_code = prm_instcode
        AND cpa_pan_code    = x.cpa_pan_code
        AND cpa_mbr_numb    = x.cpa_mbr_numb;
        IF v_no_rec         = 0 THEN
          prm_errmsg       := ' Pan detail not found in pan acct master ';
          RETURN;
        END IF;
        IF v_no_rec   = 1 THEN
          prm_errmsg := 'Cannot De-link the only account linked to the PAN ' || x.cpa_pan_code;
          RETURN;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        prm_errmsg := ' Error while selecting pan acct detail ' || SUBSTR(SQLERRM,1,200);
        RETURN;
      END;
      --En check no of rec in pan_acct
      --Sn create a record in pan_acct hist
      BEGIN
        INSERT
        INTO CMS_PAN_ACCT_HIST
          (
            cpa_inst_code,
            cpa_pan_code,
            cpa_mbr_numb,
            cpa_acct_id,
            cpa_acct_posn,
            cpa_ins_user,
            cpa_lupd_user,
            cpa_pan_code_encr
          )
          VALUES
          (
            prm_instcode,
            x.cpa_pan_code,
            x.cpa_mbr_numb,
            prm_acctid,
            x.cpa_acct_posn,
            prm_lupduser,
            prm_lupduser,
             x.cpa_pan_code_encr
          );
      EXCEPTION
      WHEN OTHERS THEN
        prm_errmsg := ' Error while creating rec in  pan acct hist ' || SUBSTR
        (
          SQLERRM,1,200
        )
        ;
        RETURN;
      END;
      --En create a record in pan_acct hist
      --Sn delete record from pan_acct
      BEGIN
        DELETE
        FROM CMS_PAN_ACCT
        WHERE cpa_inst_code = prm_instcode
        AND cpa_pan_code    = x.cpa_pan_code
        AND cpa_mbr_numb    = x.cpa_mbr_numb
        AND cpa_acct_id     = prm_acctid;
        IF sql%rowcount     = 0 THEN
          prm_errmsg       := 'Record not deleted from card acct master';
          RETURN;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        prm_errmsg := ' Error while creating rec in  pan acct hist ' || SUBSTR(SQLERRM,1,200);
        RETURN;
      END;
      --En delete record from pan_acct
      --Sn update acct posn
      BEGIN
        UPDATE CMS_PAN_ACCT
        SET cpa_acct_posn   = cpa_acct_posn - 1
        WHERE cpa_inst_code = prm_instcode
        AND cpa_pan_code    = x.cpa_pan_code
        AND cpa_mbr_numb    = x.cpa_mbr_numb
        AND cpa_acct_posn   > x.cpa_acct_posn;
      EXCEPTION
      WHEN OTHERS THEN
        prm_errmsg := ' Error while updating record in card acct master ' || SUBSTR(SQLERRM,1,200);
        RETURN;
      END;
      --En update acct posn
      --Sn update in card master
      IF x.cpa_acct_posn = 1 THEN
        -- Set primary account in the pan master
        BEGIN
          UPDATE CMS_APPL_PAN
          SET
            (
              cap_acct_id,
              cap_acct_no,
              cap_bill_addr
            )
            =
            (SELECT acct_mast.cam_acct_id,
              acct_mast.cam_acct_no,
              DECODE(v_addr_updmode,'ACCOUNT',acct_mast.cam_bill_addr,appl_pan.cap_bill_addr)
            FROM CMS_APPL_PAN appl_pan,
              CMS_PAN_ACCT pan_acct,
              CMS_ACCT_MAST acct_mast
            WHERE appl_pan.cap_inst_code = pan_acct.cpa_inst_code
            AND appl_pan.cap_pan_code    = pan_acct.cpa_pan_code
            AND appl_pan.cap_mbr_numb    = pan_acct.cpa_mbr_numb
            AND pan_acct.cpa_inst_code   = acct_mast.cam_inst_code
            AND pan_acct.cpa_acct_id     = acct_mast.cam_acct_id
            AND appl_pan.cap_inst_code   = 1
            AND appl_pan.cap_pan_code    = x.cpa_pan_code
            AND appl_pan.cap_mbr_numb    = x.cpa_mbr_numb
            AND pan_acct.cpa_acct_posn   = 1
            )
          WHERE cap_pan_code = x.cpa_pan_code
          AND cap_mbr_numb   = x.cpa_mbr_numb;
        EXCEPTION
        WHEN OTHERS THEN
          prm_errmsg := ' Error while updating record in card master ' || SUBSTR(SQLERRM,1,200);
          RETURN;
        END;
        --Sn update primary acct stat
        BEGIN
          UPDATE CMS_ACCT_MAST
          SET cam_stat_code   = 8
          WHERE cam_inst_code = prm_instcode
          AND cam_acct_id     =
            (SELECT cpa_acct_id
            FROM CMS_PAN_ACCT
            WHERE cpa_pan_code = x.cpa_pan_code
            AND cpa_mbr_numb   = x.cpa_mbr_numb
            AND cpa_acct_posn  = 1
            );
        EXCEPTION
        WHEN OTHERS THEN
          prm_errmsg := ' Error while updating record in Acct master ' || SUBSTR(SQLERRM,1,200);
          RETURN;
        END;
        --En update primary acct stat
      END IF;
      --En update in card master
      --Sn create record in pan_spprt
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
            'D',
            'DLINK2',
            prm_rsncode,
            prm_remark,
            prm_lupduser,
            prm_lupduser,
            prm_workmode,
            v_encr_pan
          );
      EXCEPTION
      WHEN OTHERS THEN
        prm_errmsg := 'Error while inserting in pan support master - ' || SUBSTR
        (
          SQLERRM,1,200
        )
        ;
        RETURN;
      END;
      --En create record in pan_spprt
      BEGIN
        SELECT cci_file_gen,
          cci_seg12_issue_stat,
          cci_seg12_pin_mailer,
          cci_seg12_card_carrier,
          cci_pin_ofst,
          cci_crd_stat,
          cci_file_gen,
          cci_rec_typ
        INTO v_caffilegen_flag,
          v_issuestatus,
          v_pinmailer,
          v_cardcarrier,
          v_pinoffset,
          v_cardstat,
          v_filegen,
          v_rec_type
        FROM CMS_CAF_INFO
        WHERE cci_inst_code = prm_instcode
        AND cci_pan_code    =v_hash_pan -- DECODE(LENGTH(prm_pancode), 16,prm_pancode
        --  || '   ', 19,prm_pancode)
        AND cci_mbr_numb = prm_mbrnumb;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_record_exist := 'N';
      WHEN OTHERS THEN
        prm_errmsg := 'Error while selecting data from CAF - ' || SUBSTR(SQLERRM,1,200);
        RETURN;
      END;
      IF v_filegen    = 'Y' THEN
        record_exist := '1';
      END IF;
      BEGIN
        DELETE
        FROM CMS_CAF_INFO
        WHERE cci_inst_code = prm_instcode
        AND cci_pan_code    = v_hash_pan --DECODE(LENGTH(prm_pancode), 16,prm_pancode
         -- || '   ', 19,prm_pancode)--RPAD (prm_pancode, 19, ' ')
        AND cci_mbr_numb = prm_mbrnumb;
      EXCEPTION
      WHEN OTHERS THEN
        prm_errmsg := 'Error while selecting data from CAF - ' || SUBSTR(SQLERRM,1,200);
        RETURN;
      END;
      BEGIN
--        Sp_Caf_Rfrsh (prm_instcode, prm_pancode, prm_mbrnumb, SYSDATE, 'C', NULL, 'DLINK', prm_lupduser, prm_errmsg );
          Sp_Caf_Rfrsh (prm_instcode, prm_pancode, prm_mbrnumb, SYSDATE, 'C', NULL, 'DLINK', prm_lupduser,prm_pancode, prm_errmsg );
        IF prm_errmsg <> 'OK' THEN
          RETURN;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        prm_errmsg := 'Error from cafgeneration process' || SUBSTR(SQLERRM,1,200);
        RETURN;
      END;
      /*IF record_exist = 1 THEN
        BEGIN
          UPDATE CMS_CAF_INFO
          SET cci_crd_stat    = v_cardstat
          WHERE cci_inst_code = prm_instcode
          AND cci_pan_code    = DECODE(LENGTH(prm_pancode), 16,prm_pancode
            || '   ', 19,prm_pancode)--RPAD (pancode, 19, ' ')
          AND cci_mbr_numb = prm_mbrnumb;
          IF sql%rowcount  = 0 THEN
            prm_errmsg    := 'Record not updated successfully in CAF ';
            RETURN;
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          prm_errmsg := 'Error while updating caf' || SUBSTR(SQLERRM,1,200);
          RETURN;
        END;
      END IF;*/
      IF v_rec_type = 'A'
         THEN
            v_issuestatus := '00';                -- no pinmailer no embossa.
            v_pinoffset := RPAD ('Z', 16, 'Z');        -- keep original pin .
      END IF;
      IF /*prm_workmode = 1 AND*/ v_record_exist = 'Y' THEN
        BEGIN
          UPDATE CMS_CAF_INFO
          SET cci_file_gen         = v_caffilegen_flag,
            cci_seg12_issue_stat   = v_issuestatus,
            cci_seg12_pin_mailer   = v_pinmailer,
            cci_seg12_card_carrier = v_cardcarrier,
            cci_pin_ofst           = v_pinoffset
          WHERE cci_inst_code      = prm_instcode
          AND cci_pan_code         = v_hash_pan --DECODE(LENGTH(prm_pancode), 16,prm_pancode
        --    || '   ', 19,prm_pancode)--RPAD (pancode, 19, ' ')
          AND cci_mbr_numb = prm_mbrnumb;
          IF sql%rowcount  = 0 THEN
            prm_errmsg    := 'Record not updated successfully in CAF for workmode 1 ';
            RETURN;
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          prm_errmsg := 'Error while updating caf for workmode 1' || SUBSTR(SQLERRM,1,200);
          RETURN;
        END;
      END IF;
      /*IF prm_workmode = 1 AND v_record_exist = 'N' THEN
        BEGIN
          UPDATE CMS_CAF_INFO
          SET cci_file_gen    = 'Y'
          WHERE cci_inst_code = prm_instcode
          AND cci_pan_code    = DECODE(LENGTH(prm_pancode), 16,prm_pancode
            || '   ', 19,prm_pancode)--RPAD (pancode, 19, ' ')
          AND cci_mbr_numb = prm_mbrnumb;
          IF sql%rowcount  = 0 THEN
            prm_errmsg    := 'Record not updated successfully for file generation in CAF for workmode 1 ';
            RETURN;
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          prm_errmsg := 'Error while updating caf for workmode 1' || SUBSTR(SQLERRM,1,200);
          RETURN;
        END;
      END IF;*/
      --En create a record in CAF
    EXCEPTION --<< LOOP X EXCEPTION >>
    WHEN OTHERS THEN
      prm_errmsg := 'Error while processing record ' || SUBSTR(SQLERRM,1,200);
      RETURN;
    END; --<< LOOP X END >>
  END LOOP;
EXCEPTION --<< MAIN EXCEPTION >>
WHEN OTHERS THEN
  prm_errmsg := 'Main Exception -- ' || SUBSTR(SQLERRM,1,200);
END; --<< MAIN END>>
/


show error