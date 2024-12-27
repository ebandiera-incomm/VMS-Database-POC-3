CREATE OR REPLACE PROCEDURE VMSCMS.sp_reissue_pan (
   prm_instcode       IN       NUMBER,
   prm_old_pancode    IN       VARCHAR2,
   prm_remark         IN       VARCHAR2,
   prm_rsncode        IN       NUMBER,
   prm_spprt_key      IN       VARCHAR2,
   prm_new_prodcode   IN       VARCHAR2,
   prm_new_cardtype   IN       VARCHAR2,
   prm_new_dispname   IN       VARCHAR2,
   prm_rowid          IN       NUMBER,
   prm_lupduser       IN       NUMBER,
   prm_newpan         OUT      VARCHAR2,
   prm_errmsg         OUT      VARCHAR2
)
IS
   v_old_product       cms_appl_pan.cap_prod_code%TYPE;
   v_old_cardtype      cms_appl_pan.cap_card_type%TYPE;
   v_old_prodcatg      cms_appl_pan.cap_prod_catg%TYPE;
   v_new_prod_catg     cms_prod_mast.cpm_catg_code%TYPE;
   v_new_product       cms_appl_pan.cap_prod_code%TYPE;
   v_new_cardtype      cms_appl_pan.cap_card_type%TYPE;
   v_check_cardtype    NUMBER (1);
   v_errmsg            VARCHAR2 (300);
   v_reasondesc        cms_spprt_reasons.csr_reasondesc%TYPE;
   v_tran_code           CMS_FUNC_MAST.cfm_txn_code%TYPE;
   v_tran_mode           CMS_FUNC_MAST.cfm_txn_mode%TYPE;
   v_delv_chnl           CMS_FUNC_MAST.cfm_delivery_channel%TYPE;
   v_savepoint         NUMBER DEFAULT 1;
   v_ressiue_dupflg    VARCHAR2(1);
   exp_reject_record   EXCEPTION;
   excp_reissue_dup    EXCEPTION;
   v_reissue_makecheker_flg varchar2(1);
   
     v_new_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_new_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;

    v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
 
BEGIN                                                       --<< MAIN BEGIN >>
   v_errmsg := 'OK';
   prm_errmsg := 'OK';
   SAVEPOINT v_savepoint;

--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(prm_old_pancode);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN CREATE HASH PAN 

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(prm_old_pancode);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN create encr pan

   
   --Sn find product catg( debit,prepaid etc)
   BEGIN
      SELECT cap_prod_catg, cap_prod_code, cap_card_type
        INTO v_old_prodcatg, v_old_product, v_old_cardtype
        FROM cms_appl_pan
       WHERE cap_pan_code =v_hash_pan-- prm_old_pancode 
       AND cap_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := ' Product category not found';
         RAISE exp_reject_record;
      WHEN TOO_MANY_ROWS
      THEN
         v_errmsg := ' More than one product category  found';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting product catg ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En find product catg( debit,prepaid etc)----
   
   --------Sn to check maker checker ison or not-------
   BEGIN
   select cip_param_value 
   into v_reissue_makecheker_flg
   from cms_inst_param
   where cip_inst_code=prm_instcode
   and cip_param_key='REISSUE';
   
   EXCEPTION WHEN OTHERS THEN
      prm_errmsg:='Error while chekcing maker checker mode '||substr(sqlerrm,1,200);
      RAISE exp_reject_record;
   END;
   --------Sn to check maker checker ison or not-------
   
   
  
   ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_reasondesc
                 INTO  v_reasondesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'REISSUE'
                  AND csr_spprt_rsncode=prm_rsncode 
                  AND csr_inst_code = prm_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Reissue  reason code not present in master';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

              ------------------------------En get reason code from support reason master-------
   
   --Sn get tran code
   BEGIN
           SELECT 
               cfm_txn_code,
               cfm_txn_mode,
               cfm_delivery_channel
        INTO   v_tran_code,
               v_tran_mode,
               v_delv_chnl
        FROM   CMS_FUNC_MAST
        WHERE  cfm_inst_code = prm_instcode 
        AND       cfm_func_code = 'REISSUE';
   EXCEPTION
           WHEN NO_DATA_FOUND THEN
        v_errmsg :=
            'Support function reissue not defined in master ' ;
         RAISE exp_reject_record;
        WHEN TOO_MANY_ROWS THEN
        v_errmsg :=
            'More than one record found in master for reissue support func ' ;
         RAISE exp_reject_record;
         
        WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting reissue fun detail ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
      
   END;
     
   --En get tran code   
   
   --Sn check new product and new cardtype
   IF TRIM (prm_new_prodcode) IS NULL
   THEN
      v_new_product := v_old_product;
      v_new_cardtype := v_old_cardtype;
   ELSE
      v_new_product := prm_new_prodcode;
      v_new_cardtype := prm_new_cardtype;
   END IF;

   --En check new product and new cardtype
   IF TRIM (prm_new_prodcode) IS NOT NULL
   THEN
      --Sn check new product catg with old product catg
      BEGIN
         SELECT cpm_catg_code
           INTO v_new_prod_catg
           FROM cms_prod_mast
          WHERE cpm_prod_code = v_new_product AND cpm_inst_code = prm_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := ' New product category not found';
            RAISE exp_reject_record;
         WHEN TOO_MANY_ROWS
         THEN
            v_errmsg := 'More than one product category found ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting product catg '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   --En check new product catg with old product catg
   ELSE
      v_new_prod_catg := v_old_prodcatg;
   END IF;

   --Sn check product and cardtype combination
   BEGIN
      SELECT 1
        INTO v_check_cardtype
        FROM cms_prod_cattype
       WHERE cpc_inst_code = prm_instcode
         AND cpc_prod_code = v_new_product
         AND cpc_card_type = v_new_cardtype;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := ' Not a valid combination of Product and product type';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting product and product type combination '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En check product and cardtype combination
   
   --Sn compare old and new product catg
   IF v_old_prodcatg <> v_new_prod_catg
   THEN
      v_errmsg := 'Both old and new product category is not matching';
      RAISE exp_reject_record;
   END IF;

   --En compare old and new product catg
   IF v_old_prodcatg in('D','A')
   THEN
      --Sn debit reissue--
      BEGIN
         sp_reissue_pan_debit (prm_instcode,
                               prm_old_pancode,
                               v_old_product,
                               prm_remark,
                               prm_rsncode,
                               prm_spprt_key,
                               v_new_product,
                               v_new_cardtype,
                               prm_new_dispname,
                               prm_lupduser,
                               v_ressiue_dupflg,
                               prm_newpan,
                               v_errmsg
                              );

         IF v_errmsg <> 'OK'
         THEN
