CREATE OR REPLACE PROCEDURE VMSCMS.SP_GETFEE_DETAILS(
   prm_instcode           IN       NUMBER,
   prm_card_no            IN       VARCHAR2,
   prm_mbr_numb           IN       VARCHAR2,
   prm_txn_code           IN       VARCHAR2,
   prm_tran_mode          IN       VARCHAR2,
   prm_delivery_channel   IN       VARCHAR2,
   prm_intl_indicator     IN       VARCHAR2,
   prm_feeamount          OUT      VARCHAR2,
   prm_fee_desc           OUT      VARCHAR2,
   prm_feeflag            OUT      VARCHAR2,
   prm_avail_bal          OUT      VARCHAR2,
   prm_ledger_bal         OUT      VARCHAR2,
   prm_clawback_flag      OUT      VARCHAR2,
   prm_errmsg             OUT      VARCHAR2
)
IS
/**********************************************************************************************
  * VERSION                   :  1.0
  * DATE OF CREATION          :  21/Aug/2012
  * PURPOSE                   : To fetch fee and balance details
  * CREATED BY                : Sagar More
  * MODIFICATION REASON       : Changes were done so that next level will be checked only
                                when fee plan is not attached otherwise message will be returned
                                as 'No Fees Attached' if CSR fee not present  
  * LAST MODIFICATION DONE BY : Sagar M.
  * LAST MODIFICATION DATE    : 22/Sep/2012
  * Build Number              : RI0018
  
  * Modified By               : Santosh K
  * Modified For              : Defect ID : 0011207 :CSR Fee : If we define Reversal Fee and Normal Fee in One Plan, 
                                then system is not calculating the Fee
  * Modified Date             : 11/06/2013 
  * Build Number     :  RI0024.2_B0002
  
  * Modified by       : Abdul Hameed M.A
  * Modified for      : Mantis ID 13641
  * Modified Reason   : Transaction getting failed  when Reversal Fee and Normal Fee in One Plan is configured
  * Modified Date     : 08-Jul-2014
  * Reviewer          : Spankaj
  * Build Number      : RI0027.3_B0003
     
  * Modified by      : MAGESHKUMAR S.
  * Modified Date    : 03-FEB-2015
  * Modified For     : MVHOST-1121(2.4.2.4.1 & 2.4.3.1 integration)
  * Reviewer         : PANKAJ S.
  * Build Number     : RI0027.5_B0006
**************************************************************************************************/
   exp_reject_record   EXCEPTION;
   v_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_errmsg            VARCHAR2 (300);
   v_spnd_acctno       cms_appl_pan.cap_acct_no%TYPE;
   v_acct_balance      cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
   v_feeattach_flag    NUMBER;
   v_fee_code          cms_fee_mast.cfm_fee_code%TYPE;
   v_per_fees          cms_fee_mast.cfm_per_fees%TYPE;
   v_min_fees          cms_fee_mast.cfm_min_fees%TYPE;
   v_feeflag           NUMBER (1);
   v_feeamnt_type      cms_fee_mast.cfm_feeamnt_type%TYPE;
   v_fee_plan          cms_card_excpfee.cce_fee_plan%TYPE;
   v_tran_fee          NUMBER;
   v_crgl_catg         cms_card_excpfee.cce_crgl_catg%TYPE;
   v_crgl_code         cms_card_excpfee.cce_crgl_code%TYPE;
   v_crsubgl_code      cms_card_excpfee.cce_crsubgl_code%TYPE;
   v_cracct_no         cms_card_excpfee.cce_cracct_no%TYPE;
   v_drgl_catg         cms_card_excpfee.cce_drgl_catg%TYPE;
   v_drgl_code         cms_card_excpfee.cce_drgl_code%TYPE;
   v_drsubgl_code      cms_card_excpfee.cce_drsubgl_code%TYPE;
   v_dracct_no         cms_card_excpfee.cce_dracct_no%TYPE;
   v_st_calc_flag      cms_card_excpfee.cce_st_calc_flag%TYPE;
   v_cess_calc_flag    cms_card_excpfee.cce_cess_calc_flag%TYPE;
   v_st_cracct_no      cms_card_excpfee.cce_st_cracct_no%TYPE;
   v_st_dracct_no      cms_card_excpfee.cce_st_dracct_no%TYPE;
   v_cess_cracct_no    cms_card_excpfee.cce_cess_cracct_no%TYPE;
   v_cess_dracct_no    cms_card_excpfee.cce_cess_dracct_no%TYPE;
   v_freetxn_exceed    VARCHAR2 (1);
   v_duration          VARCHAR2 (10);
   v_cap_prod_code     cms_appl_pan.cap_prod_code%TYPE;
   v_cap_card_type     cms_appl_pan.cap_card_type%TYPE;
   v_dr_cr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_txn_type          VARCHAR2 (1);
   v_feeattach_type    VARCHAR2 (2);
   
   v_card_cnt          number(3);
   v_prdcatg_cnt       number(3); 
   V_PROD_CNT          number(3); 
   
   V_REVERSAL_TXN    varchar2(1) default 'N';               -- Added By Santosh K For Defect ID : 0011207
  -- V_REVESAL_MSGTYPE CMS_TXN_PROPERTIES.CTP_MSG_TYPE%TYPE;  -- Added By Santosh K For Defect ID : 0011207 --Commented for 13641
   
