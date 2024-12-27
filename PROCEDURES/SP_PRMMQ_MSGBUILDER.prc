CREATE OR REPLACE PROCEDURE VMSCMS.sp_prmmq_msgbuilder(p_inst_code          in number,
                                   p_mbr_numb           in varchar2,
                                   p_card_no            in varchar2,
                                   p_bussinessdate      in varchar2,
                                   p_rrn                in varchar2,
                                   p_business_time      in varchar2,
                                   p_auth_id            out varchar2,
                                   p_ledger_bal         out varchar2,
                                   p_acct_bal           out varchar2,
                                   p_active_date        out varchar2,
                                   p_expiry_date        out varchar2,
                                   p_last_load_date     out varchar2,
                                   p_cust_code          out varchar2,
                                   p_cam_add_one        out varchar2,
                                   p_cam_add_two        out varchar2,
                                   p_cam_city_name      out varchar2,
                                   p_cam_state_switch   out varchar2,
                                   p_cam_cntry_code     out varchar2,
                                   p_cam_pin_code       out varchar2,
                                   p_cam_phone_one      out varchar2,
                                   p_cam_mobl_one       out varchar2,
                                   p_cam_email          out varchar2,
                                   p_ccm_first_name     out varchar2,
                                   p_ccm_ssn            out varchar2,
                                   p_ccm_salut_code     out varchar2,
                                   p_ccm_birth_date     out varchar2,
                                   p_carp_card_stat     out varchar2,
                                   p_addr_verify_result out varchar2,
                                   p_pin_signature      out varchar2,
                                   p_auth_unauth        out varchar2,
                                   p_acct_no            out varchar2,
                                   p_trantype           out varchar2,
                                   p_card_gen_date      out varchar2,
                                   p_pin_chng_date      out varchar2,
                                   p_other_id           out varchar2 , --added for fss-1692 on 10/06/14
                                   p_card_id            out varchar2,
                                   p_err_msg            out varchar2,
                                   p_serial_no          out varchar2,
                                   p_delivery_channel   in  varchar2 default null, -- added for VMS-7639
                                   p_txn_code           in  varchar2 default null) -- added for VMS-7639
                                   is

