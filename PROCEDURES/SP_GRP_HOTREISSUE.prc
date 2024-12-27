CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Grp_Hotreissue
(
prm_instcode  IN NUMBER ,
prm_ipaddr    IN  VARCHAR2,
prm_lupduser  IN	NUMBER,
prm_errmsg    OUT VARCHAR2
)
as
   v_remark                 CMS_PAN_SPPRT.cps_func_remark%TYPE;
   v_cardstat               CMS_APPL_PAN.cap_card_stat%TYPE;
   v_resoncode              CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
   v_old_cardtype           cms_appl_pan.cap_card_type%TYPE;
   v_old_product            cms_appl_pan.cap_prod_code%TYPE;
   v_new_product            cms_appl_pan.cap_prod_code%TYPE;
   v_new_cardtype           varchar2(5);
   v_new_prod_catg          cms_prod_mast.cpm_catg_code%TYPE;
   --v_check_cardtype         NUMBER (1);
   v_cardtype_code          cms_appl_pan.cap_card_type%TYPE;
   v_new_pan                cms_appl_pan.cap_pan_code%type;
   v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
   v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;
   v_cardstatdesc           VARCHAR2 (10);
   v_mbrnumb                VARCHAR2 (3) DEFAULT '000';
   v_rrn                    VARCHAR2 (12);
   v_stan                   VARCHAR2 (12);
   v_authmsg                VARCHAR2 (300);
   v_card_curr              VARCHAR2 (3);
   v_errmsg                 VARCHAR2 (300);
   v_hotreissuetsavepoint   NUMBER (9) DEFAULT 99;
   v_errflag                CHAR (1);
   v_txn_code               VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_txn_mode               VARCHAR2 (2);
   v_del_channel            VARCHAR2 (2);
   v_succ_flag              VARCHAR2 (1);
   v_prod_catg              CMS_APPL_PAN.cap_prod_catg%TYPE;
   v_reasondesc             CMS_SPPRT_REASONS.CSR_REASONDESC%TYPE;
   exp_loop_reject_record   EXCEPTION;
   v_reissue_dupflg         varchar2(1);
   v_old_dispname           VARCHAR2(30);
   v_new_dispname           VARCHAR2(30);
  v_hash_new_pan	CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_new_pan	CMS_APPL_PAN.cap_pan_code_encr%TYPE;
  v_decr_pan	CMS_APPL_PAN.cap_pan_code_encr%TYPE;
  
   cursor c1 is
   select ROWID ROW_ID,
          CGH_INST_CODE,
          CGH_PAN_CODE,
          CGH_FILE_NAME,
          CGH_NEW_PRODUCT,
          CGH_NEW_PRODUCTCAT,
          CGH_NEW_DISPNAME,
          CGH_REMARK,
          CGH_NEWPAN_CODE,
          CGH_MBR_NUMB,
          CGH_INS_DATE,
          cgh_pan_code_encr
          from cms_group_hotreissue_temp
          where cgh_process_flag='N'
          and cgh_inst_code=prm_instcode;
begin                               --<< main begin start >>--
  prm_errmsg:='OK';

 

  ------------------------------ Sn get Function Master----------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'HTLST_RISU'
       AND cfm_inst_code= prm_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :='Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);        
         RETURN;
   END;

   ------------------------------ En get Function Master----------------------------
   
   ------------------------------Sn get reason code from support reason master--------------------
    BEGIN
      SELECT csr_spprt_rsncode,CSR_REASONDESC
        INTO v_resoncode,v_reasondesc
        FROM CMS_SPPRT_REASONS
       WHERE csr_spprt_key = 'HTLST_REISU' 
       AND csr_inst_code=prm_instcode
       AND ROWNUM < 2;
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         prm_errmsg := 'Hotlist reissue  reason code not present in master ';
         RETURN;
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg := 'Hotlist reissue  reason code not present in master';
         RETURN;
      WHEN OTHERS
      THEN
         prm_errmsg :='Error while selecting reason code from master '|| SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   ------------------------------En get reason code from support reason master---------------------
   
   for x in c1
    loop         
    begin                                                  --<< loop main begin start >>--
        v_hotreissuetsavepoint := v_hotreissuetsavepoint + 1;
        SAVEPOINT v_hotreissuetsavepoint;
        v_errmsg := 'OK';
        prm_errmsg := 'OK';
        
        


