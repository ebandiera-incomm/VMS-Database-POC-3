CREATE OR REPLACE PROCEDURE VMSCMS.sp_hotreissue_pan
(
prm_instcode          IN NUMBER,    
prm_pan_code          IN VARCHAR2,  
prm_remark            IN VARCHAR2,  
prm_rsncode            IN NUMBER,
prm_spprt_key     IN VARCHAR2,
prm_new_prodcode    IN  VARCHAR2, 
prm_new_cardtype    IN  VARCHAR2, 
prm_new_dispname    IN  VARCHAR2, 
prm_lupduser          IN  NUMBER,   
prm_workmode          IN NUMBER,    
prm_newpan            OUT VARCHAR2, 
prm_errmsg            OUT VARCHAR2
)
AS
v_old_product         cms_appl_pan.cap_prod_code%TYPE;
v_old_cardtype        cms_appl_pan.cap_card_type%TYPE;
v_prod_catg        cms_appl_pan.cap_prod_catg%TYPE;
v_new_prod_catg       cms_prod_mast.cpm_catg_code%TYPE;
v_new_product         cms_appl_pan.cap_prod_code%TYPE;
v_new_cardtype        cms_appl_pan.cap_card_type%TYPE;
v_cardstat            CMS_APPL_PAN.cap_card_stat%TYPE;
v_check_cardtype      NUMBER (1);
v_mbrnumb                  CMS_APPL_PAN.cap_mbr_numb%type;
v_errmsg              VARCHAR2 (300);
v_txn_code                CMS_FUNC_MAST.cfm_txn_code%TYPE;
v_txn_mode                CMS_FUNC_MAST.cfm_txn_mode%TYPE;
v_txn_type            CMS_FUNC_MAST.cfm_txn_type%TYPE;
v_del_channel              CMS_FUNC_MAST.cfm_delivery_channel%TYPE;
v_hotreissuesavepoint NUMBER    DEFAULT 0;
exp_reject_record     EXCEPTION;
v_reasondesc        cms_spprt_reasons.csr_reasondesc%TYPE;
v_reissue_dupflg      VARCHAR2(1);

 v_hash_pan             CMS_APPL_PAN.CAP_PAN_CODE%TYPE;                                          
 v_encr_pan                CMS_APPL_PAN.cap_pan_code_encr%TYPE;
v_hash_new_pan             CMS_APPL_PAN.CAP_PAN_CODE%TYPE; 
v_encr_new_pan CMS_APPL_PAN.cap_pan_code_encr%TYPE;
BEGIN                                           --<< main begin starts >>--
prm_errmsg:='OK';
v_errmsg:='OK';
v_hotreissuesavepoint:=v_hotreissuesavepoint + 1;

  --SN CREATE HASH PAN 
                 BEGIN
                 v_hash_pan := Gethash(prm_pan_code);
                  EXCEPTION
                     WHEN OTHERS THEN
                   v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
            RAISE exp_reject_record;
             END;
    --EN CREATE HASH PAN
         
  --SN create encr pan
                  BEGIN
                 v_encr_pan := Fn_Emaps_Main(prm_pan_code);
                 EXCEPTION
                 WHEN OTHERS THEN
                   v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
            RAISE exp_reject_record;
                 END;
    --EN create encr pan
  
