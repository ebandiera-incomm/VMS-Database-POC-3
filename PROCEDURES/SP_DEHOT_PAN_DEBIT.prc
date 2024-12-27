CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Dehot_Pan_Debit (
                           prm_instcode   IN       NUMBER,
                           prm_pancode    IN       VARCHAR2,
                           prm_mbrnumb    IN       VARCHAR2,
                           prm_remark     IN       VARCHAR2,
                           prm_rsncode    IN       NUMBER,
                           prm_lupduser   IN       NUMBER,
                           prm_workmode   IN       NUMBER,
                           prm_errmsg     OUT      VARCHAR2
                        )
AS
   dum                    NUMBER;
   v_mbrnumb                VARCHAR2 (3);
   v_cap_prod_catg            CMS_APPL_PAN.cap_prod_catg%type;
   v_record_exist            CHAR (1)     := 'Y';
   v_caffilegen_flag            CHAR (1)     := 'N';
   v_issuestatus            VARCHAR2 (2);
   v_pinmailer                VARCHAR2 (1);
   v_cardcarrier            VARCHAR2 (1);
   v_pinoffset                VARCHAR2 (16);
   v_rec_type                VARCHAR2 (1);
   v_next_bill_dt            CMS_APPL_PAN.cap_next_bill_date%TYPE;
   v_last_run_dt            CMS_PROC_CTRL.cpc_last_rundate%TYPE;
   v_expry_date                CMS_APPL_PAN.cap_expry_date%TYPE;
   v_acctno                CMS_APPL_PAN.cap_acct_no%TYPE;
   v_acct_id                CMS_APPL_PAN.cap_acct_id%TYPE;
   v_cap_cafgen_flag            CMS_APPL_PAN.cap_cafgen_flag%TYPE;
   v_txn_code        VARCHAR2 (2);
    v_txn_type        VARCHAR2 (2);
    v_txn_mode        VARCHAR2 (2);
    v_del_channel     VARCHAR2 (2);
   v_feetype_code            CMS_FEE_MAST.cfm_feetype_code%TYPE;
   v_fee_code                CMS_FEE_MAST.cfm_fee_code%TYPE;
   v_fee_amt                NUMBER(4);
   v_cust_code                CMS_APPL_PAN.cap_cust_code%TYPE;
   v_card_stat                CMS_APPL_PAN.cap_card_stat%type;
   v_errmsg                VARCHAR2(300);
   v_insta_check         CMS_INST_PARAM.cip_param_value%type;
    v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;

BEGIN                                   --<< main begin >>
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

    IF TRIM (prm_mbrnumb) IS NULL  THEN
        prm_errmsg:='Member number can not be null';
    RETURN;
    ELSE
        v_mbrnumb := prm_mbrnumb;
    END IF;
    IF prm_remark IS NULL
    THEN
    prm_errmsg := 'Please enter appropriate remark';
    RETURN;
    END IF;
    --SN CHECK CARD DETAILS
    BEGIN
        SELECT    cap_prod_catg,
            cap_expry_date ,
            cap_cafgen_flag ,
            cap_acct_no ,
            cap_acct_id,
            cap_cust_code,
            cap_card_stat
        INTO    v_cap_prod_catg,
            v_expry_date ,
            v_cap_cafgen_flag ,
            v_acctno ,
            v_acct_id,
            v_cust_code,
            v_card_stat
        FROM    CMS_APPL_PAN
        WHERE    cap_pan_code =v_hash_pan-- prm_pancode
        AND    cap_mbr_numb = v_mbrnumb
    AND cap_inst_code= prm_instcode;
