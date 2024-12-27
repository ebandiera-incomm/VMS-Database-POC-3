CREATE OR REPLACE PROCEDURE VMSCMS.sp_regen_pin
(	prm_instcode		IN	NUMBER	,
	prm_pancode		IN	VARCHAR2	,
	prm_oldpinoff		IN	VARCHAR2	,
	prm_oldpindate		IN	DATE		,
	prm_remark		IN	VARCHAR2	,
	prm_rsncode		IN	NUMBER	,
	prm_terminalid IN VARCHAR2,
	prm_workmode		IN	NUMBER ,
    prm_pinprocess IN VARCHAR2,
    prm_lupduser		IN	NUMBER	,
	prm_errmsg		OUT	VARCHAR2
  )
  as
  v_errmsg varchar2(500);
  v_mbrnumb CMS_APPL_PAN.cap_mbr_numb%type;
  v_cap_prod_catg    CMS_APPL_PAN.cap_prod_catg%type;
   v_txn_code               VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_txn_mode               VARCHAR2 (2);
   v_del_channel            VARCHAR2 (2);
  exp_reject_record            EXCEPTION;
  v_savepoint                    NUMBER    DEFAULT 0;
  v_reasondesc              cms_spprt_reasons.csr_reasondesc%TYPE;
   v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
     v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
  begin --<<main begin start >>--
  v_savepoint := v_savepoint + 1;
    SAVEPOINT v_savepoint;
  prm_errmsg:='OK';
  v_errmsg:='OK';
  
 --SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(    prm_pancode    );
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN CREATE HASH PAN


--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN create encr pan

    -- find product catg start
    BEGIN 
          select cap_prod_catg
          into v_cap_prod_catg
          from
          cms_appl_pan
          where cap_pan_code  = v_hash_pan--prm_pancode
          and cap_inst_code   = prm_instcode;
    EXCEPTION
    
    when no_data_found then
          v_errmsg:='Product category not defined in the master';
          raise exp_reject_record;
          
    when others then 
    
          v_errmsg:='Error while selecting the product catagory'||substr(SQLERRM,1,300);
          raise exp_reject_record;
    END;
    -- find product catg end;
  
  
------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_reasondesc
                 INTO  v_reasondesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'REPIN'
                  AND csr_spprt_rsncode=prm_rsncode 
                  AND csr_inst_code = prm_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Regen pin reason code not present in master';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
------------------------------En get reason code from support reason master-------

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
       WHERE cfm_func_code = 'REPIN'
        AND cfm_inst_code= prm_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
                   'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         RETURN;
   END;
       
    -- find member number start
    BEGIN
      select cip_param_value 
      into      v_mbrnumb 
      from      cms_inst_param
      where  cip_inst_code = prm_instcode
      and      cip_param_key = 'MBR_NUMB';
      
    EXCEPTION 
      WHEN no_data_found THEN
             v_errmsg:='member number not defined in the master';
           raise exp_reject_record;
      when others then
             v_errmsg:='Error while selecting the member number'||substr(SQLERRM,1.300);
           raise exp_reject_record;
    END;
    -- find member number end
    
    if v_cap_prod_catg='P' then
    --start regen pin for prepaid card
      null;
    --end regen pin for prepaid card
    elsif v_cap_prod_catg in('D','A') then
    --start regen pin for debit card
    sp_regen_pin_debit(
                       prm_instcode,    
                       prm_pancode,      
                       v_mbrnumb,      
                       prm_oldpinoff,    
                       prm_oldpindate,   
                       prm_remark,       
                       prm_rsncode,      
                       prm_workmode,     
                       prm_pinprocess,   
                       prm_lupduser,     
                       v_errmsg 
                      );
     if v_errmsg <>'OK' then
          raise exp_reject_record;
        else
        --start create succesfull records
        BEGIN
          INSERT INTO CMS_REGENPIN_DETAIL
                        (crd_inst_code, crd_card_no, crd_file_name,
                         crd_remarks, crd_msg24_flag, crd_process_flag,
                         crd_process_msg, crd_process_mode, crd_ins_user,
                         crd_ins_date, crd_lupd_user, crd_lupd_date, crd_card_no_encr
                        )
                 VALUES (prm_instcode, --prm_pancode
                 v_hash_pan, null,
                         prm_remark, 'N','S',
                         'Successful', 'S', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE,v_encr_pan
                        );
        EXCEPTION
            WHEN OTHERS THEN
              prm_errmsg := 'Error while creating record in detail table ' || substr(sqlerrm,1,150);
              raise exp_reject_record;
        END;  
        --end create succesfull records
        
        --start create audit logs records
        BEGIN
          insert into PROCESS_AUDIT_LOG
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
            pal_card_no_encr
                    )
                      values    
                    (prm_instcode,
                     --prm_pancode
           v_hash_pan, 
                     'Regenerate Pin',
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
           v_encr_pan
           );
        EXCEPTION
        when others then
          prm_errmsg := 'Error while creating record in detail table ' || substr(sqlerrm,1,150);
          raise exp_reject_record;
        END;
        --end create audit logs records
     end if;
      --end of regen pin for debit card
    else
      v_errmsg:='Not a valid product category for address change';
      RAISE exp_reject_record;
    end if;
    
  exception --main exception--
  when exp_reject_record then
  ROLLBACK TO v_savepoint;
     sp_regenpin_support_log(
             prm_instcode,
             prm_pancode,
             NULL,
             prm_remark,
             'N',
             'E',
             v_errmsg,
             'S',
             prm_lupduser,
             SYSDATE,
           'Regenerate Pin',
             v_txn_code,
               v_del_channel,
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
  when others then
  v_errmsg := ' Error from main ' || substr(sqlerrm,1,200);
  ROLLBACK TO v_savepoint;
  sp_regenpin_support_log(
             prm_instcode,
             prm_pancode,
             NULL,
             prm_remark,
             'N',
             'E',
             v_errmsg,
             'S',
             prm_lupduser,
             SYSDATE,
           'Regenerate Pin',
             v_txn_code,
               v_del_channel,
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
  end ; --<< main begin end >>--
/

SHOW ERRORS