SAVEPOINT v_hotreissuesavepoint;
-----------------------------------Sn find prod catg--------------------------------
        BEGIN
            SELECT cap_prod_catg,cap_card_stat,cap_prod_code,cap_card_type
            INTO   v_prod_catg,v_cardstat,v_old_product, v_old_cardtype
            FROM   CMS_APPL_PAN
            WHERE  cap_pan_code  = v_hash_pan--prm_pan_code
            AND    cap_inst_code = prm_instcode;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_errmsg := 'Product category not defined in master';
            RAISE exp_reject_record;
        WHEN OTHERS THEN
            v_errmsg := 'Error while selecting product category '|| substr(sqlerrm,1,200);
            RAISE exp_reject_record;
        END;
    ---------------------------------En find prod catg-------------------------------------
  ------------------------------ Sn get Function Master--------------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'HTLST_RISU'
       AND cfm_inst_code = prm_instcode;
   EXCEPTION
      WHEN OTHERS THEN
         v_errmsg :='Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
    END;
   ------------------------------ En get Function Master--------------------------------------
   ------------------------------Sn get reason code from support reason master--------------------
    BEGIN
      SELECT CSR_REASONDESC
        INTO v_reasondesc
        FROM CMS_SPPRT_REASONS
       WHERE csr_spprt_key = 'HTLST'
       AND csr_spprt_rsncode=prm_rsncode
       AND csr_inst_code=prm_instcode
       AND ROWNUM < 2;
   EXCEPTION
      WHEN VALUE_ERROR THEN
         v_errmsg := 'Hotlist reissue  reason code not present in master ';
         RAISE exp_reject_record;
      WHEN NO_DATA_FOUND THEN
         v_errmsg := 'Hotlist reissue  reason code not present in master';
         RAISE exp_reject_record;
      WHEN OTHERS THEN
         v_errmsg :='Error while selecting reason code from master '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   ------------------------------En get reason code from support reason master---------------------
   -------------------------------Sn find default member number-----------------------------------
        BEGIN
        SELECT cip_param_value
        INTO   v_mbrnumb
        FROM   CMS_INST_PARAM
        WHERE  cip_inst_code = prm_instcode
        AND    cip_param_key = 'MBR_NUMB';
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_errmsg := 'memeber number not defined in master';
            RAISE exp_reject_record;
        WHEN OTHERS THEN
            v_errmsg := 'Error while selecting memeber number '|| substr(sqlerrm,1,200);
            RAISE exp_reject_record;
        END;
    ---------------------------------En find default member number--------------------------------------
  IF v_cardstat <> '1' THEN         
    v_errmsg :='Card status is not open, cannot be hotlisted' ;
    RAISE exp_reject_record;
  END IF;
  IF trim(prm_new_prodcode) IS NULL THEN
          v_new_product:= v_old_product;
          v_new_cardtype:= v_old_cardtype;
  ELSE
          v_new_product:=prm_new_prodcode;
          v_new_cardtype:=prm_new_cardtype;
  END IF;
  IF trim(prm_new_prodcode) IS NOT NULL THEN
    ----------Sn check new product catg with old product catg-----------------------------
      BEGIN
        SELECT cpm_catg_code
        INTO v_new_prod_catg
        FROM cms_prod_mast
        WHERE cpm_prod_code = v_new_product AND cpm_inst_code = prm_instcode;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_errmsg := ' New product category not found';
          RAISE exp_reject_record;
        WHEN TOO_MANY_ROWS THEN
          v_errmsg := 'More than one product category found ';
          RAISE exp_reject_record;
          WHEN OTHERS THEN
          v_errmsg :='Error while selecting product catg '|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
      END;
  ELSE
      v_new_prod_catg:= v_prod_catg;
  END IF;          
    --------------En check new product catg with old product catg----------------------------
  ------------------Sn check product and cardtype combination----------------------------------
  BEGIN
      SELECT 1
      INTO v_check_cardtype
      FROM cms_prod_cattype
      WHERE cpc_inst_code = prm_instcode
      AND cpc_prod_code = v_new_product
      AND cpc_card_type = v_new_cardtype;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
          v_errmsg := ' Not a valid combination of Product and product type';
          RAISE exp_reject_record;
      WHEN OTHERS THEN
          v_errmsg :='Error while selecting product and product type combination '|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
      END;
  ------------------En check product and cardtype combination-----------------------------------
  IF v_prod_catg <> v_new_prod_catg   THEN
     v_errmsg := 'Both old and new product category is not matching';
     RAISE exp_reject_record;
  END IF;
  IF v_prod_catg = 'P' THEN
  --------------Sn to hotlist reissue for prepaid card-------------
    NULL;
   --------------En to hotlist reissue for prepaid card-------------
  ELSIF v_prod_catg in('D','A') THEN
  -------------Sn to hotlist reissue for Debit card-----------------------
    Sp_Hotlist_Pan_Debit (
                          prm_instcode,
                          prm_pan_code,
                          v_mbrnumb   ,
                          prm_remark  ,
                          prm_rsncode ,
                          prm_lupduser,
                          prm_workmode ,
                          v_errmsg
                        );
    IF v_errmsg <> 'OK' THEN
      RAISE exp_reject_record;
        ELSE
      sp_reissue_pan_debit (   
                               prm_instcode,
                               prm_pan_code,
                               v_old_product,
                               prm_remark,
                               prm_rsncode,
                               prm_spprt_key,
                               v_new_product,
                               v_new_cardtype,
                               prm_new_dispname,
                               prm_lupduser,
                               v_reissue_dupflg,
                               prm_newpan,
                               v_errmsg
                            );
      IF v_errmsg <> 'OK' THEN
        RAISE exp_reject_record;
      ELSE
        --------------------Sn create successful records in detail table-----------------
          --SN CREATE HASH PAN 
                 BEGIN
                 v_hash_new_pan := Gethash(prm_newpan);
                  EXCEPTION
                     WHEN OTHERS THEN
                   v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
            RAISE exp_reject_record;
             END;
    --EN CREATE HASH PAN
  
          --SN create encr pan
                  BEGIN
                 v_encr_new_pan := Fn_Emaps_Main(prm_newpan);
                 EXCEPTION
                 WHEN OTHERS THEN
                   v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
            RAISE exp_reject_record;
                 END;
    --EN create encr pan
  
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
                                             v_hash_pan,-- prm_pan_code,
                                             v_hash_new_pan, -- prm_newpan,
                                              NULL,
                                              prm_remark,
                                              'N',
                                              'S',
                                              'Successful',
                                              'S',
                                              prm_lupduser,
                                              SYSDATE,
                                              prm_lupduser,
                                              SYSDATE,
                                              prm_new_dispname,
                                              v_encr_pan,
                                              v_encr_new_pan
                                            );
         EXCEPTION
           WHEN OTHERS THEN
              v_errmsg := 'Error while creating record in cms_hotreissue_detail table ' || substr(sqlerrm,1,150);
              RAISE exp_reject_record;    
         END;
        --------------------En create successful records in detail table-----------------
        ---------------------Sn Create audit log records---------------------------------
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
                                           v_hash_pan,--prm_pan_code, 
                                           'Hotlist and Reissue',
                                           v_txn_code,
                                           v_del_channel,
                                           0,
                                           'HOST',
                                           'S', 
                                           prm_lupduser, 
                                           sysdate,
                                           'Successful',
                                           v_reasondesc,
                                           prm_remark,
                                           'S',
                                          v_hash_new_pan,-- prm_newpan,
                                          v_encr_pan,
                                          v_encr_new_pan
                                          );    
          
          EXCEPTION
            WHEN OTHERS THEN
            v_errmsg := 'Error while creating record in audit table ' || substr(sqlerrm,1,150);
            RAISE exp_reject_record;
          END;
        -----------------------En Create audit log records------------------
      END IF;
    END IF;
    -------------Sn to hotlist reissue for Debit card-----------------------
  ELSE
        v_errmsg := 'Not a valid product category for hotlist reissue';
        RAISE exp_reject_record;
  END IF;   