--             IF v_errmsg='Card '||prm_old_pancode ||' has been sent for Duplicate reissuance'
--              THEN
--               RAISE excp_reissue_dup;
--                /*BEGIN
--                  INSERT INTO cms_reissue_detail
--                          (crd_inst_code, crd_old_card_no, crd_new_card_no,
--                           crd_file_name, crd_remarks, crd_msg24_flag,
--                           crd_process_flag, crd_process_msg,
--                           crd_process_mode, crd_ins_user, crd_ins_date,
--                           crd_lupd_user, crd_lupd_date, crd_reissue_dupflag
--                          )
--                   VALUES (prm_instcode, prm_old_pancode, prm_newpan,
--                           NULL, prm_remark, 'N',
--                           'C', v_errmsg,
--                           'S', prm_lupduser, SYSDATE,
--                           prm_lupduser, SYSDATE,'D'
--                          );
--                EXCEPTION
--                  WHEN OTHERS THEN
--                    prm_errmsg := 'Error while creating duplicate record ' || substr(sqlerrm,1,150);
--                    RETURN;    
--                END;*/
--                ELSE
                 RAISE exp_reject_record;
                --END IF;
           ELSE
            --Sn Create successful records
--                 IF v_ressiue_dupflg='D' THEN
--                    update cms_reissue_detail 
--                    set crd_process_flag='S',
--                        crd_process_msg='Suceessful',
--                        crd_new_card_no=prm_newpan
--                        where crd_old_card_no= prm_old_pancode
--                        and crd_process_flag='N'
--                        and crd_reissue_dupflag='D';
--                  ELSE

