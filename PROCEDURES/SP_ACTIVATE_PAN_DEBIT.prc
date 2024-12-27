CREATE OR REPLACE PROCEDURE VMSCMS.Sp_activate_Pan_Debit (
   instcode   IN       NUMBER,
   pancode    IN       VARCHAR2,
   mbrnumb    IN       VARCHAR2,
   remark     IN       VARCHAR2,
   rsncode    IN       NUMBER,
   lupduser   IN       NUMBER,
   workmode   IN       NUMBER,
   errmsg     OUT      VARCHAR2
)
AS
   dum                 NUMBER;
   v_mbrnumb           VARCHAR2 (3);
   v_cap_prod_catg     VARCHAR2 (2);
   v_record_exist      CHAR (1)                               := 'Y';
   v_caffilegen_flag   CHAR (1)                               := 'N';
   v_issuestatus       VARCHAR2 (2);
   v_pinmailer         VARCHAR2 (1);
   v_cardcarrier       VARCHAR2 (1);
   v_pinoffset         VARCHAR2 (16);
   v_rec_type          VARCHAR2 (1);
   v_next_bill_dt      CMS_APPL_PAN.cap_next_bill_date%TYPE;
   v_last_run_dt       CMS_PROC_CTRL.cpc_last_rundate%TYPE;
   v_expry_date        CMS_APPL_PAN.cap_expry_date%TYPE;
   v_acctno               CMS_APPL_PAN.cap_acct_no%TYPE;
   v_acct_id           CMS_APPL_PAN.cap_acct_id%TYPE;
   v_cap_cafgen_flag   CMS_APPL_PAN.cap_cafgen_flag%TYPE;
   v_tran_code           VARCHAR2(2);
   v_tran_mode           VARCHAR2(1);
   v_tran_type           VARCHAR2(1);
   v_delv_chnl           VARCHAR2(2);
   v_feetype_code       CMS_FEE_MAST.cfm_feetype_code%TYPE;
   v_fee_code           CMS_FEE_MAST.cfm_fee_code%TYPE;
   v_fee_amt           NUMBER(4);
   v_cust_code           CMS_APPL_PAN.cap_cust_code%TYPE;
    v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;

 
BEGIN                                                      --Main begin starts
   IF TRIM (mbrnumb) IS NULL
   THEN
      v_mbrnumb := '000';
   ELSE
      v_mbrnumb := mbrnumb;
   END IF;

   errmsg := 'OK';
   DBMS_OUTPUT.put_line (pancode);


--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(pancode);
EXCEPTION
WHEN OTHERS THEN
errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
    RETURN;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(pancode);
EXCEPTION
WHEN OTHERS THEN
 errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
    RETURN;
