CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Unblock_Pan
(
   prm_instcode   IN       NUMBER,
   prm_pancode    IN       VARCHAR2,
  -- prm_mbrnumb    IN       VARCHAR2,
   prm_remark     IN       VARCHAR2,
   prm_rsncode    IN       NUMBER,
   prm_workmode   IN       NUMBER,
   prm_terminalid IN       VARCHAR2,
   prm_source     IN       VARCHAR2,
   prm_ipaddr     IN       VARCHAR2,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
as
  v_errmsg varchar2(500);
  v_mbrnumb CMS_APPL_PAN.cap_mbr_numb%type;
  v_cap_prod_catg    CMS_APPL_PAN.cap_prod_catg%type;
  exp_reject_record    EXCEPTION;
  v_savepoint        NUMBER    DEFAULT 0;
  v_txn_code        VARCHAR2 (2);
  v_txn_type        VARCHAR2 (2);
  v_txn_mode        VARCHAR2 (2);
  v_del_channel     VARCHAR2 (2);
  v_reasondesc        cms_spprt_reasons.csr_reasondesc%TYPE;
  v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
  v_cardstat                   CMS_APPL_PAN.cap_card_stat%TYPE;
  v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
  v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
  v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;
  v_expry_date                CMS_APPL_PAN.cap_expry_date%TYPE;


begin --<< main begin start >>--
v_savepoint := v_savepoint + 1;
SAVEPOINT v_savepoint;
prm_errmsg:='OK';

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



  -- find product catg start--
    begin
      select cap_prod_catg,cap_card_stat,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE
      into v_cap_prod_catg,v_cardstat ,v_applcode, v_acctno, v_prodcode
      from
      cms_appl_pan
      where cap_pan_code= v_hash_pan --prm_pancode
      and cap_inst_code=prm_instcode;
    exception
    when no_data_found then
      v_errmsg:='Product category not defined in the master';
      raise exp_reject_record;
    when others then
      v_errmsg:='Error while selecting the product catagory'||substr(SQLERRM,1,300);
      raise exp_reject_record;
    end;
    -- find product catg end--

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
    WHERE cfm_func_code = 'UNBLOKSPRT'
      AND cfm_inst_code= prm_instcode;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg :='Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
    --RAISE exp_loop_reject_record;
    RETURN;
  END;
  ------------------------------ En get Function Master----------------------------

  ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_reasondesc
                 INTO  v_reasondesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'UNBLOKSPRT'
                  AND csr_spprt_rsncode=prm_rsncode
                  AND csr_inst_code = prm_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Unblock reason code not present in master';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
------------------------------En get reason code from support reason master-------

  --------------------------find member number start-------------------------------
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
    -- ----------------------find member number end-------------------------------
        IF v_cardstat <> '0'    --siva Mar 22 2011 card status check
         THEN
            prm_errmsg := 'Card status is not blocked, cannot be UnBlocked';
            RAISE exp_reject_record;
         END IF;
         
    
    if v_cap_prod_catg='P' then
    --start Unblock pan for prepaid card--
    Sp_Unblock_Pan_Debit(
                          prm_instcode,
                          prm_pancode,
                          v_mbrnumb,
                          prm_remark,
                          prm_rsncode,
                          prm_lupduser,
                          prm_workmode,
                          v_errmsg
                        );
    --end block pan for prepaid card--
    elsif v_cap_prod_catg in('D','A') then
    --start Unblock pan for debit card--
    Sp_Unblock_Pan_Debit(
                          prm_instcode,
                          prm_pancode,
                          v_mbrnumb,
                          prm_remark,
                          prm_rsncode,
                          prm_lupduser,
                          prm_workmode,
                          v_errmsg
                        );
      --end of block pan for debit card--
    else
      v_errmsg:='Not a valid product category for address change';
      RAISE exp_reject_record;
    end if;

         if v_errmsg <>'OK' then
            raise exp_reject_record;
        else
        --start create succesfull records--
          begin
            insert into CMS_UNBLOCK_DETAIL(CUD_INST_CODE,CUD_CARD_NO,CUD_FILE_NAME,
                                           CUD_REMARKS,CUD_MSG24_FLAG,CUD_PROCESS_FLAG,
                                           CUD_PROCESS_MSG,CUD_PROCESS_MODE,CUD_INS_USER,
                                           CUD_INS_DATE,CUD_LUPD_USER,CUD_LUPD_DATE,
                                           cud_card_no_encr)
                                    values(prm_instcode, --prm_pancode
                                    v_hash_pan, null,
                                           prm_remark, 'N','S',
                                           'Successful', 'S', prm_lupduser,
                                           SYSDATE, prm_lupduser, SYSDATE,
                                           v_encr_pan
                                           );
          exception
            when others then
              prm_errmsg := 'Error while creating record in UNBLOCK PAN detail table ' || substr(sqlerrm,1,150);
              raise exp_reject_record;
          end;
          --end create succesfull records--
          
                --siva mar 25 2011
        --start for audit log success
      IF v_errmsg = 'Successful'
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
                         v_hash_pan, v_prodcode, 'GROUP HOTLIST',
                         'UPDATE', 'SUCCESS', prm_ipaddr,
                         'CMS_APPL_PAN', '', v_encr_pan,
                         prm_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while inserting records for audit log process'
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
                         v_hash_pan, v_prodcode, 'GROUP HOTLIST',
                         'UPDATE', 'FAILURE', prm_ipaddr,
                         'CMS_APPL_PAN', '', v_encr_pan,
                         prm_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while inserting records for audit log process'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      --end insert audit table
      END IF;

      --end for failure status record
          --siva end mar 25 2011
          
          --start create audit logs records--
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
                     --prm_pancode
           v_hash_pan,
                     'Unblock',
                     v_txn_code,
                     v_del_channel,
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
          raise exp_reject_record;
        end;
        --end create audit logs records--
      end if;
exception --main exception--
when exp_reject_record then
  ROLLBACK TO v_savepoint;
  sp_Unblockpan_support_log(
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
                          'Unblock',
                          v_txn_code,
                          v_del_channel,
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
  sp_Unblockpan_support_log(
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
                          'Unblock',
                          v_txn_code,
                          v_del_channel,
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
end; --<< main begin end >>--
/


SHOW ERRORS