--SN create decr pan
BEGIN
	v_decr_pan := Fn_dmaps_Main(x.CGH_PAN_CODE_ENCR);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE	exp_loop_reject_record;
END;
--EN create decr pan


        IF NVL (LENGTH (TRIM (x.CGH_PAN_CODE)), 0) = 0 THEN
            v_errmsg := 'PAN Code Is Null';
            RAISE exp_loop_reject_record;
        ELSIF NVL (LENGTH (TRIM (x.CGH_REMARK)), 0) = 0 THEN
            v_errmsg := 'Remark Is Null';
            RAISE exp_loop_reject_record;
        ELSE
            v_errmsg := 'OK';
        END IF;
        ------------------------Sn to find prod catg ,card stat--------------------------
        BEGIN
            SELECT cap_prod_catg, cap_card_stat,cap_prod_code,cap_card_type,cap_disp_name,CAP_APPL_CODE,CAP_ACCT_NO
              INTO v_prod_catg, v_cardstat, v_old_product, v_old_cardtype,v_old_dispname,v_applcode, v_acctno
              FROM CMS_APPL_PAN
             WHERE cap_pan_code = x.CGH_PAN_CODE
             AND cap_mbr_numb = x.CGH_MBR_NUMB
             AND cap_inst_code= prm_instcode;
			 
            IF v_prod_catg IS NULL OR v_cardstat IS NULL THEN
               v_errmsg := 'Old card Product category or card status is not defined ';
               RAISE exp_loop_reject_record;						
            END IF;
			 
        EXCEPTION 
            WHEN NO_DATA_FOUND THEN
               v_errmsg := 'Card is not defined in master';
               RAISE exp_loop_reject_record;
            WHEN OTHERS THEN 
               v_errmsg :='Error while getting records from card master '|| SUBSTR(SQLERRM, 1, 200);
               RAISE exp_loop_reject_record;
        END;
        ------------------------En to find prod catg ,card stat--------------------------
        
        IF v_cardstat <> '1' THEN		 
            v_errmsg :='Card status is not open, cannot be hotlisted' ;
            RAISE exp_loop_reject_record;
        END IF;
        
        IF (x.CGH_NEW_DISPNAME) IS NULL THEN
            v_new_dispname:=v_old_dispname;
        ELSE
            v_new_dispname:=x.CGH_NEW_DISPNAME;
        END IF;
        
        IF trim(x.CGH_NEW_PRODUCT) IS NULL THEN
          v_new_product:= v_old_product;
          v_new_cardtype:= v_old_cardtype;
        ELSE
          v_new_product:=x.CGH_NEW_PRODUCT;
          ------------------Sn check product and cardtype combination-----------------
           BEGIN
              SELECT CPC_CARD_TYPE
                INTO v_new_cardtype
                FROM cms_prod_cattype
               WHERE cpc_inst_code = prm_instcode
                 AND cpc_prod_code = v_new_product
                 AND CPC_CARDTYPE_SNAME = x.CGH_NEW_PRODUCTCAT;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 v_errmsg := ' Not a valid combination of Product and product type';
                 RAISE exp_loop_reject_record;
              WHEN OTHERS THEN
                v_errmsg :='Error while selecting product and product type combination '|| SUBSTR (SQLERRM, 1, 200);
                 RAISE exp_loop_reject_record;
           END;
        ------------------En check product and cardtype combination-----------------
          
        END IF;
        
        IF trim(x.CGH_NEW_PRODUCT) IS NOT NULL THEN
        ----------Sn check new product catg with old product catg-----------------
            BEGIN
               SELECT cpm_catg_code
                 INTO v_new_prod_catg
                 FROM cms_prod_mast
                WHERE cpm_prod_code = v_new_product AND cpm_inst_code = prm_instcode;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  v_errmsg := ' New product category not found';
                  RAISE exp_loop_reject_record;
               WHEN TOO_MANY_ROWS THEN
                  v_errmsg := 'More than one product category found ';
                  RAISE exp_loop_reject_record;
               WHEN OTHERS THEN
                  v_errmsg :='Error while selecting product catg '|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;
          ELSE
            v_new_prod_catg:= v_prod_catg;
          END IF;
          
        --------------En check new product catg with old product catg----------------
        
        IF v_prod_catg <> v_new_prod_catg   THEN
          v_errmsg := 'Both old and new product category is not matching';
          RAISE exp_loop_reject_record;
        END IF;
        
        IF v_prod_catg = 'P' THEN
         --------------Sn to hotlist reissue for prepaid card-------------
          NULL;
         --------------En to hotlist reissue for prepaid card-------------
        ELSIF v_prod_catg in('D','A') THEN
         -------------Sn to hotlist reissue for Debit card
          Sp_Hotlist_Pan_Debit (
                                  prm_instcode,
                                 -- x.CGH_PAN_CODE
                                 v_decr_pan,
                                  x.CGH_MBR_NUMB,
                                  x.CGH_REMARK,
                                  v_resoncode,
                                  prm_lupduser,
                                  0,
                                  v_errmsg
                                    );
          IF v_errmsg <> 'OK' THEN
            RAISE exp_loop_reject_record;          
          ELSE
           sp_reissue_pan_debit (
                                 prm_instcode,
                                -- x.CGH_PAN_CODE
                                 v_decr_pan,
                                 v_old_product,
                                 x.CGH_REMARK,
                                 v_resoncode,
                                 'HR',
                                 v_new_product,
                                 v_new_cardtype,
                                 v_new_dispname,
                                 prm_lupduser,
                                 v_reissue_dupflg,
                                 v_new_pan,
                                 v_errmsg
                              );