BEGIN

  v_errmsg := 'OK'; 

   BEGIN
      v_hash_pan := gethash (prm_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while converting pan into hash'
            || prm_card_no
            || ' '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_reject_record;
   END;

   /*
     BEGIN
        v_encr_pan := fn_emaps_main (prm_card_no);
     EXCEPTION
        WHEN OTHERS
        THEN
           v_errmsg :=
                 'Error while converting pan into encrypted pan for'
              || prm_card_no
              || ' '
              || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_reject_record;
     END;
    */
   BEGIN
      SELECT cap_acct_no, cap_prod_code, cap_card_type
        INTO v_spnd_acctno, v_cap_prod_code, v_cap_card_type
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan
         AND cap_inst_code = prm_instcode
         AND cap_mbr_numb = prm_mbr_numb;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
              'Spending Account Number Not Found For the Card in PAN Master ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error While Selecting Spending account Number for Card '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal
        INTO v_acct_balance, v_ledger_bal
        FROM cms_acct_mast
       WHERE cam_inst_code = prm_instcode AND cam_acct_no = v_spnd_acctno;

      prm_avail_bal := TRIM (TO_CHAR (v_acct_balance, '9999999999999990.00'));
      prm_ledger_bal := TRIM (TO_CHAR (v_ledger_bal, '9999999999999990.00'));
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'account not found in master' || v_spnd_acctno;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'error while validating account number '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT ctm_credit_debit_flag,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1'))
        INTO v_dr_cr_flag,
             v_txn_type
        FROM cms_transaction_mast
       WHERE ctm_tran_code = prm_txn_code
         AND ctm_delivery_channel = prm_delivery_channel
         AND ctm_inst_code = prm_instcode;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
               'Transflag  not defined for txn code '
            || prm_txn_code
            || ' and delivery channel '
            || prm_delivery_channel;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting transflag ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   
   
   --Commented for 13641
   --SN : Added By Santosh K For Defect ID : 0011207
   
  /* BEGIN

    SELECT CTP_MSG_TYPE
     INTO V_REVESAL_MSGTYPE
     FROM CMS_TXN_PROPERTIES
    WHERE CTP_INST_CODE = prm_instcode AND
         CTP_DELIVERY_CHANNEL = prm_delivery_channel AND
         CTP_TXN_CODE = prm_txn_code AND
         CTP_MSG_TYPE in ('0400', '1420', '9220', '9221', '1220', '1221') and
         CTP_REVERSAL_CODE !=0;
        
    V_REVERSAL_TXN := 'R';

   EXCEPTION
    WHEN NO_DATA_FOUND THEN  */
     V_REVERSAL_TXN := 'N';

--Commented for 13641
  /*  WHEN OTHERS THEN
     v_errmsg := 'Error while selecting the Reversal Flag  ' ||  SUBSTR (SQLERRM, 1, 100);
     RAISE exp_reject_record;

   END;
  */
  --EN : Added By Santosh K For Defect ID : 0011207
 
    select count(1)
    into   v_card_cnt
    from  cms_card_excpfee,cms_fee_feeplan
    where cce_pan_code = v_hash_pan
    and   cce_fee_plan = cff_fee_plan(+)
    AND ((cce_valid_to IS NOT NULL AND (trunc(sysdate) between cce_valid_from and cce_valid_to))
         OR (cce_valid_to IS NULL AND trunc(sysdate) >= cce_valid_from));
     
     If v_card_cnt >= 1
     then
     
        Begin     
     
              select    CFM_FEE_AMT,
                        CFM_FEE_DESC,
                        'Y',
                        cfm_clawback_flag,
                        cfm_fee_code
              into      prm_feeamount,    
                        prm_fee_desc,     
                        prm_feeflag,      
                        prm_clawback_flag,
                        v_fee_code
             from  cms_card_excpfee,cms_fee_mast,cms_fee_feeplan
             where cce_fee_plan = cff_fee_plan
             and   cfm_fee_code = cff_fee_code
             and   cce_pan_code = v_hash_pan
             and   cfm_delivery_channel = prm_delivery_channel
             and   (CFM_TRAN_CODE  = PRM_TXN_CODE or CFM_TRAN_CODE  = 'A')
             and   nvl(CFM_NORMAL_RVSL,'N') = V_REVERSAL_TXN                               -- Added By Santosh K For Defect ID : 0011207
             AND ((cce_valid_to IS NOT NULL AND (trunc(sysdate) between cce_valid_from and cce_valid_to))
             OR (cce_valid_to IS NULL AND trunc(sysdate) >= cce_valid_from));
             
             prm_feeflag := 'Y';
             
        exception when no_data_found
        then
        
             v_errmsg    := 'NO FEES ATTACHED';
             prm_feeflag := 'N';
             --return;
             
        when others
        then      
             
        v_errmsg    := 'Error while getting fee details for Card '||substr(sqlerrm,1,100);
        prm_feeflag := 'E';
        RAISE exp_reject_record;
         
        End; 
     
         

     elsif v_card_cnt = 0
     then  
     
        select count(1)
        into   v_prdcatg_cnt
        from  cms_prodcattype_fees,cms_fee_feeplan
        where cpf_prod_code = v_cap_prod_code
        and   cpf_card_type = v_cap_card_type
        and   cpf_fee_plan = cff_fee_plan(+)
        AND ((cpf_valid_to IS NOT NULL AND (trunc(sysdate) between cpf_valid_from and cpf_valid_to))
             OR (cpf_valid_to IS NULL AND trunc(sysdate) >= cpf_valid_from));
     
          
         if v_prdcatg_cnt >= 1
         then 
            
            Begin
            
                select  CFM_FEE_AMT,
                        CFM_FEE_DESC,
                        'Y',
                        cfm_clawback_flag,
                        cfm_fee_code
               into     prm_feeamount,    
                        prm_fee_desc,     
                        prm_feeflag,      
                        prm_clawback_flag,
                        v_fee_code
                 from  cms_prodcattype_fees,cms_fee_mast ,cms_fee_feeplan
                 where cpf_fee_plan = cff_fee_plan
                 and   cfm_fee_code = cff_fee_code
                 and   cpf_prod_code = v_cap_prod_code
                 and   cpf_card_type = v_cap_card_type
                 and   cfm_delivery_channel = prm_delivery_channel
                 and   (CFM_TRAN_CODE  = PRM_TXN_CODE or CFM_TRAN_CODE  = 'A')
                 and   nvl(CFM_NORMAL_RVSL,'N') = V_REVERSAL_TXN                          -- Added By Santosh K For Defect ID : 0011207
                 and ((cpf_valid_to IS NOT NULL AND (trunc(sysdate) between cpf_valid_from and cpf_valid_to))
                 OR (cpf_valid_to IS NULL AND trunc(sysdate) >= cpf_valid_from));
                 
                 prm_feeflag := 'Y';
                              
            exception when no_data_found
            then
                
                 v_errmsg    := 'NO FEES ATTACHED';
                 prm_feeflag := 'N';
                 --return;
                     
            when others
            then      
                     
            v_errmsg := 'Error while getting fee details for Prod catg '||substr(sqlerrm,1,100);
            prm_feeflag := 'E';
            RAISE exp_reject_record;
                 
            End; 
             
         elsif v_prdcatg_cnt = 0
         then
         
         
            select count(1)
            into  v_prod_cnt
            from  cms_prod_fees,cms_fee_feeplan
            where cpf_prod_code = v_cap_prod_code
            and   cpf_fee_plan = cff_fee_plan(+)
            AND ((cpf_valid_to IS NOT NULL AND (trunc(sysdate) between cpf_valid_from and cpf_valid_to))
            OR (cpf_valid_to IS NULL AND trunc(sysdate) >= cpf_valid_from));
          
         
             if v_prod_cnt >= 1
             then 
                
                Begin
                
                    select  CFM_FEE_AMT,
                            CFM_FEE_DESC,
                            'Y',
                            cfm_clawback_flag,
                            cfm_fee_code
                   into     prm_feeamount,    
                            prm_fee_desc,     
                            prm_feeflag,      
                            prm_clawback_flag,
                            v_fee_code
                     from  cms_prod_fees,cms_fee_mast ,cms_fee_feeplan
                     where cpf_fee_plan = cff_fee_plan
                     and   cfm_fee_code = cff_fee_code
                     and   cpf_prod_code = v_cap_prod_code
                     and   cfm_delivery_channel = prm_delivery_channel
                     and   (CFM_TRAN_CODE       = PRM_TXN_CODE or CFM_TRAN_CODE  = 'A')
                     and   nvl(CFM_NORMAL_RVSL,'N') = V_REVERSAL_TXN                      -- Added By Santosh K For Defect ID : 0011207
                     and ((cpf_valid_to IS NOT NULL AND (trunc(sysdate) between cpf_valid_from and cpf_valid_to))
                     OR (cpf_valid_to IS NULL AND trunc(sysdate) >= cpf_valid_from));
                     
                     
                      prm_feeflag := 'Y';      
                                  
                exception when no_data_found
                then
                    
                     v_errmsg    := 'NO FEES ATTACHED';
                     prm_feeflag := 'N';
                     --return;
                         
                when others
                then      
                         
                v_errmsg := 'Error while getting fee details for Prod '||substr(sqlerrm,1,100);
                prm_feeflag := 'E';
                RAISE exp_reject_record;
                     
                End; 
                
                
             elsif v_prod_cnt = 0
             then
             
                     v_errmsg    := 'NO FEES ATTACHED';
                     prm_feeflag := 'N';
                     --return;
                
             End if; -- Product              
          

         End if; -- Product Catg
        
     
     End if;  -- Card


    IF v_fee_code IS NOT NULL
    THEN 
       BEGIN
          SELECT cfm_fee_desc
            INTO prm_fee_desc
            FROM cms_fee_mast
           WHERE cfm_inst_code = prm_instcode AND cfm_fee_code = v_fee_code;
       EXCEPTION WHEN NO_DATA_FOUND
          THEN
             v_errmsg := 'Fee desc not found for fee code ' || v_fee_code;
             RAISE exp_reject_record;
          WHEN OTHERS
          THEN
             v_errmsg :=
                   'Error occured while fetching fee desc '
                || SUBSTR (SQLERRM, 1, 100);
             RAISE exp_reject_record;
       END;
       
       prm_feeamount := TRIM (TO_CHAR (prm_feeamount, '9999999999999990.00'));
       
    END IF;   

   
   prm_errmsg := v_errmsg;

 
     
EXCEPTION
   WHEN exp_reject_record
   THEN
      prm_errmsg := v_errmsg;
      prm_feeflag := 'E';
   WHEN OTHERS
   THEN
      prm_errmsg := 'Error from main ' || SUBSTR (SQLERRM, 1, 100);
      prm_feeflag := 'E';
END;
/
SHOW ERROR