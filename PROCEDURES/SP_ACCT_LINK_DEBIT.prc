CREATE OR REPLACE PROCEDURE VMSCMS.sp_acct_link_debit
(
p_instcode        IN VARCHAR2,
p_rsncode        IN NUMBER,
p_lupduser        IN VARCHAR2,
p_pan_code        IN VARCHAR2,
p_new_acct_no        IN VARCHAR2,
p_remarks        IN VARCHAR2,
p_mbrnumb        IN VARCHAR2,
p_workmode        IN NUMBER,
p_errmsg        OUT  VARCHAR2
)
AS

--v_mbrnumb        VARCHAR2(3);
v_remark        CMS_PAN_SPPRT.cps_func_remark%TYPE;
v_cap_cafgen_flag    CMS_APPL_PAN.cap_cafgen_flag%TYPE;
v_cam_acct_id        CMS_ACCT_MAST.cam_acct_id%TYPE;
v_cap_cust_code        CMS_APPL_PAN.CAP_CUST_CODE%TYPE;
v_cca_rel_stat        CMS_CUST_ACCT.CCA_REL_STAT%TYPE ;
v_cap_acct_no        CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
v_cap_disp_name        CMS_APPL_PAN.CAP_DISP_NAME%TYPE;
v_cap_prod_catg        CMS_APPL_PAN.cap_prod_catg%TYPE;
v_cap_addon_stat    CMS_APPL_PAN.cap_addon_stat%TYPE;
v_caffilegen_flag    CMS_CAF_INFO.cci_file_gen%TYPE;
v_issuestatus        CMS_CAF_INFO.cci_seg12_issue_stat%TYPE;
v_pinmailer        CMS_CAF_INFO.cci_seg12_pin_mailer%TYPE;
v_cardcarrier        CMS_CAF_INFO.cci_seg12_card_carrier%TYPE;
v_pinoffset        CMS_CAF_INFO.cci_pin_ofst%TYPE;
v_cardstat        CMS_CAF_INFO.cci_crd_stat%TYPE;
v_new_acctposn        NUMBER(3)    ;
V_CUSTCODE        CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
v_tran_code           VARCHAR2(2);
v_tran_mode           VARCHAR2(1);
v_tran_type           VARCHAR2(1);
v_delv_chnl           VARCHAR2(2);
v_feetype_code        CMS_FEE_MAST.cfm_feetype_code%TYPE;
v_fee_code        CMS_FEE_MAST.cfm_fee_code%TYPE;
v_fee_amt        NUMBER(4);
v_savepoint        NUMBER    DEFAULT 0;
v_cap_card_stat cms_appl_pan.cap_card_stat%type;
v_insta_check     CMS_INST_PARAM.cip_param_value%type;

v_dum            NUMBER;
v_holdposn        NUMBER(2);
v_acct_posn        varchar2(5);
v_record_exist        VARCHAR2(1)    ;
 v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;


BEGIN --BEGIN 1.1

--v_mbrnumb    :=    p_mbrnumb    ;
v_remark    :=    p_remarks    ;

p_errmsg := 'OK';

--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(p_pan_code);
EXCEPTION
WHEN OTHERS THEN
p_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RETURN;
END;
--EN CREATE HASH PAN


--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(p_pan_code);
EXCEPTION
WHEN OTHERS THEN
p_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RETURN;
END;
--EN create encr pan