/*************************************************
* Created Date     :  21-June-2011
* Created By       :  Srinivasu
* PURPOSE          :  For PRM Message Queue 
* Modified By      :  Narayanan
* Modified Date    :  05-02-2013
* Modified Reason  :  To get the card gen date and pin change date
* Reviewer         :  B.Besky Anand.
* Reviewed Date    :  18-07-2012
* Build Number     :  CMS3.5.1_RI0012_B0015 
      
* Modified By      :  Ramesh
* Modified Date    :  10/Jun/2014
* Modified Reason  :  FSS-1692 :  We need to perform changes in PRM messages to send SSN in USER.GOVT-ID field. USER.SEC-GOVT-ID field have other id (driver license / passport number&) if the customer dont have SSN
* Build Number     :  CMS3.5.1_RI0027.1.8_B0001  
      
* Modified By      :  Ramesh
* Modified Date    :  12/Jun/2014
* Modified Reason  :  Defect id :15129
* Reviewer         :  spankaj
* Build Number     :  CMS3.5.1_RI0027.1.8_B0002    

* Modified By      :  Saravanakumar
* Modified Date    :  26-Sep-2014
* Modified Reason  :  Performance changes
* Reviewer         :  
* Build Number     :  

* Modified by       : Abdul Hameed M.A
* Modified for      : Need to send card id instead of card no
* Modified Date     : 13-Oct-2015
* Reviewer          : Spankaj
* Build Number      : VMSGPRHOSTCSD_3.1.2

* Modified by       : Abdul Hameed M.A
* Modified for      : Error message should be returned
* Modified Date     : 22-Feb-2016
* Reviewer          : Spankaj
* Build Number      : VMSGPRHOSTCSD_3.2.5

* Modified by       :Siva kumar 
* Modified Date    : 22-Mar-16
* Modified For     : MVHOST-1323
* Reviewer         : Saravanankumar/Pankaj
* Build Number     : VMSGPRHOSTCSD_4.0_B006

* Modified by       :Saravanakumar 
* Modified Date    : 08-Aug-16
* Modified For     : 
* Reviewer         : Pankaj
* Build Number     : VMSGPRHOSTCSD_4.7_B001

      * Modified by       :Siva kumar 
       * Modified Date    : 23-11-2017
       * Modified For     : VMS-37
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_17.11

       * Modified by       :Vini
       * Modified Date    : 10-Jan-2018
       * Modified For     : VMS-162
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_17.12.1
       
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01   
*************************************************/
    v_hash_pan cms_appl_pan.cap_pan_code%type;
    v_encr_pan cms_appl_pan.cap_pan_code_encr%type;
    v_err_msg  varchar2(900);
    exp_reject_record exception;
    v_ledgerbal          cms_acct_mast.cam_ledger_bal%type;
    v_acctbal            cms_acct_mast.cam_acct_bal%type;
    v_activedate         varchar2(10);
    v_cardgendate        varchar2(10); --to get the card gen date and pin change date
    v_pinchngdate        varchar2(10); --to get the card gen date and pin change date
 --   prm_errmsg           cms_transaction_log_dtl.ctd_process_msg%type;
    v_lastloaddate       varchar2(10);
    v_tranauthid         transactionlog.auth_id%type;
    v_expiry_date        varchar2(10);
    v_auth_id            transactionlog.auth_id%type;
    v_addr_verify_result transactionlog.addr_verify_response%type;
    v_pin_signature      transactionlog.pos_verification%type;
    v_auth_unauth        varchar2(1);
    v_acct_no            transactionlog.customer_acct_no%type;
    v_cust_code          cms_cust_mast.ccm_cust_code%type;
    v_cam_add_one        cms_addr_mast.cam_add_one%type;
    v_cam_add_two        cms_addr_mast.cam_add_two%type;
    v_cam_city_name      cms_addr_mast.cam_city_name%type;
    v_cam_state_switch   cms_addr_mast.cam_state_switch%type;
    v_cam_cntry_code     cms_addr_mast.cam_cntry_code%type;
    v_cam_pin_code       cms_addr_mast.cam_pin_code%type;
    v_cam_phone_one      cms_addr_mast.cam_phone_one%type;
    v_cam_mobl_one       cms_addr_mast.cam_mobl_one%type;
    v_cam_email          cms_addr_mast.cam_email%type;
    v_ccm_first_name     cms_cust_mast.ccm_first_name%type;
    v_ccm_ssn            cms_cust_mast.ccm_ssn%type;
    v_ccm_salut_code     cms_cust_mast.ccm_salut_code%type;
    v_ccm_birth_date     varchar2(30);
    v_carp_card_stat     cms_appl_pan.cap_card_stat%type;
    v_other_id     cms_caf_info_entry.cci_id_number%type;
    v_id_type      cms_cust_mast.ccm_id_type%type; --added for defect id 15129 on 12/06/14
    --SN Added by Saravanakumar on 18-Sep-2014
    v_delivery_channel  transactionlog.delivery_channel%type; 
    V_Txn_Code          Transactionlog.Txn_Code%Type;  
    v_serial_number     cms_appl_pan.cap_serial_number%Type;
    v_prod_code         cms_appl_pan.cap_prod_code%TYPE;
    v_card_type         cms_appl_pan.cap_card_type%TYPE;
    V_ENCRYPT_ENABLE    CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
	
	v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
    
    --v_cnt               number;
    --En Added by Saravanakumar on 18-Sep-2014
begin
v_err_msg:='OK';
    --Gethash is used to hash the original Pan no
    begin
        v_hash_pan := gethash(p_card_no);
    exception
        when others then
            v_err_msg := 'Error while converting pan ' || substr(sqlerrm, 1, 200);
            raise exp_reject_record;
    end;
      
    --Fn_Emaps_Main is used for Encrypt the original Pan no
    begin
        v_encr_pan := fn_emaps_main(p_card_no);
    exception
        when others then
            v_err_msg := 'Error while converting pan ' || substr(sqlerrm, 1, 200);
            raise exp_reject_record;
    end;
    
    