END;
--EN create encr pan


   IF remark IS NULL
   THEN
      errmsg := 'Please enter appropriate remark';
   END IF;

   BEGIN                                                      --begin 0 starts
      SELECT cap_prod_catg, cap_expry_date ,cap_cafgen_flag ,cap_acct_no ,cap_acct_id,cap_cust_code
        INTO v_cap_prod_catg, v_expry_date ,v_cap_cafgen_flag ,v_acctno ,v_acct_id,v_cust_code
        FROM CMS_APPL_PAN
       WHERE cap_pan_code = v_hash_pan--pancode 
       AND cap_mbr_numb = v_mbrnumb;

      IF v_cap_prod_catg = 'D' AND TRUNC (v_expry_date) < TRUNC (SYSDATE)
      THEN
         errmsg :=
               'Debit Card '
            || pancode
            || ' is already Expired ,cannot be Activate ';
      END IF;

   EXCEPTION                                                 --excp of begin 0
      WHEN NO_DATA_FOUND
      THEN
         errmsg := 'No such PAN found.';
      WHEN OTHERS
      THEN
         errmsg := 'Excp 0 -- ' || SQLERRM;
   END;                                                         --begin 0 ends
   
   --check whether there is any pan reissued for the  hotlisted card. If so then don't allow to activate the card
   IF errmsg = 'OK' AND v_cap_cafgen_flag = 'N'
   THEN                                                            --cafgen if
      errmsg := 'CAF has to be generated atleast once for this pan';
      RETURN;
   END IF;
   
   IF errmsg = 'OK'
   THEN
      BEGIN                                                         --Begin 1
         SELECT COUNT (chr_pan_code)
           INTO dum
           FROM CMS_HTLST_REISU
          WHERE chr_inst_code = instcode
            AND chr_pan_code = v_hash_pan--pancode
            AND chr_mbr_numb = v_mbrnumb;

         IF dum != 0
         THEN
            errmsg :=
                  'A New PAN already Generated for '
               || pancode
               || ' . Cannot be Activated';
         END IF;
      EXCEPTION                                              --Excp of begin 1
         WHEN OTHERS
         THEN
            errmsg := 'Excp 1 -- ' || SQLERRM;
      END;                                                    --End of begin 1
      
   END IF;
   
   
    --Sn Check fees if any attached
      IF errmsg  = 'OK' THEN
      
           v_tran_code :=        'SD';
         v_tran_mode :=        '0';   
            v_tran_type :=        '0';   
            v_delv_chnl :=     '05';
         
         
         
         Sp_Calc_Fees_Offline_Debit
                            (
                             instcode    ,
                             pancode,
                             v_tran_code ,
                             v_tran_mode ,
                             v_delv_chnl ,
                             v_tran_type ,
                             v_feetype_code,
                             v_fee_code,
                             v_fee_amt,
                             errmsg
                             );
                IF  errmsg  <> 'OK' THEN
                RETURN;
                END IF; 
                
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
                                instcode,
                                NULL,
                              --  pancode
                              v_hash_pan,
                                mbrnumb,
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
                                lupduser,
                                SYSDATE,
                                lupduser,
                                SYSDATE,
                                NULL,
                                NULL,
                                v_encr_pan
                                );
                EXCEPTION
                WHEN OTHERS THEN
                
                errmsg := ' Error while inserting into charge dtl ' || SUBSTR(SQLERRM,1,200);
                RETURN;
                END;
                
                --En INSERT A RECORD INTO CMS_CHARGE_DTL
            END IF;
    
    END IF;

   IF errmsg = 'OK'
   THEN
      BEGIN                                                         --Begin 2

         IF workmode = 1
         THEN
            UPDATE CMS_APPL_PAN
               SET cap_card_stat = 1,
                   cap_lupd_user = lupduser
             WHERE cap_inst_code = instcode
               AND cap_pan_code = v_hash_pan--pancode
               AND cap_mbr_numb = v_mbrnumb
               AND cap_cafgen_flag = 'Y';
         ELSE
            UPDATE CMS_APPL_PAN
               SET cap_card_stat = 1,
                   cap_lupd_user = lupduser
             WHERE cap_inst_code = instcode
               AND cap_pan_code = v_hash_pan--pancode
               AND cap_mbr_numb = v_mbrnumb
               AND cap_card_stat IN (0,4)
               AND cap_cafgen_flag = 'Y';
         --added on 09-05-02 to make sure that the caf was generated atleast once
         END IF;

         IF SQL%ROWCOUNT != 1
         THEN
            errmsg :=
                  'Either the Card was not Activated or the CAF is still Not Generated for this pan '
               || pancode
               || '.';
         END IF;
      EXCEPTION                                              --Excp of begin 2
         WHEN OTHERS
         THEN
            errmsg := 'Excp 2 -- ' || SQLERRM;
      END;                                                    --End of begin 2
   END IF;

   IF errmsg = 'OK'
   THEN
      BEGIN                                                         --Begin 3
       
         INSERT INTO CMS_PAN_SPPRT
                     (cps_inst_code, cps_pan_code, cps_mbr_numb,
                      cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                      cps_func_remark, cps_ins_user, cps_lupd_user,
                      cps_cmd_mode,cps_pan_code_encr
                     )
              VALUES (instcode, --pancode
              v_hash_pan, v_mbrnumb,
                      v_cap_prod_catg, 'ACTVTCARD', rsncode,
                      remark, lupduser, lupduser,
                      workmode,v_encr_pan
                     );

      EXCEPTION                                              --Excp of begin 3
         WHEN OTHERS
         THEN
            errmsg := 'Excp 3 -- ' || SQLERRM;
      END;                                                    --End of begin 3
   END IF;

   --Caf Refresh
   ---
   
   IF errmsg = 'OK'
   THEN
      BEGIN
         SELECT cap_next_bill_date
           INTO v_next_bill_dt
           FROM CMS_APPL_PAN
          WHERE cap_pan_code = v_hash_pan--pancode
           AND cap_mbr_numb = v_mbrnumb;

         SELECT MAX (cpc_last_rundate)
           INTO v_last_run_dt
           FROM CMS_PROC_CTRL
          WHERE cpc_proc_name = 'FEE CALC';

         IF (TRUNC (v_next_bill_dt) <= TRUNC (v_last_run_dt))
         THEN
            UPDATE CMS_APPL_PAN
               SET cap_next_bill_date =
                      SYSDATE
                      + 1       
             WHERE cap_pan_code = v_hash_pan--pancode
              AND cap_mbr_numb = v_mbrnumb;

            IF SQL%ROWCOUNT = 0
            THEN
               errmsg :=
                     'Error while updating next bill date  in appl_pan -- '
                  || SUBSTR (SQLERRM, 1, 300);
            END IF;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            errmsg :=
                  'Error while updating next bill date -- '
               || SUBSTR (SQLERRM, 1, 300);
      END;
   END IF;


      ---
   IF errmsg = 'OK'
   THEN
      BEGIN                                                         --Begin 4
       
         BEGIN
            SELECT   cci_rec_typ, cci_file_gen, cci_seg12_issue_stat,
                     cci_seg12_pin_mailer, cci_seg12_card_carrier,
                     cci_pin_ofst
                INTO v_rec_type, v_caffilegen_flag, v_issuestatus,
                     v_pinmailer, v_cardcarrier,
                     v_pinoffset
                FROM CMS_CAF_INFO
               WHERE cci_inst_code = instcode
                 AND cci_pan_code =v_hash_pan-- DECODE(LENGTH(pancode), 16,pancode || '   ',
                                  --    19,pancode)--RPAD (pancode, 19, ' ')
                 AND cci_mbr_numb = v_mbrnumb
                 AND cci_file_gen = 'N'    -- Only when a CAF is not generated
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
         END;


         DELETE FROM CMS_CAF_INFO
               WHERE cci_inst_code = instcode
                 AND cci_pan_code = v_hash_pan--DECODE(LENGTH(pancode), 16,pancode || '   ',
                                     -- 19,pancode)--RPAD (pancode, 19, ' ')
                 AND cci_mbr_numb = v_mbrnumb;

         --call the procedure to insert into cafinfo
         Sp_Caf_Rfrsh (instcode,
                      -- pancode
                      v_hash_pan,
                       v_mbrnumb,
                       SYSDATE,
                       'C',
                       remark,
                       'ACTVTCARD',
                       lupduser,
                       v_encr_pan,
                       errmsg
                      );

         IF v_rec_type = 'A'
         THEN
            v_issuestatus := '00';                -- no pinmailer no embossa.
            v_pinoffset := RPAD ('Z', 16, 'Z');        -- keep original pin .
         END IF;

-- ##########################
         IF workmode = 1 AND v_record_exist = 'Y'
         THEN
            UPDATE CMS_CAF_INFO
            SET cci_seg12_issue_stat = v_issuestatus,
                cci_seg12_pin_mailer = v_pinmailer,
                cci_seg12_card_carrier = v_cardcarrier,
                cci_pin_ofst = v_pinoffset               
             WHERE cci_inst_code = 1
               AND cci_pan_code =v_hash_pan-- DECODE(LENGTH(pancode), 16,pancode || '   ',
                                      --19,pancode)--RPAD (pancode, 19, ' ')
               AND cci_mbr_numb = '000';
         END IF;


         IF errmsg != 'OK'
         THEN
            errmsg := 'From caf refresh -- ' || errmsg;
         END IF;
      EXCEPTION                                                       --Excp 4
         WHEN OTHERS
         THEN
            errmsg := 'Excp 4 -- ' || SQLERRM;
      END;                                                    --End of begin 4
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      errmsg := 'Main Exception -- ' || SQLERRM;
END;
/


show error