SAVEPOINT v_savepoint ;



    --BEGIN  --begin 1.2


        BEGIN -- 1.3

               SELECT  cap_cafgen_flag, cap_cust_code , cap_acct_no, cap_disp_name, cap_prod_catg,
                cap_addon_stat, cap_card_stat
               INTO v_cap_cafgen_flag, v_cap_cust_code, v_cap_acct_no, v_cap_disp_name, v_cap_prod_catg,
                v_cap_addon_stat,v_cap_card_stat
               FROM CMS_APPL_PAN
               WHERE CAP_PAN_CODE = v_hash_pan --p_pan_code
               AND   CAP_MBR_NUMB = p_mbrnumb
               AND cap_card_stat = '1'
               AND cap_inst_code = p_instcode;

        EXCEPTION    --excp of begin 1.3

               WHEN NO_DATA_FOUND THEN

              p_errmsg := 'NO SUCH ACTIVE PAN FOUND';

              RETURN    ;

               WHEN OTHERS THEN

              p_errmsg := 'WHILE GETTING DATA FROM PAN MASTER : '|| SUBSTR(SQLERRM, 1, 100) ;

              RETURN    ;

        END; --1.3

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


        IF v_cap_cafgen_flag = 'N' THEN

            P_ERRMSG := 'CAF HAS TO BE GENERATED ATLEAST ONCE FOR THIS PAN';

            RETURN ;

        END IF;

        IF v_cap_addon_stat = 'A' THEN

            --ROLLBACK TO v_savepoint ;

            P_ERRMSG :=    'CANNOT LINK ACCOUNTS TO ADDONS. IT WILL BE DONE AUTOMATICALLY';

            RETURN ;

        END IF;

        /* -- SN: TO GET ACT ID BANK SPECIFIC

        BEGIN -- 1.4

              SELECT  cam_acct_id
              INTO v_cam_acct_id
              FROM CMS_ACCT_MAST
              WHERE CAM_INST_CODE = p_instcode
              AND     CAM_ACCT_NO = p_new_acct_no
              ;


        EXCEPTION

              WHEN NO_DATA_FOUND THEN

                 p_errmsg := 'NO SUCH ACCOUNT FOUND';

                 RETURN    ;

              WHEN OTHERS THEN

                 p_errmsg := 'WHILE SELECTING ACCOUNT FROM ACCOUNT MASTER '|| SUBSTR(SQLERRM, 1, 100) ;

                 RETURN    ;

        END; -- 1.4

         -- EN: TO GET ACT ID BANK SPECIFIC
         */

         ----------------------------
         -- SN: TO GET THE ACCOUNT ID
         ----------------------------

         BEGIN

            SP_BANK_GET_ACTID (
                    p_instcode,
                    p_pan_code,
                    p_new_acct_no,
                    v_cap_acct_no,
                    p_lupduser,
                    v_cam_acct_id,
                    P_ERRMSG ) ;

            IF P_ERRMSG <> 'OK' THEN

                --ROLLBACK TO v_savepoint ;

                P_ERRMSG := 'ERROR WHILE GETTING ACCOUNT ID ' || P_ERRMSG ;

                RETURN ;

            END IF;



         END;
         -----------------------------
         -- EN: TO GET THE ACCOUNT ID
         ----------------------------

        BEGIN -- 1.5

              SELECT CCA_REL_STAT
              INTO v_cca_rel_stat
              FROM CMS_CUST_ACCT
              WHERE cca_cust_code = v_cap_cust_code
              AND cca_acct_id = v_cam_acct_id
              AND cca_inst_code = p_instcode;

              IF v_cca_rel_stat = 'N' THEN

                --ROLLBACK TO v_savepoint ;

                 p_errmsg := 'CUST_ACCT RELATION SHIP IS CLOSED' ;

                 RETURN ;

              END IF  ;


                EXCEPTION    --excp of begin 1.5

              WHEN NO_DATA_FOUND THEN

                    UPDATE CMS_ACCT_MAST
                    SET CAM_HOLD_COUNT = CAM_HOLD_COUNT + 1
                    WHERE CAM_INST_CODE = p_instcode AND
                    CAM_ACCT_ID = v_cam_acct_id
                    ;

                        Sp_Create_Holder(
                        p_instcode,
                        v_cap_cust_code,
                        v_cam_acct_id,
                        NULL,
                        1,
                        v_holdposn,
                        p_errmsg
                        );


                     IF p_errmsg <> 'OK' THEN

                    p_errmsg := 'ERROR FROM PROCESS OF CREATING ACCOUNT HOLDER : '|| p_errmsg;

                    --ROLLBACK TO v_savepoint ;

                    RETURN    ;

                     END IF;

            WHEN OTHERS THEN

                p_errmsg := 'ERROR WHILE GETTING RELATION STATUS : '|| SUBSTR(SQLERRM, 1, 100) ;

                RETURN    ;

        END; -- 1.5



        -------------------------------------------
        -- SN 1.6 : TO UPDATE PAN ACCOUNT MASTER
        --------------------------------------------

        BEGIN

            SELECT  COUNT(1)
            INTO    v_dum
            FROM    CMS_PAN_ACCT
            WHERE    cpa_inst_code    = p_instcode
            AND    cpa_pan_code    = v_hash_pan--p_pan_code
            AND    cpa_mbr_numb    = p_mbrnumb
            AND     cpa_acct_id     = v_cam_acct_id ;

        EXCEPTION

        WHEN OTHERS THEN

            p_errmsg := 'ERROR WHILE CHECKING ACT EXISTANCE IN PAN ACT MASTER '|| SUBSTR(SQLERRM , 1,100);

            RETURN;

        END;

        IF  v_dum = 1  THEN

            p_errmsg := 'CARD ALREADY LINKED TO ACCT GIVEN IN FILE';

            RETURN ;

        ELSIF v_dum = 0 THEN
        BEGIN                                                --begin 2

              SELECT   MAX (cpa_acct_posn) + 1, cpa_cust_code
              INTO v_new_acctposn, v_custcode
              FROM CMS_PAN_ACCT
              WHERE cpa_inst_code    = p_instcode
                AND cpa_pan_code    =v_hash_pan-- p_pan_code
                AND cpa_mbr_numb    = p_mbrnumb
              GROUP BY cpa_cust_code
              ;


              INSERT INTO CMS_PAN_ACCT
                      (cpa_inst_code, cpa_cust_code, cpa_acct_id,
                       cpa_acct_posn, cpa_pan_code, cpa_mbr_numb,
                       cpa_ins_user, cpa_lupd_user,cpa_pan_code_encr
                      )
                   VALUES (p_instcode, v_custcode, v_cam_acct_id,
                       v_new_acctposn,-- p_pan_code
               v_hash_pan, p_mbrnumb,
                       p_lupduser, p_lupduser,v_encr_pan
                      );
        EXCEPTION

              WHEN OTHERS THEN

             -- ROLLBACK TO v_savepoint ;

              p_errmsg := 'ERROR WHILE INSERTING IN PAN ACCT MASTER '
                || SUBSTR (SQLERRM, 1, 100);

              RETURN ;
        END;
        END IF;
        -------------------------------------------
        -- EN 1.6 : TO UPDATE PAN ACCOUNT MASTER
        --------------------------------------------

        ------Sn account link
        
        BEGIN
               SELECT 
                   cfm_txn_code,
                   cfm_txn_mode,
                   cfm_delivery_channel,
                   cfm_txn_type
            INTO   v_tran_code,
                   v_tran_mode,
                   v_delv_chnl,
                   v_tran_type
            FROM   CMS_FUNC_MAST
            WHERE  cfm_inst_code = p_instcode
            AND       cfm_func_code = 'LINK';
         EXCEPTION
               WHEN NO_DATA_FOUND THEN
            p_errmsg :=
                'Support function acct close not defined in master ' ;
             RETURN ;
             
            WHEN TOO_MANY_ROWS THEN
            p_errmsg :=
                'More than one record found in master for acct close support func ' ;
             RETURN ;
             
            WHEN OTHERS
                   THEN
             p_errmsg :=
                'Error while selecting acct close function detail ' || SUBSTR (SQLERRM, 1, 200);
             RETURN ;
   END;
     --En get tran code
        -------------------------------------------
        -- SN 1.7 : TO CALCULATE FEE FOR DEBIT CARD
        --------------------------------------------
        BEGIN