--    BEGIN   
--      SELECT cap_prod_code, cap_card_type
--        INTO v_prod_code, v_card_type
--        FROM cms_appl_pan
--       WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
--     EXCEPTION
--      WHEN NO_DATA_FOUND
--      THEN
--         v_err_msg := 'PAN details not available in CMS_APPL_PAN';
--         RAISE exp_reject_record;
--      WHEN OTHERS
--      THEN
--         v_err_msg :=
--               'Error while fetching data from pan master '
--            || SUBSTR (SQLERRM, 1, 200);
--         RAISE exp_reject_record;
--      END;
     
      
    
    
    begin
        select cam_ledger_bal,
            cam_acct_bal,
            to_char(cap_active_date, 'yyyymmdd'),
            to_char(cap_expry_date, 'mmyy'),
            cap_cust_code,
            cap_card_stat,
            to_char(cap_pangen_date, 'yyyymmdd'), --to get the card gen date and pin change date
            to_char(cap_pingen_date, 'yyyymmdd'), --to get the card gen date and pin change date
            CAP_CARD_ID,
            cap_serial_number, cap_prod_code,cap_card_type
        into v_ledgerbal,
            v_acctbal,
            v_activedate,
            v_expiry_date,
            v_cust_code,
            v_carp_card_stat,
            v_cardgendate, --to get the card gen date and pin change date
        v_pinchngdate --to get the card gen date and pin change date      
        ,p_card_id,v_serial_number,v_prod_code, v_card_type
        from cms_appl_pan cap, cms_acct_mast cam
        where cap.cap_pan_code = v_hash_pan and
        cap.cap_mbr_numb = p_mbr_numb and cap_inst_code = p_inst_code and
        cap.cap_acct_no = cam.cam_acct_no and
        cap.cap_inst_code = cam.cam_inst_code and
        cap_acct_id = cam_acct_id;
    exception
        when others then
            v_err_msg := 'Error while while selecting from CMS_APPL_PAN, CMS_ACCT_MAST ' || substr(sqlerrm, 1, 200);
            raise exp_reject_record;
    end;
    
    --Sn check if Encrypt Enabled
      BEGIN
       SELECT  CPC_ENCRYPT_ENABLE
         INTO  V_ENCRYPT_ENABLE
         FROM  CMS_PROD_CATTYPE
        WHERE CPC_INST_CODE = P_INST_CODE 
          AND CPC_PROD_CODE = V_PROD_CODE
          AND CPC_CARD_TYPE = V_CARD_TYPE;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_err_msg   := 'Invalid Prod Code Card Type ' || V_PROD_CODE || ' ' || V_CARD_TYPE;
            RAISE exp_reject_record;
        WHEN OTHERS THEN
            v_err_msg   := 'Problem while selecting product category details' || SUBSTR(SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
    --En check if Encrypt Enabled     
  
    BEGIN
	
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_bussinessdate), 1, 8), 'yyyymmdd');


IF p_delivery_channel is null THEN --VMS-7639
    IF (v_Retdate>v_Retperiod)
        THEN
            select auth_id,
                addr_verify_response,
                decode(pos_verification, 'P', 1, 'S', 0, 0),
                decode(msgtype,
                '9220',
                'U',
                '9221',
                'U',
                '1220',
                'U',
                '1221',
                'U',
                'A'),
                customer_acct_no,
                --SN Added by Saravanakumar on 18-Sep-2014
                delivery_channel, 
                txn_code
                --EN Added by Saravanakumar on 18-Sep-2014
            into v_auth_id,
                v_addr_verify_result,
                v_pin_signature,
                v_auth_unauth,
                v_acct_no,
                v_delivery_channel, 
                v_txn_code   
            from transactionlog
            where rrn = p_rrn and customer_card_no = v_hash_pan and
            business_date = p_bussinessdate and
            business_time = p_business_time;
    ELSE
    
    select auth_id,
                addr_verify_response,
                decode(pos_verification, 'P', 1, 'S', 0, 0),
                decode(msgtype,
                '9220',
                'U',
                '9221',
                'U',
                '1220',
                'U',
                '1221',
                'U',
                'A'),
                customer_acct_no,
                --SN Added by Saravanakumar on 18-Sep-2014
                delivery_channel, 
                txn_code
                --EN Added by Saravanakumar on 18-Sep-2014
            into v_auth_id,
                v_addr_verify_result,
                v_pin_signature,
                v_auth_unauth,
                v_acct_no,
                v_delivery_channel, 
                v_txn_code   
            from 
    VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
            where rrn = p_rrn and customer_card_no = v_hash_pan and
            business_date = p_bussinessdate and
            business_time = p_business_time;
    END IF;