--SN CREATE HASH PAN 
BEGIN
    v_hash_new_pan := Gethash(v_new_pan);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_loop_reject_record;
END;
--EN CREATE HASH PAN
 
--SN create encr pan
BEGIN
    v_encr_new_pan := Fn_Emaps_Main(v_new_pan);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_loop_reject_record;
END;
--EN create encr pan                     
                              
                              
             IF v_errmsg <> 'OK'
             THEN
                RAISE exp_loop_reject_record;
             ELSE
                  v_errflag := 'S';
                  v_succ_flag := 'S';
                  v_errmsg := 'SUCCESSFUL';
                  UPDATE cms_group_hotreissue_temp
                     SET cgh_process_flag = 'S',
                         cgh_newpan_code  = v_hash_new_pan , --v_new_pan
                         cgh_process_msg = 'SUCCESSFULL'
                     WHERE ROWID = x.ROW_ID;
             --------------------Sn create successful records in detail table-----------------
                BEGIN
                  INSERT INTO cms_hotreissue_detail(
                                                    crd_inst_code,
                                                    crd_old_card_no,
                                                    crd_new_card_no,
                                                    crd_file_name,
                                                    crd_remarks,
                                                    crd_msg24_flag,
                                                    crd_process_flag,
                                                    crd_process_msg,
                                                    crd_process_mode,
                                                    crd_ins_user,
                                                    crd_ins_date,
                                                    crd_lupd_user,
                                                    crd_lupd_date,
                                                    crd_new_dispname,
                                                    crd_old_card_no_encr,
                                                    crd_new_card_no_encr
                                                  )
                                            VALUES(
                                                    prm_instcode,
                                                    x.CGH_PAN_CODE,
                                                    --v_new_pan
                                                    v_hash_new_pan,
                                                    x.CGH_FILE_NAME,
                                                    x.CGH_REMARK,
                                                    'N',
                                                    'S',
                                                    'Successful',
                                                    'G',
                                                    prm_lupduser,
                                                    x.CGH_INS_DATE,
                                                    prm_lupduser,
                                                    x.CGH_INS_DATE,
                                                    v_new_dispname,
                                                    x.CGH_PAN_CODE_encr,
                                                    v_encr_new_pan
                                                  );
                EXCEPTION
                  WHEN OTHERS THEN
                      v_errmsg := 'Error while creating record in cms_hotreissue_detail table ' || substr(sqlerrm,1,150);
                      RAISE exp_loop_reject_record;    
                END;
                --------------------En create successful records in detail table-----------------
                
                /*---------------------Sn Create audit log records---------------------------------
                BEGIN
                  INSERT INTO PROCESS_AUDIT_LOG(
                                                 pal_inst_code,
                                                 pal_card_no, 
                                                 pal_activity_type, 
                                                 pal_transaction_code,
                                                 pal_delv_chnl, 
                                                 pal_tran_amt, 
                                                 pal_source,
                                                 pal_success_flag, 
                                                 pal_ins_user, 
                                                 pal_ins_date,
                                                 pal_process_msg, 
                                                 pal_reason_desc, 
                                                 pal_remarks,
                                                 pal_spprt_type,
                                                 pal_new_card
                                                )
                                          VALUES(
                                                 prm_instcode,
                                                 x.CGH_PAN_CODE, 
                                                 x.CGH_REMARK,
                                                 v_txn_code,
                                                 v_del_channel,
                                                 0,
                                                 'HOST',
                                                 v_succ_flag, 
                                                 prm_lupduser, 
                                                 sysdate,
                                                 'Successful',
                                                 'Hotlist and reissue',
                                                 x.CGH_REMARK,
                                                 'G',
                                                 v_new_pan
                                                );    
            
                EXCEPTION
                  WHEN OTHERS THEN
                  v_errmsg := 'Error while creating record in audit table ' || substr(sqlerrm,1,150);
                  RAISE exp_loop_reject_record;
              END;
              -----------------------En Create audit log records------------------*/
            END IF;         
        END IF;
          -------------Sn to hotlist reissue for Debit card-----------------------
      END IF;
        
    EXCEPTION                                              --<< loop main exception >>--
      WHEN exp_loop_reject_record THEN
        ROLLBACK TO v_hotreissuetsavepoint;
        v_succ_flag := 'E';
        UPDATE CMS_GROUP_HOTREISSUE_TEMP
            SET cgh_process_flag = 'E',
                cgh_process_msg = v_errmsg
            WHERE ROWID = x.ROW_ID;
        INSERT INTO cms_hotreissue_detail(
                                           crd_inst_code,
                                           crd_old_card_no,
                                           crd_new_card_no,
                                           crd_file_name,
                                           crd_remarks,
                                           crd_msg24_flag,
                                           crd_process_flag,
                                           crd_process_msg,
                                           crd_process_mode,
                                           crd_ins_user,
                                           crd_ins_date,
                                           crd_lupd_user,
                                           crd_lupd_date,
                                           crd_new_dispname,
                                           crd_old_card_no_encr,
                                           crd_new_card_no_encr
                                           )
                                    VALUES(
                                           prm_instcode,
                                           x.CGH_PAN_CODE,
                                           --v_new_pan
                                           v_hash_new_pan,
                                           x.CGH_FILE_NAME,
                                           x.CGH_REMARK,
                                           'N',
                                           v_succ_flag,
                                           v_errmsg,
                                           'G',
                                           prm_lupduser,
                                           x.CGH_INS_DATE,
                                           prm_lupduser,
                                           x.CGH_INS_DATE,
                                           v_new_dispname,
                                           x.CGH_PAN_CODE_encr,
                                           v_encr_new_pan
                                           );
      WHEN OTHERS THEN
        ROLLBACK TO v_hotreissuetsavepoint;
        v_succ_flag := 'E';
        v_errmsg := 'Error while processing hotlist and reissue ' || substr(sqlerrm,1,200);
        UPDATE CMS_GROUP_HOTREISSUE_TEMP
            SET cgh_process_flag = 'E',
                cgh_process_msg = v_errmsg
            WHERE ROWID = x.ROW_ID;
        INSERT INTO cms_hotreissue_detail(
                                           crd_inst_code,
                                           crd_old_card_no,
                                           crd_new_card_no,
                                           crd_file_name,
                                           crd_remarks,
                                           crd_msg24_flag,
                                           crd_process_flag,
                                           crd_process_msg,
                                           crd_process_mode,
                                           crd_ins_user,
                                           crd_ins_date,
                                           crd_lupd_user,
                                           crd_lupd_date,
                                           crd_new_dispname,
                                           crd_old_card_no_encr,
                                           crd_new_card_no_encr
                                           )
                                    VALUES(
                                           prm_instcode,
                                           x.CGH_PAN_CODE,
                                           --v_new_pan
                                            v_hash_new_pan,
                                           x.CGH_FILE_NAME,
                                           x.CGH_REMARK,
                                           'N',
                                           v_succ_flag,
                                           v_errmsg,
                                           'G',
                                           prm_lupduser,
                                           x.CGH_INS_DATE,
                                           prm_lupduser,
                                           x.CGH_INS_DATE,
                                           v_new_dispname,
                                            x.CGH_PAN_CODE_encr,
                                           v_encr_new_pan
                                           );
      
        
    
    END;          --<< loop main begin end >>--
                    --siva mar 22 2011
        --start for audit log success
      IF v_errmsg = 'SUCCESSFUL'
      THEN
         --insert into Audit table
         BEGIN
            INSERT INTO cms_audit_log_process
                        (cal_inst_code, cal_appl_no, cal_acct_no,
                         cal_pan_no, cal_prod_code, cal_prg_name,
                         cal_action, cal_status, cal_ip_address,
                         cal_ref_tab_name, cal_ref_tab_rowid, cal_pan_encr,
                         cal_ins_user, cal_ins_date
                        )
                 VALUES (prm_instcode, v_applcode, v_acctno,
                         x.CGH_PAN_CODE, v_old_product, 'GROUP HOTLIST AND REISSUE',
                         'INSERT', 'SUCCESS', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.CGH_PAN_CODE_ENCR,
                         prm_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while inserting records for support detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      --end insert audit table

       --end for audit log success
      -- start for failure record
      ELSE
         --insert into Audit table
         BEGIN
            INSERT INTO cms_audit_log_process
                        (cal_inst_code, cal_appl_no, cal_acct_no,
                         cal_pan_no, cal_prod_code, cal_prg_name,
                         cal_action, cal_status, cal_ip_address,
                         cal_ref_tab_name, cal_ref_tab_rowid, cal_pan_encr,
                         cal_ins_user, cal_ins_date
                        )
                 VALUES (prm_instcode, v_applcode, v_acctno,
                         x.CGH_PAN_CODE, v_old_product, 'GROUP HOTLIST AND REISSUE',
                         'INSERT', 'FAILURE', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.CGH_PAN_CODE_ENCR,
                         prm_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while inserting records for support detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      --end insert audit table
      END IF;

      --end for failure status record
          --siva end mar 22 2011
    
    BEGIN
    INSERT INTO PROCESS_AUDIT_LOG(
                                        pal_inst_code,
                                        pal_card_no, 
                                        pal_activity_type, 
                                        pal_transaction_code,
                                        pal_delv_chnl, 
                                        pal_tran_amt, 
                                        pal_source,
                                        pal_success_flag, 
                                        pal_ins_user, 
                                        pal_ins_date,
                                        pal_process_msg, 
                                        pal_reason_desc, 
                                        pal_remarks,
                                        pal_spprt_type,
                                        pal_new_card,
                                        pal_card_no_encr,
                                        pal_new_card_encr
                                        )
                                 VALUES(
                                        prm_instcode,
                                        x.CGH_PAN_CODE, 
                                        'Hotlist and reissue',
                                        v_txn_code,
                                        v_del_channel,
                                        0,
                                        'HOST',
                                        v_succ_flag, 
                                        prm_lupduser, 
                                        sysdate,
                                        v_errmsg,
                                        'Hotlist and reissue',
                                         x.CGH_REMARK,
                                         'G',
                                       --  v_new_pan
                                         v_hash_new_pan,
                                           x.CGH_PAN_CODE_encr, 
                                           v_encr_new_pan
                                         );            
    EXCEPTION
      WHEN OTHERS THEN
        UPDATE CMS_GROUP_HOTREISSUE_TEMP
        SET cgh_process_flag = 'E',
            cgh_process_msg = v_errmsg
        WHERE ROWID = x.ROW_ID;
    END;    
    END LOOP;   
    prm_errmsg := 'OK'; 
EXCEPTION                           --<< main exception >>--
WHEN OTHERS THEN
  prm_errmsg:='Main error occurs from grp hotlist reissue '||substr(sqlerrm,1,200);
END;                               --<< main begin end >>--
/


