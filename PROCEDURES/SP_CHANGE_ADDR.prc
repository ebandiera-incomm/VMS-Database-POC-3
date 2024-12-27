CREATE OR REPLACE PROCEDURE VMSCMS.sp_change_addr(
   prm_instcode   	  IN     NUMBER,
   prm_pancode    	  IN     VARCHAR2,
   prm_remark     	  IN     VARCHAR2,
   prm_addrcode   	  IN     NUMBER,
   prm_rsncode    	  IN     NUMBER,
   prm_CustomerCode   IN 	 NUMBER,
   prm_AddressLine1   IN 	 VARCHAR2,
   prm_AddressLine2   IN 	 VARCHAR2,
   prm_AddressLine3   IN 	 VARCHAR2,
   prm_PinCode 		  IN 	 VARCHAR2,
   prm_Phone1 		  IN 	 VARCHAR2,
   prm_Phone2 		  IN 	 VARCHAR2,
   prm_CountryCode 	  IN 	 VARCHAR2,
   prm_CityName 	  IN 	 VARCHAR2,
   prm_StateName 	  IN 	 VARCHAR2,
   prm_Fax1 		  IN 	 VARCHAR2,
   prm_AddressFlag 	  IN 	 VARCHAR2,
   prm_source         IN     VARCHAR2,
   prm_workmode   	  IN     NUMBER,
   prm_lupduser   	  IN     NUMBER,
   prm_newAddrCode 	  OUT    NUMBER,
   prm_errmsg           OUT    VARCHAR2
   )
as
  v_errmsg varchar2(500):='OK';
  v_mbrnumb CMS_APPL_PAN.cap_mbr_numb%type;
  v_cap_prod_catg    CMS_APPL_PAN.cap_prod_catg%type;
  exp_reject_record    EXCEPTION;
  v_savepoint        NUMBER    DEFAULT 0;
  v_tran_code            VARCHAR2(2);
   v_tran_mode            VARCHAR2(1);
   v_tran_type            VARCHAR2(1);
   v_delv_chnl            VARCHAR2(2);
   v_reasondesc        cms_spprt_reasons.csr_reasondesc%TYPE;
   
    v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
 
begin--<< main begin starts >>--
  v_savepoint := v_savepoint + 1;
    SAVEPOINT v_savepoint;
  prm_errmsg:='OK';
  ------Sn to get transaction code,delivery channel-----------------
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
          AND cfm_func_code   = 'ADDR';
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_errmsg := 'Support function reissue not defined in master ' ;
          raise exp_reject_record;
        WHEN TOO_MANY_ROWS THEN
          v_errmsg := 'More than one record found in master for reissue support func ' ;
          raise exp_reject_record;
        WHEN OTHERS THEN
          v_errmsg := 'Error while selecting reissue fun detail ' || SUBSTR (SQLERRM, 1, 200);
          raise exp_reject_record;
        END;
 ------En to get transaction code,delivery channel-----------------
 
        ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_reasondesc
                 INTO  v_reasondesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'ADDR'
                  AND csr_spprt_rsncode=prm_rsncode 
                  AND csr_inst_code = prm_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Address change reason code not present in master';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

              ------------------------------En get reason code from support reason master-------
              
--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(prm_pancode);
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
    begin 
      select cap_prod_catg
      into v_cap_prod_catg
      from
      cms_appl_pan
      where cap_pan_code= v_hash_pan--prm_pancode
      and cap_inst_code=prm_instcode;
    exception
    when no_data_found then
      v_errmsg:='Product category not defined in the master';
      raise exp_reject_record;
    when others then 
      v_errmsg:='Error while selecting the product catagory'||substr(SQLERRM,1,300);
      raise exp_reject_record;
    end;
    -- find product catg end;
    
    -- find member number start
    begin
      select cip_param_value 
      into v_mbrnumb 
      from cms_inst_param
      where cip_inst_code = prm_instcode
      and cip_param_key = 'MBR_NUMB';
    exception 
    when no_data_found then
    v_errmsg:='member number not defined in the master';
    raise exp_reject_record;
    when others then
    v_errmsg:='Error while selecting the member number'||substr(SQLERRM,1.300);
    raise exp_reject_record;
    end;
    -- find member number end
    
    if v_cap_prod_catg='P' then
    --start addr change for prepaid card
      null;
    --end addr change for prepaid card
    elsif v_cap_prod_catg in('D','A') then
    --start addr change for debit card
    Sp_Change_Addr_Debit (
                           prm_instcode,         
                           prm_pancode ,         
                           v_mbrnumb,          
                           prm_remark,           
                           prm_addrcode,         
                           prm_rsncode,          
                           prm_CustomerCode,   
                           prm_AddressLine1,   
                           prm_AddressLine2,   
                           prm_AddressLine3,   
                           prm_PinCode,           
                           prm_Phone1,           
                           prm_Phone2,           
                           prm_CountryCode,       
                           prm_CityName,       
                           prm_StateName,       
                           prm_Fax1,           
                           prm_AddressFlag,       
                           prm_lupduser,         
                           prm_workmode,         
                           prm_newAddrCode,       
                           v_errmsg
                           );
        if v_errmsg <>'OK' then
        raise exp_reject_record;
      else
        --start create succesfull records
        begin
          INSERT INTO CMS_ADDRCHNG_DETAIL
                        (crd_inst_code, crd_card_no, crd_file_name,
                         crd_remarks, crd_msg24_flag, crd_old_addr,
                         crd_new_addr, crd_process_flag, crd_process_msg,
                         crd_process_mode, crd_ins_user, crd_ins_date,
                         crd_lupd_user, crd_lupd_date
                        )
                 VALUES (prm_instcode, prm_instcode, null,
                         prm_remark, 'N', prm_addrcode,
                         prm_newAddrCode, 'S', 'Successful',
                         'S', prm_lupduser, SYSDATE,
                         prm_lupduser, SYSDATE
                        );
          exception
          when others then
            prm_errmsg := 'Error while creating record in Addr change detail table ' || substr(sqlerrm,1,200);
          return;    
          end; 
        --end create succesfull records
        --start create audit logs records
        begin
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
                    -- prm_pancode
          v_hash_pan, 
                     'Address Change',
                     v_tran_code,
                     v_delv_chnl,
                     0,
                     prm_source,
                     'S', 
                     prm_lupduser, 
                     sysdate,
                     'Successful',
                     v_reasondesc,
                     prm_remark,
                     'S',
           v_encr_pan
           );
        exception
        when others then
          prm_errmsg := 'Error while creating record in Audit Log table ' || substr(sqlerrm,1,150);
          return;    
        end;
        --end create audit logs records      
       end if;
      --end of block pan for debit card
    else
      v_errmsg:='Not a valid product category for address change';
      RAISE exp_reject_record;
    end if;
exception --main exception--
  when exp_reject_record then
  ROLLBACK TO v_savepoint;
  sp_addrchnge_support_log(
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
                          'Address Change',
                          v_tran_code,
                          v_delv_chnl,
                          0,
                          prm_source,
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
  sp_addrchnge_support_log(
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
                          'Address Change',
                          v_tran_code,
                          v_delv_chnl,
                          0,
                          prm_source,
                          v_reasondesc,
                          'S',
                          prm_errmsg
                          );
      IF prm_errmsg <> 'OK' THEN
        RETURN;
      ELSE
        prm_errmsg := v_errmsg;
      END IF;
end;--<< main end >>--
/


show error