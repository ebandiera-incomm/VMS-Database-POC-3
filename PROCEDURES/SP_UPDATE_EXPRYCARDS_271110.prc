CREATE OR REPLACE PROCEDURE VMSCMS.SP_UPDATE_EXPRYCARDS_271110 (prm_instcode IN number,
                                                 prm_lupduser IN number,
                                                 prm_errmsg OUT varchar2
                                                )
as
 CURSOR c1
   IS
       SELECT cap_pan_code, cap_mbr_numb,cap_lupd_user,
       cap_prod_catg
       FROM CMS_APPL_PAN, CMS_BIN_MAST, CMS_PROD_MAST
       WHERE cap_expry_date < LAST_DAY(ADD_MONTHS(SYSDATE,-1)) + 1 
       AND cap_card_stat = '1'  
       AND cap_prod_catg = 'D' 
       AND cbm_inst_bin = SUBSTR(cap_pan_Code,1,6)
       AND cbm_inst_code = prm_instcode
       AND cpm_inst_code = cap_inst_code
       AND cpm_prod_code = cap_prod_code
       AND ROWNUM <19000; 
       
 v_savepoint        NUMBER := 0; 
 exp_reject_record  EXCEPTION;
 v_proc_flag        CHAR (1);
 v_expcount         NUMBER;
 v_errmsg           VARCHAR2(500);
 v_acctnt           NUMBER;
 v_record_exist		CHAR (1) := 'Y';
 v_caffilegen_flag	CHAR (1) := 'N';
 v_issuestatus      VARCHAR2 (2);
 v_pinmailer        VARCHAR2 (1);
 v_cardcarrier		VARCHAR2 (1);
 v_pinoffset		VARCHAR2 (16);
 v_rec_type		    VARCHAR2 (1);
 v_succ_flag varchar2(1);