--SN CREATE HASH PAN 
BEGIN
    v_new_hash_pan := Gethash(prm_newpan);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_new_encr_pan := Fn_Emaps_Main(prm_newpan);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN create encr pan
                    BEGIN
                        IF v_reissue_makecheker_flg='Y' THEN                        
                            BEGIN
                                Update cms_group_reissue_temp
                                set cgh_process_flag='S',
                                cgh_process_msg='Successful',
                                 cgh_new_card_no=v_new_hash_pan,--prm_newpan
                                 cgh_new_card_no_encr=v_new_encr_pan
                                where cgh_inst_code=prm_instcode
                                and cgh_process_flag='N'
                                and cgh_card_no=v_hash_pan--prm_old_pancode                           
                                and cgh_rowid=prm_rowid;
                            
                                IF SQL%ROWCOUNT =0 THEN
                                 v_errmsg:='Error while updating temp table ' ||substr(sqlerrm,1,200);
                                 RAISE exp_reject_record;
                                END IF;
                             END;
                         END IF;
                   
                        INSERT INTO cms_reissue_detail
                                    (crd_inst_code, crd_old_card_no, crd_new_card_no,
                                     crd_file_name, crd_remarks, crd_msg24_flag,
                                     crd_process_flag, crd_process_msg,
                                     crd_process_mode, crd_ins_user, crd_ins_date,
                                     crd_lupd_user, crd_lupd_date, crd_new_dispname,
                                     crd_new_product, crd_new_productcat,crd_reason_code,
                                     crd_new_card_no_encr,crd_old_card_no_encr
                                    )
                             VALUES (prm_instcode, --prm_old_pancode, prm_newpan,
                             v_hash_pan,v_new_hash_pan,
                                     NULL, prm_remark, 'N',
                                     'S', 'Successful',
                                     'S', prm_lupduser, SYSDATE,
                                     prm_lupduser, SYSDATE,prm_new_dispname,v_new_product,
                                     v_new_cardtype,prm_rsncode,v_new_encr_pan,v_encr_pan);
                    EXCEPTION 
                    WHEN exp_reject_record THEN
                        RAISE;                                 
                    WHEN OTHERS THEN
                       prm_errmsg := 'Error while creating record in detail table ' || substr(sqlerrm,1,150);
                       RETURN;    
                    END;
                 --En create successful records
         
                --Sn Create audit log records
                BEGIN
                INSERT INTO PROCESS_AUDIT_LOG
                  (
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
                          VALUES    
                  (prm_instcode,
                   --prm_old_pancode
                    v_hash_pan, 
                   'Reissue pan',
                   v_tran_code,
                   v_delv_chnl,
                   0,
                   'HOST',
                   'S', 
                   prm_lupduser, 
                   sysdate,
                   'Successful',
                   v_reasondesc,
                   prm_remark,
                   'S',
                   --prm_newpan
                   v_new_hash_pan,
                   v_encr_pan,
                   v_new_encr_pan
                         );    
            
              EXCEPTION
               WHEN OTHERS THEN
               prm_errmsg := 'Error while creating record in detail table ' || substr(sqlerrm,1,150);
               RETURN;    
              END;
              --END IF;
              --En Create audit log records
         
         END IF;
      EXCEPTION
         WHEN excp_reissue_dup THEN
          RAISE;
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while executing debit reissue process '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   --En debit reissue--
   ELSIF v_old_prodcatg = 'P'
   THEN
      --Sn prepaid reissue--
      NULL;
   --En prepaid reissue--
   ELSE
      --Sn invalid product catg for reissue
      v_errmsg :=
            'Reissue for the product category not supported '
         || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
   --En invalid product catg for reissue
   END IF;
--Sn update successful message
EXCEPTION                                               --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      --Sn Create unsuccessful records
    --  prm_errmsg := 'OK';
      ROLLBACK TO v_savepoint;
       sp_reissue_support_log
            (
             prm_instcode,
             prm_old_pancode,
             prm_newpan,
             prm_new_dispname,
             v_new_product,
             v_new_cardtype,
             NULL,
             prm_remark,
             prm_rsncode,
             'N',
             'E',
             v_errmsg,
             'S',
             prm_lupduser,
             SYSDATE,
        ----------Audit log details------------
            'Reissue pan',
             v_tran_code,
               v_delv_chnl,
             0,
            'HOST',
             v_reasondesc,
             'S',
             prm_errmsg              
           );
           
           IF prm_errmsg <> 'OK' THEN
           RETURN;
           ELSE
            prm_errmsg := v_errmsg;
           END IF;

--       --Sn Create unsuccessful records
--       INSERT INTO cms_reissue_detail
--                   (crd_inst_code, crd_old_card_no, crd_new_card_no,
--                    crd_file_name, crd_remarks, crd_msg24_flag,
--                    crd_process_flag, crd_process_msg, crd_process_mode,
--                    crd_ins_user, crd_ins_date, crd_lupd_user, crd_lupd_date
--                   )
--            VALUES (prm_instcode, prm_old_pancode, prm_newpan,
--                    NULL, prm_remark, 'N',
--                    'E', v_errmsg, 'S',
--                    prm_lupduser, SYSDATE, prm_lupduser, SYSDATE
--                   );
--             --En create successful records
   --En create unsuccessful records
   WHEN excp_reissue_dup THEN
    ROLLBACK TO v_savepoint;
    sp_reissue_support_log
            (
             prm_instcode,
             prm_old_pancode,
             prm_newpan,
             prm_new_dispname,
             v_new_product,
             v_new_cardtype,
             NULL,
             prm_remark,
             prm_rsncode,
             'N',
             'C',
             v_errmsg,
             'S',
             prm_lupduser,
             SYSDATE,
        ----------Audit log details------------
            'Reissue pan',
             v_tran_code,
         v_delv_chnl,
             0,
            'HOST',
             v_reasondesc,
             'S',
             prm_errmsg              
           );
           
           IF prm_errmsg <> 'OK' THEN
           RETURN;
           ELSE
            prm_errmsg := v_errmsg;
           END IF;
    
   WHEN OTHERS
   THEN
      --Sn Create unsuccessful records
    --  prm_errmsg := 'OK';
      v_errmsg := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
      ROLLBACK TO v_savepoint;

          sp_reissue_support_log
            (
             prm_instcode,
             prm_old_pancode,
             prm_newpan,
             prm_new_dispname,
             v_new_product,
             v_new_cardtype,
             NULL,
             prm_remark,
             prm_rsncode,
             'N',
             'E',
             v_errmsg,
             'S',
             prm_lupduser,
             SYSDATE,
        ----------Audit log details------------
            'Reissue pan',
             v_tran_code,
               v_delv_chnl,
             0,
            'HOST',
             v_reasondesc,
             'S',
             prm_errmsg              
           );
           
           IF prm_errmsg <> 'OK' THEN
           RETURN;
           ELSE
            prm_errmsg := v_errmsg;
           END IF;
      
END;                                                           --<< MAIN END>>
/