END IF;
    exception
        when others then
            v_err_msg := 'Error while selecting from TRANSACTIONLOG' || substr(sqlerrm, 1, 200);
            raise exp_reject_record;
    end;
        
    begin
        select decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_add_one),cam_add_one),
        decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_add_two),cam_add_two),
        decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_city_name),cam_city_name),
        cam_state_switch,
        cam_cntry_code,
        decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_pin_code),cam_pin_code),
        nvl(decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_phone_one),cam_phone_one), ''),       
        nvl(decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_mobl_one),cam_mobl_one), ''),        
        decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_email),cam_email),
        decode(v_encrypt_enable,'Y',fn_dmaps_main(ccm_first_name),ccm_first_name),
        NVL(FN_DMAPS_MAIN(ccm_ssn_ENCR),CCM_SSN),
        ccm_salut_code,
        to_char(ccm_birth_date, 'YYYYMMDD'),
        ccm_id_type --added for defect id 15129 on 12/06/14
        into v_cam_add_one,
        v_cam_add_two,
        v_cam_city_name,
        v_cam_state_switch,
        v_cam_cntry_code,
        v_cam_pin_code,
        v_cam_phone_one,
        v_cam_mobl_one,
        v_cam_email,
        v_ccm_first_name,
        v_ccm_ssn,
        v_ccm_salut_code,
        v_ccm_birth_date,
        v_id_type --added for defect id 15129 on 12/06/14
        from cms_addr_mast cam, cms_cust_mast ccm
        where ccm.ccm_cust_code = cam.cam_cust_code and
        ccm.ccm_inst_code = cam.cam_inst_code and
        ccm.ccm_cust_code = v_cust_code and
        ccm_inst_code = p_inst_code and cam_addr_flag = 'P';
    exception
        when others then
            v_err_msg := 'Error while while selecting from CMS_ADDR_MAST , CMS_CUST_MAST' || substr(sqlerrm, 1, 200);
            raise exp_reject_record;
    end;
        
    begin
        select decode(ctm_credit_debit_flag, 'DR', 'D', 'CR', 'C', 'N')
        into p_trantype
        from cms_transaction_mast
        where ctm_delivery_channel=nvl(p_delivery_channel,v_delivery_channel)
        and ctm_tran_code=nvl(p_txn_code,v_txn_code) --Modified by Saravanakumar on 18-Sep-2014
        /*(select delivery_channel, txn_code
        from transactionlog
        where rrn = p_rrn and customer_card_no = v_hash_pan and
        business_date = p_bussinessdate and
        business_time = p_business_time) */
        and ctm_inst_code = p_inst_code;
    exception
        when others then
            v_err_msg := 'Error while selecting trantype from CMS_TRANSACTION_MAST' || substr(sqlerrm, 1, 200);
            raise exp_reject_record;
    end;
    
    --SN Added by Saravanakumar on 18-Sep-2014
    
   /* begin
        select count(1) into v_cnt
        from cms_prm_msgqueue_spec where cpm_field_name='RC-DAT'
        and cpm_delivery_channel=v_delivery_channel
        and cpm_transaction_code=v_txn_code
        and cpm_inst_code=p_inst_code;
    exception
        when others then
            v_err_msg := 'Error while selecting count' || substr(sqlerrm, 1, 200);
            raise exp_reject_record;
    end;
    
    if v_cnt <> 0 then

        begin
            select max(business_date) into v_lastloaddate
            from transactionlog
            where instcode=p_inst_code and
            ((delivery_channel = '08' and txn_code = '22') or
            (delivery_channel = '07' and txn_code = '08') or
            (delivery_channel = '10' and txn_code = '08') or
            (delivery_channel = '04' and txn_code in ('80', '82', '85', '88')) or
            (delivery_channel = '11' and txn_code in ('22', '32'))) and
            response_code = '00' and customer_card_no = v_hash_pan;
        exception
            when others then
                v_err_msg := 'Error while selecting load date ' || substr(sqlerrm, 1, 200);
                raise exp_reject_record;
        end;
                
    end if;*/
    --EN Added by Saravanakumar on 18-Sep-2014
    
    
    --St --Added for FSS-1692 on 10/06/14
    if v_id_type <> 'SSN' then  --Code modified for defect id 15129 on 12/06/14
        v_other_id := v_ccm_ssn;
        v_ccm_ssn := '';
    end if;
    --END --Added for FSS-1692 on 10/06/14
  
    p_auth_id            := v_auth_id;
    p_ledger_bal         := v_ledgerbal;
    p_acct_bal           := v_acctbal;
    p_active_date        := v_activedate;
    p_expiry_date        := v_expiry_date;
    p_last_load_date     := v_lastloaddate;
    p_cust_code          := v_cust_code;
    p_cam_add_one        := v_cam_add_one;
    p_cam_add_two        := v_cam_add_two;
    p_cam_city_name      := v_cam_city_name;
    p_cam_state_switch   := v_cam_state_switch;
    p_cam_cntry_code     := v_cam_cntry_code;
    p_cam_pin_code       := v_cam_pin_code;
    p_cam_phone_one      := v_cam_phone_one;
    p_cam_mobl_one       := v_cam_mobl_one;
    p_cam_email          := v_cam_email;
    p_ccm_first_name     := v_ccm_first_name;
    p_ccm_ssn            := v_ccm_ssn;
    p_ccm_salut_code     := v_ccm_salut_code;
    p_ccm_birth_date     := v_ccm_birth_date;
    p_carp_card_stat     := v_carp_card_stat;
    p_addr_verify_result := v_addr_verify_result;
    p_pin_signature      := v_pin_signature;
    p_auth_unauth        := v_auth_unauth;
    p_acct_no            := v_acct_no;
    p_card_gen_date      := v_cardgendate; --to get the card gen date and pin change date
    p_pin_chng_date      := v_pinchngdate; --to get the card gen date and pin change date
    p_other_id           := v_other_id; --added for fss-1692 on 10/06/14
    p_serial_no          :=v_serial_number;
    p_err_msg           :=v_err_msg;
exception
    when exp_reject_record then
        p_err_msg := 'Error from EXP_REJECT_RECORD ' || v_err_msg;--substr(sqlerrm, 1, 200);
    when others then
        p_err_msg := 'Error from others main exception handler' || substr(sqlerrm, 1, 200);
end;
/
show error ;