BEGIN
    prm_errmsg:='OK';
    
    BEGIN
        SELECT cip_param_value
        INTO v_proc_flag
        FROM CMS_INST_PARAM
        WHERE cip_inst_code = 1 
        AND cip_param_key = 'EXPCLOSEPROC';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        prm_errmsg := 'Parameter not defined in Master';
    RETURN;
    WHEN OTHERS THEN
        prm_errmsg:='Error while fetching details for expiry close card '||substr(sqlerrm,1,200);
        RETURN;
    END;
    
    IF v_proc_flag = 'Y'
    THEN
      prm_errmsg := 'Process Already executed';      
   END IF;
   
   FOR i in C1
    LOOP
        BEGIN
            v_savepoint:=v_savepoint+1;
            SAVEPOINT v_savepoint;
            v_errmsg:='OK';
            
            --Sn to update status for pan
            BEGIN                                                      
                UPDATE CMS_APPL_PAN
                SET cap_card_stat = '9'
                WHERE cap_inst_code = prm_instcode
                AND cap_pan_code = i.cap_pan_code
                AND cap_mbr_numb = i.cap_mbr_numb;
                
                IF SQL%ROWCOUNT != 1
                THEN
                    v_errmsg :='Problem in updation of status for pan '|| i.cap_pan_code|| ' '||substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
                END IF;
            END;
            
            --Sn not to generate CAF for cards which dont have account
            BEGIN 
                SELECT COUNT(cpa_acct_id)
                INTO    v_acctnt
                FROM    CMS_PAN_ACCT 
                WHERE    cpa_inst_code = prm_instcode
                AND cpa_pan_code = i.cap_pan_code
                AND cpa_mbr_numb = i.cap_mbr_numb;
                
                IF v_acctnt = 0 then
                    v_errmsg:='No Accounts linked to PAN. Card Closed without CAF.';
                    RAISE exp_reject_record;
                END IF;
            EXCEPTION    
            WHEN OTHERS THEN 
                v_errmsg:='Error while checking linked accounts to the pan '||i.cap_pan_code||' '||substr(sqlerrm,1,200);
                RAISE exp_reject_record;
            END;
             -- En not to generate CAF for cards which dont have account
            
            IF v_acctnt>0 THEN
               
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
                WHERE cci_inst_code = prm_instcode
                AND trim(cci_pan_code)    = i.cap_pan_code
                AND cci_mbr_numb = i.cap_mbr_numb
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
                v_errmsg := 'Error while selecting caf details '|| SUBSTR (SQLERRM, 1, 300);
                RAISE exp_reject_record;
              END;
              --En get caf detail          
                
               BEGIN                                                      
                    DELETE FROM CMS_CAF_INFO
                    WHERE cci_inst_code = prm_instcode
                    AND trim(cci_pan_code) = i.cap_pan_code
                    AND cci_mbr_numb = i.cap_mbr_numb;
               EXCEPTION
                WHEN OTHERS THEN
                    v_errmsg := 'Error in deleting from Caf '||substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
               END;
               
               BEGIN                                --Begin -4
                     Sp_Caf_Rfrsh (prm_instcode,
                                   i.cap_pan_code,
                                   i.cap_mbr_numb,
                                   SYSDATE,
                                   'C',
                                   NULL,
                                   'EXPRY',
                                   i.cap_lupd_user,
                                   v_errmsg
                                  );
                      IF v_errmsg != 'OK' THEN
                         v_errmsg := 'From caf refresh -' ||v_errmsg;
                         RAISE exp_reject_record;
                      ELSE
                          v_succ_flag:='S';
                          BEGIN                                                        
                             INSERT INTO CMS_PAN_SPPRT
                                         (cps_inst_code, cps_pan_code, cps_mbr_numb,
                                          cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                                          cps_func_remark, cps_ins_user, cps_ins_date,
                                          cps_lupd_user, cps_lupd_date, cps_cmd_mode
                                         )
                                  VALUES (prm_instcode, i.cap_pan_code, i.cap_mbr_numb,
                                          i.cap_prod_catg, 'EXPRY', 1,
                                          'CARD EXPIRED', i.cap_lupd_user, SYSDATE,
                                          i.cap_lupd_user, SYSDATE, 0
                                         );
                          EXCEPTION                                             
                             WHEN OTHERS
                             THEN                                
                                v_errmsg := 'Error while creating suucessful entry in pan support ' || substr(SQLERRM,1,200);
                                RAISE exp_reject_record;
                          END;
                          
                          BEGIN
                                INSERT INTO CMS_EXPIRYCARD_CLOSE_DETAIL
                                        (ced_inst_code,ced_pan_code,ced_remark,ced_process_flag,
                                         ced_process_msg,ced_process_mode,ced_ins_user,
                                         ced_ins_date,ced_lupd_user,ced_lupd_date
                                        )
                                  VALUES(prm_instcode,i.cap_pan_code,'CARD EXPIRED',v_succ_flag,
                                         'Successful','G',prm_lupduser,
                                         SYSDATE,prm_lupduser,SYSDATE
                                         );
                          EXCEPTION                                             
                             WHEN OTHERS
                             THEN                                
                                v_errmsg:= 'Error while creating successful detail entry ' || substr(SQLERRM,1,200);
                                RAISE exp_reject_record;
                          END;
                                                                   
                      END IF;
               END;
               
               IF v_rec_type = 'A' THEN
                  v_issuestatus := '00';                
                  v_pinoffset := RPAD ('Z', 16, 'Z');   
               END IF;
               
               --Sn update caf info
               IF v_record_exist = 'Y' THEN
                 BEGIN
                    UPDATE CMS_CAF_INFO
                    SET	 cci_seg12_issue_stat = v_issuestatus,
                     cci_seg12_pin_mailer = v_pinmailer,
                     cci_seg12_card_carrier = v_cardcarrier,
                     cci_pin_ofst = v_pinoffset        
                    WHERE  cci_inst_code = prm_instcode
                    AND trim(cci_pan_code) = i.cap_pan_code
                    AND cci_mbr_numb    = i.cap_mbr_numb;
                 EXCEPTION
                 WHEN OTHERS THEN
                  v_errmsg := 'Error updating CAF record ' || substr(sqlerrm,1,200);
                  RAISE exp_reject_record;
                 END;
               END IF;
                --En update caf info                 
                
            END IF;                                     
        EXCEPTION 
        WHEN exp_reject_record THEN
           IF v_errmsg='No Accounts linked to PAN. Card Closed without CAF.' THEN            
              v_succ_flag:='S';
           ELSE
              ROLLBACK TO v_savepoint;
              v_succ_flag:='E';
           END IF;           
           INSERT INTO CMS_EXPIRYCARD_CLOSE_DETAIL
                  (ced_inst_code,ced_pan_code,ced_remark,ced_process_flag,
                   ced_process_msg,ced_process_mode,ced_ins_user,
                   ced_ins_date,ced_lupd_user,ced_lupd_date
                   )
           VALUES(prm_instcode,i.cap_pan_code,'CARD EXPIRED',v_succ_flag,
                  v_errmsg,'G',prm_lupduser,
                  SYSDATE,prm_lupduser,SYSDATE
                  );            
        WHEN OTHERS THEN
            ROLLBACK TO v_savepoint;
            v_succ_flag:='E';           
            INSERT INTO CMS_EXPIRYCARD_CLOSE_DETAIL
                  (ced_inst_code,ced_pan_code,ced_remark,ced_process_flag,
                   ced_process_msg,ced_process_mode,ced_ins_user,
                   ced_ins_date,ced_lupd_user,ced_lupd_date
                   )
            VALUES(prm_instcode,i.cap_pan_code,'CARD EXPIRED',v_succ_flag,
                   v_errmsg,'G',prm_lupduser,
                   SYSDATE,prm_lupduser,SYSDATE
                   );            
        END;    
    END LOOP;
    BEGIN
      SELECT COUNT(1) 
      INTO v_expcount
      FROM CMS_APPL_PAN, CMS_BIN_MAST, CMS_PROD_MAST
           WHERE cap_expry_date < LAST_DAY(ADD_MONTHS(SYSDATE,-1)) + 1 
           AND cap_card_stat = '1'  
           AND cap_prod_catg = 'D' 
           AND cbm_inst_bin = SUBSTR(cap_pan_Code,1,6)
           AND cbm_inst_code = prm_instcode
           AND cpm_prod_code = cap_prod_Code;
      EXCEPTION
      WHEN OTHERS THEN
           prm_errmsg:='Error while getting count for expired card to close '||substr(sqlerrm,1,200);
           v_expcount:=0;
      END;
      
      IF v_expcount = 0 THEN      
          UPDATE CMS_INST_PARAM
          SET cip_param_value = 'Y'
           WHERE cip_inst_code = 1 
           AND cip_param_key ='EXPCLOSEPROC'
           AND cip_inst_code=prm_instcode;
      END IF;
EXCEPTION WHEN OTHERS THEN
    prm_errmsg:='Error from main process '||substr(sqlerrm,1,200);
END;
/