--          v_tran_code :=        'AL'    ;
--          v_tran_mode :=        '0'    ;
--          v_tran_type :=        '0'    ;
--          v_delv_chnl :=        '05'    ;



            Sp_Calc_Fees_Offline_Debit
                    (
                     p_instcode    ,
                     p_pan_code,
                     v_tran_code ,
                     v_tran_mode ,
                     v_delv_chnl ,
                     v_tran_type ,
                     v_feetype_code,
                     v_fee_code,
                     v_fee_amt,
                     p_errmsg
                     );
            IF  p_errmsg  <> 'OK' THEN

                --ROLLBACK TO v_savepoint ;

                p_errmsg := 'ERROR FROM PROCESS OF CALCULATING FEE : '|| p_errmsg;

                RETURN    ;

            END IF;

            IF  v_fee_amt > 0 THEN

            ------------------------------------------
            --SN INSERT A RECORD INTO CMS_CHARGE_DTL
            ------------------------------------------

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
                      CCD_PLAN_CODE,
            ccd_pan_code_encr
                     )
                    VALUES
                    (
                    p_instcode,
                    NULL,
                --    p_pan_code
        v_hash_pan,
                    p_mbrnumb,
                    v_custcode,
                    v_cam_acct_id,
                    p_new_acct_no,
                    'R',
                    v_feetype_code,
                    v_fee_code,
                    v_fee_amt,
                    SYSDATE,
                    SYSDATE,
                    NULL,
                    NULL,
                    NULL,
                    p_lupduser,
                    SYSDATE,
                    p_lupduser,
                    SYSDATE,
                    NULL,
                    NULL,
          v_encr_pan
                    );


            EXCEPTION
            WHEN OTHERS THEN

            --ROLLBACK TO v_savepoint ;

            p_errmsg := 'ERROR WHILE INSERTING INTO CHARGE DTL ' || SUBSTR(SQLERRM,1, 100);

            RETURN;


            END;

            -----------------------------------------
            --EN INSERT A RECORD INTO CMS_CHARGE_DTL
            -----------------------------------------

            END IF;

        END ;
        -------------------------------------------
        -- EN 1.7 : TO CALCULATE FEE FOR DEBIT CARD
        --------------------------------------------

        -------------------------------------------
        -- SN 1.8 : TO INSERT IN PAN SUPPORT TABLE
        -------------------------------------------
        BEGIN

                  INSERT INTO CMS_PAN_SPPRT
                              (cps_inst_code, cps_pan_code, cps_mbr_numb,
                               cps_prod_catg, cps_spprt_key,
                               cps_spprt_rsncode, cps_func_remark,
                               cps_ins_user, cps_lupd_user, cps_cmd_mode,cps_pan_code_encr
                              )
                       VALUES (p_instcode, --p_pan_code
                       v_hash_pan, p_mbrnumb,
                               v_cap_prod_catg, 'LINK',
                               p_rsncode, p_remarks,
                               p_lupduser, p_lupduser, p_workmode,v_encr_pan
                              );
        EXCEPTION                                     --Excp of begin 4

            WHEN OTHERS THEN

            --ROLLBACK TO v_savepoint ;

            p_errmsg := 'ERROR WHILE INSERTING IN PAN SUPPORT MASTER '
                        || SUBSTR (SQLERRM, 1, 100);

            RETURN ;

        END;
        -------------------------------------------
        -- EN 1.8 :  TO INSERT IN PAN SUPPORT TABLE
        --------------------------------------------


        -------------------------------------------
        -- SN 1.9 : CAF REFRESH
        -------------------------------------------
        BEGIN

                SELECT  cci_file_gen, cci_seg12_issue_stat, cci_seg12_pin_mailer, cci_seg12_card_carrier,
                    cci_pin_ofst, cci_crd_stat
                INTO v_caffilegen_flag, v_issuestatus, v_pinmailer, v_cardcarrier,
                    v_pinoffset, v_cardstat
                FROM CMS_CAF_INFO
                WHERE cci_inst_code = p_instcode
                AND cci_pan_code = v_hash_pan--DECODE(LENGTH(p_pan_code), 16,p_pan_code || '   ', 19,p_pan_code)
                AND cci_mbr_numb = p_mbrnumb
                GROUP BY cci_file_gen,
                    cci_seg12_issue_stat,
                    cci_seg12_pin_mailer,
                    cci_seg12_card_carrier,
                    cci_pin_ofst,
                    cci_crd_stat
                    ;

                v_record_exist := 'Y';

                IF p_workmode = 0 THEN

                DELETE FROM CMS_CAF_INFO
                WHERE cci_inst_code = p_instcode
                AND cci_pan_code = v_hash_pan--DECODE(LENGTH(p_pan_code), 16,p_pan_code || '   ', 19,p_pan_code)
                AND cci_mbr_numb = p_mbrnumb
                ;

                END IF;




        EXCEPTION

                WHEN NO_DATA_FOUND    THEN

                    v_record_exist := 'N';

                WHEN others THEN

                    --ROLLBACK TO v_savepoint ;

                    p_errmsg := 'ERROR WHILE SELECTING RECORD FOR CAF : '
                    || SUBSTR (SQLERRM, 1, 100);

                    RETURN ;

        END;


              -----------------------------
            -- SN 1.9.1 : GENERATE CAF
            -----------------------------
            
            IF  p_workmode = 0 THEN -- SN: TO GENERATE CAF ONLY FOR OFFLINE MODE
            BEGIN --1.9.1

                  Sp_Caf_Rfrsh (p_instcode,
                        --p_pan_code
            p_pan_code,
                        p_mbrnumb,
                        SYSDATE,
                        'C',
                        NULL,
                        'LINK',
                        p_lupduser,
            p_pan_code,
                        p_errmsg
                           );

                  IF p_errmsg <> 'OK'
                  THEN
                    --ROLLBACK TO v_savepoint ;

                    p_errmsg := 'ERROR FROM CAF REFRESH : ' || p_errmsg;

                    RETURN ;

                  END IF;

            EXCEPTION -- 1.9.1

                WHEN others THEN

                    --ROLLBACK TO v_savepoint ;

                    p_errmsg := 'OTHER ERROR WHILE GENERATING CAF : ' || p_errmsg;

                    RETURN ;

                END ; -- 1.9.1
            END IF ; -- EN: TO GENERATE CAF ONLY FOR OFFLINE MODE


          -- ? CHINMAYA CONFIRM BELOW PARAMETER

                     IF p_workmode = 1 AND v_record_exist = 'Y'
                     THEN
                        UPDATE CMS_CAF_INFO
                           SET cci_file_gen = v_caffilegen_flag,
                               cci_seg12_issue_stat = v_issuestatus,
                               cci_seg12_pin_mailer = v_pinmailer,
                               cci_seg12_card_carrier = v_cardcarrier,
                               cci_pin_ofst = v_pinoffset
                         WHERE cci_inst_code = p_instcode
                           AND cci_pan_code = v_hash_pan--DECODE(LENGTH(p_pan_code), 16,p_pan_code || '   ', 19,p_pan_code)
                           AND cci_mbr_numb = p_mbrnumb;
                     END IF;




        -------------------------------------------
        -- EN 1.9 : CAF REFRESH
        -------------------------------------------

            --END;  --end 1.2

p_errmsg := 'OK';

EXCEPTION    --excp of begin 1.2
                WHEN OTHERS THEN
            p_errmsg := 'Excp 1.1 '||SQLERRM;
END;--END 1.1
/


show error