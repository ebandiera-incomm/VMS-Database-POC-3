CREATE OR REPLACE PROCEDURE VMSCMS.sp_chnge_crdstat
(
	 prm_instcode   IN       NUMBER,
	 prm_pancode    IN       VARCHAR2,
	 --prm_mbrnumb    IN       VARCHAR2,
	 prm_remark     IN       VARCHAR2,
   prm_rsncode    IN       NUMBER,
   prm_workmode   IN       NUMBER,    -- to be commented for production set up
   prm_cardstat   IN       VARCHAR2,
   prm_source     IN       VARCHAR2,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
AS

   /**********************************************************************************************
  
  * Modified by          : MageshKumar S.
  * Modified Date        : 25-July-14    
  * Modified For         : FWR-48
  * Modified reason      : GL Mapping removal changes
  * Reviewer             : Spankaj
  * Build Number         : RI0027.3.1_B0001
**************************************************************************************************/
   v_errmsg            varchar2(500):='OK';                          
   v_mbrnumb           cms_appl_pan.cap_mbr_numb%TYPE;
   v_cap_prod_catg     cms_appl_pan.cap_prod_catg%TYPE;
   v_cap_card_stat     cms_appl_pan.cap_card_stat%TYPE;
   exp_reject_record   EXCEPTION;
   v_savepoint         NUMBER                                  DEFAULT 0;
   v_txn_code          VARCHAR2 (2) default 'SC'; --Modified for fwr-48
  -- v_txn_type          VARCHAR2 (2); --commented for fwr-48
  -- v_txn_mode          VARCHAR2 (2); --commented for fwr-48
   v_del_channel       VARCHAR2 (2) default '05'; --Modified for fwr-48
   v_reasondesc        cms_spprt_reasons.csr_reasondesc%TYPE;
 v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;

  begin                --<< main begin start>>--
    v_savepoint := v_savepoint + 1;
    SAVEPOINT v_savepoint;
    v_errmsg  := 'OK';
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


 ----------------------------------find product catg start---------------------------
    begin
          select cap_prod_catg,cap_card_stat
          into v_cap_prod_catg,v_cap_card_stat
          from
          cms_appl_pan
          where cap_pan_code=v_hash_pan-- prm_pancode
          and cap_inst_code=prm_instcode;
    exception
    when no_data_found then
          v_errmsg:='Product category not defined in the master';
          raise exp_reject_record;
    when others then
          v_errmsg:='Error while selecting the product catagory'||substr(SQLERRM,1,300);
          raise exp_reject_record;
    end;
  ----------------------------------find product catg end---------------------------

   -------------------------------- Sn get Function Master----------------------------
   
   --Sn commented for fwr-48
  /* BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM cms_func_mast
       WHERE cfm_func_code = 'CHGSTA' AND cfm_inst_code = prm_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                   'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;*/
  --En commented for fwr-48

   ------------------------------ En get Function Master----------------------------

  ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_reasondesc
                 INTO  v_reasondesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'CHGSTA'
                  AND csr_spprt_rsncode=prm_rsncode
                  AND csr_inst_code = prm_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Change status reason code not present in master';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
------------------------------En get reason code from support reason master-------

  -------------------------------find member number start--------------------------
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
   ------------------------------find member number end------------------------------
   IF v_cap_card_stat NOT IN ('1', '4','0') THEN
      v_errmsg := 'Card is not available as open or restricted or blocked';
      raise exp_reject_record;
   END IF;

  -- if v_cap_prod_catg='P' then
    -----------------start change stat for prepaid card---------------------
    Sp_Chnge_Crdstat_Debit(prm_instcode,
                         prm_pancode,
                         v_mbrnumb,
                         prm_remark,
                         prm_rsncode,
                         prm_workmode,
                         prm_cardstat,
                         prm_lupduser,
                         v_errmsg
                          );

    -----------------end change stat for prepaid card-----------------------
   /*elsif v_cap_prod_catg in('D','A') then
    -------------------start change stat for debit card-----------------------
    Sp_Chnge_Crdstat_Debit(prm_instcode,
                         prm_pancode,
                         v_mbrnumb,
                         prm_remark,
                         prm_rsncode,
                         prm_workmode,
                         prm_cardstat,
                         prm_lupduser,
                         v_errmsg
                          );

   else
      v_errmsg:='Not a valid product category to Change card status process';
      RAISE exp_reject_record;
   end if;*/
                          

    if v_errmsg <>'OK' then
        raise exp_reject_record;
    else
        -------------------------start create successfull records-----------------------
        BEGIN
            insert into cms_change_cardstat_detail(
                                              CCD_INST_CODE,
                                              CCD_CARD_NO,
                                              CCD_FILE_NAME,
                                              CCD_OLD_CARDSTAT,
                                              CCD_NEW_CARDSTAT,
                                              CCD_REMARKS,
                                              CCD_MSG24_FLAG,
                                              CCD_PROCESS_FLAG,
                                              CCD_PROCESS_MSG,
                                              CCD_PROCESS_MODE,
                                              CCD_INS_USER,
                                              CCD_INS_DATE,
                                              CCD_LUPD_USER,
                                              CCD_LUPD_DATE,CCD_CARD_NO_encr
                                            )
                                      VALUES(
                                              prm_instcode,
                                              --prm_pancode
                                              v_hash_pan,
                                              NULL,
                                              v_cap_card_stat,
                                              prm_cardstat,
                                              prm_remark,
                                              'N',
                                              'S',
                                              'Successful',
                                              'S',
                                              prm_lupduser,
                                              SYSDATE,
                                              prm_lupduser,
                                              SYSDATE        ,
                                              v_encr_pan
                                        );
        EXCEPTION WHEN OTHERS THEN
            v_errmsg := 'Error while creating record in card stat change detail table ' || substr(sqlerrm,1,150);
            raise exp_reject_record;
        END;
        ------------------------end create succesful records--------------------------

        --------------------------start create audit logs records-----------------------
        BEGIN
              insert into PROCESS_AUDIT_LOG(
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
                                      (
                                       prm_instcode,
                                      -- prm_pancode
                                      v_hash_pan,
                                       'Change status',
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
        EXCEPTION
        when others then
              v_errmsg := 'Error while creating record in Audit Log table ' || substr(sqlerrm,1,150);
              raise exp_reject_record;
        END;
        ---------------------------end create audit logs records------------------------------

    end if;
    -----------------end change stat for debit card--------------------

  EXCEPTION            --<< main exception >>--
  when exp_reject_record then
  ROLLBACK TO v_savepoint;
  sp_chnge_crdstat_support_log(
                          prm_instcode,
                          prm_pancode,
                          NULL,
                          v_cap_card_stat,
                          prm_cardstat,
                          prm_remark,
                          'N',
                          'E',
                          v_errmsg,
                          'S',
                          prm_lupduser,
                          SYSDATE,
                          'Change status',
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
   v_errmsg := 'Error while processing change card status ' || substr(sqlerrm,1,200);
   ROLLBACK TO v_savepoint;
   sp_chnge_crdstat_support_log(
                          prm_instcode,
                          prm_pancode,
                          NULL,
                          v_cap_card_stat,
                          prm_cardstat,
                          prm_remark,
                          'N',
                          'E',
                          v_errmsg,
                          'S',
                          prm_lupduser,
                          SYSDATE,
                          'Change status',
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
  end;               --<< main begin end>>--
/
SHOW ERROR