EXCEPTION                                       --<< main exception >>--
WHEN exp_reject_record THEN
ROLLBACK TO v_hotreissuesavepoint;
sp_hotreissue_support_log(
                           prm_instcode,  
                           prm_pan_code  ,
                           NULL ,
                           prm_remark  ,
                           prm_new_dispname,
                           'N',  
                           'E', 
                           v_errmsg,
                           'S' ,
                           prm_lupduser  ,
                           SYSDATE  ,
                           'Hotlist and Reissue', 
                           v_txn_code  ,
                           v_del_channel ,
                           0 ,
                           'HOST'  ,
                           v_reasondesc,  
                           'S', 
                           prm_errmsg   
                          );
IF prm_errmsg <> 'OK' THEN
   RETURN;
ELSE
    prm_errmsg := v_errmsg;
END IF;
WHEN OTHERS THEN
v_errmsg := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
ROLLBACK TO v_hotreissuesavepoint;
sp_hotreissue_support_log(
                           prm_instcode,  
                           prm_pan_code  ,
                           NULL ,
                           prm_remark  ,
                           prm_new_dispname,
                           'N',  
                           'E', 
                           v_errmsg,
                           'S' ,
                           prm_lupduser  ,
                           SYSDATE  ,
                           'Hotlist and Reissue', 
                           v_txn_code  ,
                           v_del_channel ,
                           0 ,
                           'HOST'  ,
                           v_reasondesc,  
                           'S', 
                           prm_errmsg   
                          );
IF prm_errmsg <> 'OK' THEN
   RETURN;
ELSE
    prm_errmsg := v_errmsg;
END IF;
END;    
--<< main begin end >>--
/