--      IF v_cap_prod_catg <> 'D' THEN
--     prm_errmsg :=  'Not a debit card';
--     RETURN;
--      END IF;
      IF  TRUNC (v_expry_date) < TRUNC (SYSDATE)
      THEN
         prm_errmsg :=  'Debit Card ' || v_hash_pan || ' is already Expired ,cannot be DehotListed ';
     RETURN;
      END IF;

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
                        v_card_stat,
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
      ELSIF v_cap_cafgen_flag = 'N' THEN
     prm_errmsg := 'CAF has to be generated atleast once for this pan';
     RETURN;
      END IF;
   EXCEPTION                                                 --excp of begin 0
      WHEN NO_DATA_FOUND
      THEN
        prm_errmsg :=  'Pan not found in master';
    RETURN;
      WHEN OTHERS THEN
        prm_errmsg :=  'Error while selecting pan details' || substr(sqlerrm,1,200);
    RETURN;
   END;
   --EN CHECK CARD DETAILS
   --
  IF v_card_stat NOT IN ('2','3') THEN
    prm_errmsg :=  'Not a valid card status for dehot list';
    RETURN;
  END IF;
  --Sn check in hotlist_reissue
    BEGIN
        SELECT COUNT (chr_pan_code)
        INTO    dum
        FROM CMS_HTLST_REISU
        WHERE chr_inst_code   = prm_instcode
        AND   chr_pan_code    = v_hash_pan--prm_pancode
        AND   chr_mbr_numb    = v_mbrnumb;
         IF dum != 0
         THEN
            prm_errmsg :=
            'A New PAN already Generated for '
            || prm_pancode
            || ' . Cannot be De-Hotted';
        RETURN;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg := 'Error while selecting card details from hotlist-reissue history master' || substr(sqlerrm,1,150);
        RETURN;
      END;
  --En check in hotlist_reissue
  --Sn calc fees
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
    WHERE cfm_func_code = 'DHTLST'
      AND cfm_inst_code= prm_instcode;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg :='Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
    --RAISE exp_loop_reject_record;
    RETURN;
  END;
  ------------------------------ En get Function Master----------------------------
            BEGIN
            Sp_Calc_Fees_Offline_Debit
                            (
                             prm_instcode    ,
                             prm_pancode,
                             v_txn_code ,
                             v_txn_mode ,
                             v_del_channel ,
                             v_txn_type ,
                             v_feetype_code,
                             v_fee_code,
                             v_fee_amt,
                             v_errmsg
                             );
                IF  v_errmsg <> 'OK' THEN
                prm_errmsg := v_errmsg;
                RETURN;
                END IF;
             EXCEPTION
                WHEN OTHERS THEN
                prm_errmsg := 'Error from fee calculation process' || substr(sqlerrm,1,200);
                RETURN;
             END;
            IF  v_fee_amt > 0 THEN
                --Sn INSERT A RECORD INTO CMS_CHARGE_DTL
                BEGIN
                     INSERT INTO CMS_CHARGE_DTL
                                  (
                                  CCD_INST_CODE     ,
                                  CCD_FEE_TRANS     ,
                                  CCD_PAN_CODE      ,
                                  CCD_MBR_NUMB      ,
                                  CCD_CUST_CODE     ,
                                  CCD_ACCT_ID       ,
                                  CCD_ACCT_NO       ,
                                  CCD_FEE_FREQ      ,
                                  CCD_FEETYPE_CODE  ,
                                  CCD_FEE_CODE      ,
                                  CCD_CALC_AMT      ,
                                  CCD_EXPCALC_DATE  ,
                                  CCD_CALC_DATE     ,
                                  CCD_FILE_DATE     ,
                                  CCD_FILE_NAME     ,
                                  CCD_FILE_STATUS   ,
                                  CCD_INS_USER      ,
                                  CCD_INS_DATE      ,
                                  CCD_LUPD_USER     ,
                                  CCD_LUPD_DATE     ,
                                  CCD_PROCESS_ID    ,
                                  CCD_PLAN_CODE   ,
                  CCD_PAN_CODE_encr
                                 )
                                VALUES
                                (
                                 prm_instcode ,
                                NULL,
                                --prm_pancode
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
                prm_errmsg := ' Error while inserting into charge dtl ' || SUBSTR(SQLERRM,1,200);
                RETURN;
                END;
                --En INSERT A RECORD INTO CMS_CHARGE_DTL
            END IF;
    --En calc fees
    --Sn update card status flag
     BEGIN
         IF prm_workmode = 1
         THEN
            UPDATE CMS_APPL_PAN
               SET cap_card_stat = 1,
               cap_lupd_user = prm_lupduser
             WHERE cap_inst_code = prm_instcode
               AND cap_pan_code = v_hash_pan--prm_pancode
               AND cap_mbr_numb = v_mbrnumb
               AND cap_cafgen_flag = 'Y';
         ELSE
            UPDATE CMS_APPL_PAN
               SET cap_card_stat = 1,
               cap_lupd_user = prm_lupduser
             WHERE cap_inst_code = prm_instcode
               AND cap_pan_code = v_hash_pan--prm_pancode
               AND cap_mbr_numb = v_mbrnumb
               AND cap_card_stat IN ( 2, 3)
               AND cap_cafgen_flag = 'Y';
         --added on 09-05-02 to make sure that the caf was generated atleast once
         END IF;
         IF SQL%ROWCOUNT != 1
         THEN
            prm_errmsg :=
                  'Either the Card was not Hotlisted or the CAF is still Not Generated for this pan '
               || prm_pancode
               || '.';
         RETURN;
         END IF;
      EXCEPTION                                              --Excp of begin 2
         WHEN OTHERS
         THEN
            prm_errmsg := 'Error while updating pan master'|| substr(sqlerrm,1,200) ;
        RETURN;
      END;
    --En update card status flag
    --Sn create a record in pan_spprt
    BEGIN
         INSERT INTO CMS_PAN_SPPRT
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
              VALUES (
              prm_instcode,
            --  prm_pancode
        v_hash_pan,
              v_mbrnumb,
                      v_cap_prod_catg,
              'DEHOT',
              prm_rsncode,
                      prm_remark,
              prm_lupduser,
              prm_lupduser,
                      prm_workmode,
                      v_encr_pan
                     );
      EXCEPTION
         WHEN OTHERS  THEN
            prm_errmsg := ' Error while inserting into charge dtl ' || SUBSTR(SQLERRM,1,200);
        RETURN;
      END;
    --En create a record in pan_spprt
    --Sn find next billing date
    BEGIN
       SELECT    cap_next_bill_date
           INTO        v_next_bill_dt
           FROM        CMS_APPL_PAN
       WHERE    cap_pan_code =v_hash_pan-- prm_pancode
       AND        cap_mbr_numb = v_mbrnumb
     AND cap_inst_code = prm_instcode;
    EXCEPTION
       WHEN OTHERS THEN
       prm_errmsg := ' Error while selecting billing date  ' || SUBSTR(SQLERRM,1,200);
       RETURN;
    END;
    --En find next billing date
    --Sn find fee last rundate
    BEGIN
       SELECT MAX (cpc_last_rundate)
           INTO      v_last_run_dt
           FROM      CMS_PROC_CTRL
           WHERE  cpc_proc_name = 'FEE CALC'
           AND    cpc_inst_code = prm_instcode;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
       v_last_run_dt := null;
       WHEN OTHERS THEN
       prm_errmsg := ' Error while selecting fee calc date  ' || SUBSTR(SQLERRM,1,200);
       RETURN;
    END;
    --En find fee last rundate
    --Sn update next_bill date
    BEGIN
         IF (TRUNC (v_next_bill_dt) <= TRUNC (v_last_run_dt))
         THEN
        UPDATE  CMS_APPL_PAN
        SET    cap_next_bill_date = SYSDATE+ 1
        WHERE   cap_pan_code       = v_hash_pan --prm_pancode
    AND cap_mbr_numb = v_mbrnumb
    AND cap_inst_code= prm_instcode;
            IF SQL%ROWCOUNT = 0
            THEN
               prm_errmsg :=
                     'Error while updating next bill date  in appl_pan -- '
                  || SUBSTR (SQLERRM, 1, 300);
           RETURN;
            END IF;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while updating next bill date -- '|| SUBSTR (SQLERRM, 1, 300);
        RETURN;
      END;
    --En update next billing date
    IF v_cap_prod_catg= 'P' THEN
    null;
    ELSE
    --Sn get caf detail
    BEGIN
        SELECT   cci_rec_typ,
             cci_file_gen,
             cci_seg12_issue_stat,
             cci_seg12_pin_mailer,
             cci_seg12_card_carrier,
             cci_pin_ofst
                INTO     v_rec_type,
             v_caffilegen_flag,
             v_issuestatus,
             v_pinmailer,
             v_cardcarrier,
             v_pinoffset
                FROM    CMS_CAF_INFO
                WHERE    cci_inst_code = prm_instcode
                AND    cci_pan_code = v_hash_pan--DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
                                    --   19,prm_pancode)--RPAD (prm_pancode, 19, ' ')
                 AND    cci_mbr_numb = v_mbrnumb
                 AND    cci_file_gen = 'N'    -- Only when a CAF is not generated
        GROUP BY cci_rec_typ,
             cci_file_gen,
             cci_seg12_issue_stat,
             cci_seg12_pin_mailer,
             cci_seg12_card_carrier,
             cci_pin_ofst;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_record_exist := 'N';
        WHEN OTHERS THEN
        prm_errmsg := 'Error while selecting caf details '|| SUBSTR (SQLERRM, 1, 300);
        RETURN;
        END;
    --En get caf detail
    --Sn delete record from CAF
                  DELETE FROM CMS_CAF_INFO
                  WHERE cci_inst_code = prm_instcode
                    AND cci_pan_code =v_hash_pan-- DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
                                      --19,prm_pancode)--RPAD (prm_pancode, 19, ' ')
                    AND cci_mbr_numb = v_mbrnumb;

    --En delete record from CAF

    --Sn create CAF rfrsh
    BEGIN
     Sp_Caf_Rfrsh (prm_instcode ,
                       prm_pancode,
                       --v_hash_pan,
                       v_mbrnumb,
                       SYSDATE,
                       'C',
                       prm_remark,
                       'DEHOT',
                       prm_lupduser,
                       prm_pancode,
                       prm_errmsg
                      );
    IF prm_errmsg <> 'OK' THEN
        prm_errmsg := 'Error from caf process' || prm_errmsg;
        RETURN;
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
        prm_errmsg := 'Error while creating caf record ' || substr(sqlerrm,1,200);
        RETURN;
    END;
    --En create CAF rfrsh
     IF v_rec_type = 'A'
         THEN
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
          WHERE  cci_inst_code = prm_instcode
          AND    cci_pan_code = v_hash_pan--DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
                         -- 19,prm_pancode)--RPAD (prm_pancode, 19, ' ')
          AND cci_mbr_numb    = v_mbrnumb;
     EXCEPTION
     WHEN OTHERS THEN
        prm_errmsg := 'Error updating CAF record ' || substr(sqlerrm,1,200);
        RETURN;
     END;
     END IF;
    --En update caf info
    END IF;
EXCEPTION                --<< main exception>>
WHEN OTHERS THEN
prm_errmsg := 'Error from main ' || substr(sqlerrm,1,200);
END;                    --<< main end >>
/


show error