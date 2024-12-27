create or replace
PROCEDURE               vmscms.SP_TRAN_FEES_PRODUCTCATG
(prm_inst_code         IN NUMBER,
prm_del_channel        IN        VARCHAR2,
prm_tran_type        IN        VARCHAR2,    -- FIN/NON FIN TRAN
prm_tran_mode        IN        VARCHAR2,    -- ONUS/OFFUS
prm_tran_code        IN        VARCHAR2,
prm_currency_code    IN        VARCHAR2,
prm_trn_amt        IN        NUMBER,
prm_prod_code        IN        VARCHAR2,
prm_card_type        IN        NUMBER,
prm_consodium_code    IN        NUMBER,
prm_partner_code    IN        NUMBER,
prm_tran_date       IN      DATE,
prm_intl_indicator      IN          VARCHAR2,--Added by Deepa
prm_pos_verification    IN          VARCHAR2,--Added by Deepa
prm_response_code       IN          VARCHAR2,--Added by Deepa
prm_msg_type            IN          VARCHAR2,--Added by Deepa
prm_card_number         IN          VARCHAR2,--Added by Deepa
prm_reversal_flag       IN          VARCHAR2,--Added by Deepa on June 25 2012 for Reversal txn Fee
prm_reversal_code       IN          VARCHAR2,--Added by Deepa on June 25 2012 for Reversal txn Fee
prm_mcc_code         IN          VARCHAR2,
prm_preauth_flag        IN           VARCHAR2,--Added by Abdul Hameed for 15194
prm_cr_dr_flag           IN          VARCHAR2,--Added by Abdul Hameed for 15194
prm_acct_number      IN          VARCHAR2, --Added for OTC changes
prm_fee_code        OUT        NUMBER,
prm_flat_fee        OUT        NUMBER,
prm_per_fees        OUT        NUMBER,
prm_min_fees        OUT        NUMBER,
prm_fee_attach          OUT         NUMBER,--Added by Deepa
prm_feeamnt_type        OUT         VARCHAR2,--Added by Deepa
prm_clawback            OUT         VARCHAR2,--Added by Deepa
prm_fee_plan            OUT         VARCHAR2,--Added by Deepa
prm_tran_fee        OUT        NUMBER,
prm_error        OUT        VARCHAR2,
prm_crgl_catg           OUT             VARCHAR2,
prm_crgl_code           OUT             VARCHAR2,
prm_crsubgl_code        OUT             VARCHAR2,
prm_cracct_no           OUT             VARCHAR2,
prm_drgl_catg           OUT             VARCHAR2,
prm_drgl_code           OUT             VARCHAR2,
prm_drsubgl_code        OUT             VARCHAR2,
prm_dracct_no           OUT             VARCHAR2,
prm_st_calc_flag                   OUT            VARCHAR2,
prm_cess_calc_flag               OUT               VARCHAR2     ,
prm_st_cracct_no                  OUT       VARCHAR2,
prm_st_dracct_no                   OUT               VARCHAR2,
prm_cess_cracct_no                OUT                VARCHAR2,
prm_cess_dracct_no                OUT               VARCHAR2,
prm_freetxn_exceeded    OUT         VARCHAR2, -- Added by Trivikram on 26-Jul-2012
PRM_DURATION            OUT         VARCHAR2, -- Added by Trivikram on 26-Jul-2012
PRM_FEE_DESC            OUT         VARCHAR2, -- Added for MVCSD-4471
prm_complfree_flag              IN VARCHAR2 DEFAULT 'N',
prm_surchrg_ind   IN VARCHAR2 DEFAULT '2' --Added for VMS-5856
)
IS
/***************************************************************************************
      * Modified By      :  Deepa T
      * Modified Date    :  25--Sep-2012
      * Modified Reason  :  To allow the Fees with Particular MCCode and ALL in the same FeePlan and to calculate the Fee based on that.
      * Reviewer         : Saravanakumar.
      * Reviewed Date    : 15-Oct-2012
      * Build Number     :  CMS3.5.1_RI0020_B0001
      
      * Modified By      :  Naila Uzma S.N
      * Modified Date    :  21-Aug-2013
      * Modified Reason  :  NCGPR-438
      * Build Number     :  RI0024.4_B0004

      
      * Modified By      : Sachin P.
      * Modified Date    : 02-Sep-2013
      * Modified for     : DFCHOST-340
      * Modified Reason  :
      * Reviewer         : Dhiraj
      * Reviewed Date    : 03/09/2013
      * Build Number     : RI0024.3.6_B0002  
              
      * Modified By      : Sachin P.
      * Modified Date    : 05-Sep-2013
      * Modified for     : DFCHOST-340(review) and Mantis id: 12277
      * Modified Reason  : Review Changes
                          Mantis id: 12277-Transaction Fee should be assessed based on sysdate
      * Reviewer         : Dhiraj
       * Reviewed Date   : 11-sep-2013
      * Build Number     : RI0024.4_B0009
      
      * Modified By      : Siva Kumar M
      * Modified Date    : 17-Oct-2013
      * Modified for     : LYFE HOST-61
      * Reviewer         : Dhiraj 
      * Reviewed Date    : 17-Oct-2013
      * Build Number     : RI0024.6_B0001

      * Modified By      : Siva Kumar M
      * Modified Date    : 25-Oct-2013
      * Modified for     : Defect Id:12815
      * Reviewer         : Dhiraj
      * Reviewed Date    : 25-Oct-2013
      * Build Number     : RI0024.6_B0003
      
      * Modified By      : MageshKumar S
      * Modified Date    : 28-Jan-2014
      * Modified for     : MVCSD-4471
      * Modified Reason  : Narration change for FEE amount
      * Reviewer         : Dhiraj
      * Reviewed Date    : 28-Jan-2014
      * Build Number     : RI0027.1_B0001
      
      * Modified By      : Abdul Hameed M.A
      * Modified Date    : 03-July-2014
      * Modified for     : Mantis ID 15194
      * Modified Reason  : Merchandise return auth transaction fee issues 
      * Reviewer         : Spankaj
      * Build Number     : RI0027.2.2_B0002

      * Modified By      : Ramesh A
      * Modified Date    : 20-Aug-2014
      * Modified for     : Mantis ID 15696
      * Modified Reason  : Merchandise return null completion 
      * Reviewer         : Spankak
      * Build Number     : RI0027.3.1_B0005
      
      * Modified By      : MageshKumar S
      * Modified Date    : 08-JUNE-2015
      * Modified for     : 
      * Modified Reason  : Calculate fee for ATM auth transactions
      * Reviewer         : Pankaj
      * Reviewed Date    :
      * Build Number     : VMSGPRHOSTCSD3.0.3_B0001
      
    * Modified by       : Abdul Hameed M.A
    * Modified Date     : 23-June-15
    * Modified For      : FSS 1960
    * Reviewer          : Pankaj S
    * Build Number      : VMSGPRHOSTCSD_3.1_B0001

     * Modified by          : Saravanakumar
     * Modified Date        : 19-Aug-2015
     * Modified For         :Performance changes
     * Reviewer             : Spankaj
     * Build Number         : VMSGPRHOSTCSD3.1_B0003

     * Modified by          : Spankaj
     * Modified Date        : 08-Nov-2016
     * Modified For         :FSS-4762:VMS OTC Support for Instant Payroll Card
     * Reviewer             : Saravanakumar
     * Build Number         : VMSGPRHOSTCSD4.11     
     * Modified by          : Saravanakumar A
     * Modified Date        : 08-Feb-2017
     * Modified For         : NCGPR-2921-multiple Activation Fee charges in same day/account
     * Reviewer             : Pankaj S
     * Build Number         : VMSGPRHOSTCSD17.02

     * Modified by      : Pankaj S.
     * Modified for     : FSS-5126: Free Fee Issue
     * Modified Date    : 26-June-2017
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_17.06
     
     * Modified by      : Pankaj S.
     * Modified for     : VMS-5856
     * Modified Date    : 29-Jun-2022
     * Reviewer         : Venkat S.
     * Build Number     : R65
****************************************************************************************/
exp_main    EXCEPTION        ;
exp_nofees    EXCEPTION        ;
v_hash_pan         CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
 v_duration         CMS_FEE_MAST.CFM_DURATION%TYPE;
 v_free_txncnt      CMS_FEE_MAST.CFM_FREE_TXNCNT%TYPE;
 v_txn_done         CMS_FEE_MAST.CFM_FREE_TXNCNT%TYPE;
 v_tran_fee         NUMBER(1);
 v_perc_fee         CMS_FEE_MAST.cfm_fee_amt%TYPE;
 v_tran_typemast    VARCHAR2(5);
 v_intl_indicator   CMS_FEE_MAST.CFM_INTL_INDICATOR%TYPE;
 v_approve_stat     CMS_FEE_MAST.CFM_APPROVE_STATUS%TYPE;
 v_PIN_TXN          CMS_FEE_MAST.CFM_PIN_SIGN%TYPE;
 v_decline_resp     NUMBER(10);
 v_freetxn_exceeded VARCHAR2(1);
 v_trn_amt          NUMBER;
 v_reversal_code    CMS_FEE_MAST.CFM_NORMAL_RVSL%TYPE;
 V_TXN_STATUS       VARCHAR2(1) default 'A';
 v_free_declinetxn  NUMBER default 0;
 v_tran_date        DATE;
 v_from_date        VARCHAR2(10);
 v_to_date          VARCHAR2(10);
v_tran_mode CMS_FEE_MAST.cfm_tran_mode%type;
v_tran_type  CMS_FEE_MAST.cfm_tran_type%type;
v_tran_code  CMS_FEE_MAST.cfm_tran_code%type;
v_merc_code  CMS_FEE_MAST.CFM_MERC_CODE%type;
v_maxlimit NUMBER(5); -- ADDED FOR NCGPR-438 by Naila on 14-08-2013
v_maxlimitfreq VARCHAR2(1); -- ADDED FOR NCGPR-438 by Naila on 14-08-2013
v_maxlimit_exceeded VARCHAR2(1); -- ADDED FOR NCGPR-438 by Naila on 14-08-2013
v_error_msg VARCHAR2(500); -- ADDED FOR NCGPR-438 by Naila on 14-08-2013
v_prdcatg_cnt          number;--Added on 02.09.2013 for DFCHOST-340

v_cap_amt  cms_fee_mast.cfm_cap_amt%type;   -- Added for lyfehost-61.
--SN: Added for OTC changes
v_freetxn_flag   VARCHAR2(1);
v_frrefreq_change  cms_fee_mast.cfm_duration_change%TYPE;
--EN: Added for OTC changes
v_card_activation cms_transaction_mast.ctm_card_activation%type;
v_active_flag cms_acct_mast.cam_active_flag%type;
v_count number;
BEGIN

prm_freetxn_exceeded := 'Y';

--SN CREATE HASH PAN
BEGIN
    v_hash_pan := Gethash(prm_card_number);
EXCEPTION
WHEN OTHERS THEN
prm_error := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
    RAISE exp_main;
END;
--EN CREATE HASH PAN

    prm_error := 'OK'    ;
   v_tran_date:= TRUNC(prm_tran_date);
        --SN Added on 02.09.2013 for DFCHOST-340
   BEGIN  
      SELECT count (case when ((cpf_valid_to IS NOT NULL AND TRUNC(sysdate) between cpf_valid_from and cpf_valid_to))
         OR (cpf_valid_to IS NULL AND TRUNC(sysdate) >= cpf_valid_from)then 1 end)
    INTO v_prdcatg_cnt
    FROM cms_prodcattype_fees      
    WHERE cpf_inst_code = prm_inst_code 
    AND cpf_prod_code   = prm_prod_code
    AND cpf_card_type   = prm_card_type;
   EXCEPTION 
   WHEN OTHERS THEN
            prm_error := 'Error while selecting count from product catg level  --'||SUBSTR(SQLERRM,1,200) ;
            RAISE exp_main; 
    
   END;
  --EN Added on 02.09.2013 for DFCHOST-340 

 IF v_prdcatg_cnt =0 THEN --IF condition Added on 02.09.2013 for DFCHOST-340
     prm_fee_attach :=0;
   ELSE   
    prm_fee_attach :=1;
 
    BEGIN
        SELECT ctm_card_activation
        into v_card_activation
        FROM CMS_TRANSACTION_MAST
        WHERE CTM_DELIVERY_CHANNEL=PRM_DEL_CHANNEL
        AND CTM_TRAN_CODE         =PRM_TRAN_CODE
        AND CTM_INST_CODE         =PRM_INST_CODE;
    EXCEPTION
      WHEN OTHERS THEN
        PRM_ERROR := 'Error while getting transaction details' || SQLERRM;
        RAISE EXP_MAIN;
    END; 
    if v_card_activation='Y' then
        begin
            select cam_active_flag
            into v_active_flag
            from cms_acct_mast
            where CAM_INST_CODE=prm_inst_code
            and   CAM_ACCT_NO=prm_acct_number;
        exception
            WHEN OTHERS THEN
            PRM_ERROR := 'Error while getting  details from cms_acct_mast' || SQLERRM;
            RAISE EXP_MAIN;
        end;
        if v_active_flag is null then
            select count(1)
            into v_count
            from cms_appl_pan
            where cap_inst_code=prm_inst_code
            and cap_acct_no=prm_acct_number
            and cap_active_date is not null
            and cap_startercard_flag='N';
            if v_count>0 then
                begin
                   update cms_acct_mast set cam_active_flag='Y'
                   where CAM_INST_CODE=prm_inst_code
                   and   CAM_ACCT_NO=prm_acct_number; 
                exception
                    when others then
                       PRM_ERROR := 'Error while updating cms_acct_mast' || SQLERRM;
                       RAISE EXP_MAIN;
                end;
                prm_fee_attach :=0;
                RAISE exp_nofees;
            else
                begin
                   update cms_acct_mast set cam_active_flag='N'
                   where CAM_INST_CODE=prm_inst_code
                   and   CAM_ACCT_NO=prm_acct_number; 
                exception
                    when others then
                       PRM_ERROR := 'Error while updating cms_acct_mast' || SQLERRM;
                       RAISE EXP_MAIN;
                end;
            end if;
         ELSIF   V_ACTIVE_FLAG='Y' THEN
                   prm_fee_attach :=0;
                  RAISE exp_nofees;
         end if;
    end if;  
BEGIN



    BEGIN -- BEGIN 1
        SELECT  cfm_fee_code,  cfm_fee_amt, cfm_per_fees, cfm_min_fees,
                    cpf_crgl_catg, cpf_crgl_code,cpf_crsubgl_code,cpf_cracct_no,
                    cpf_drgl_catg,  cpf_drgl_code,cpf_drsubgl_code,cpf_dracct_no,
                    cpf_st_calc_flag ,cpf_cess_calc_flag,cpf_st_cracct_no,cpf_st_dracct_no,
                    cpf_cess_cracct_no,cpf_cess_dracct_no,cfm_feeamnt_type,cfm_duration,
                    cfm_free_txncnt,CFM_INTL_INDICATOR,CFM_APPROVE_STATUS,CFM_PIN_SIGN,
            CFM_CLAWBACK_FLAG,cpf_fee_plan,CFM_NORMAL_RVSL,cfm_tran_type,cfm_tran_code,cfm_tran_mode,CFM_MERC_CODE,CFM_MAX_LIMIT,CFM_MAXLMT_FREQ,cfm_cap_amt, --modified for ncgpr-438 by Naila on 14-08-2013 & added cfm_cap_amt for lyfehost-61
            cfm_fee_desc -- Added for MVCSD-4471
            ,cfm_duration_change --Added for OTC changes
            INTO    prm_fee_code,  prm_flat_fee, prm_per_fees, prm_min_fees,
                    prm_crgl_catg ,prm_crgl_code    ,prm_crsubgl_code ,prm_cracct_no    ,
                    prm_drgl_catg    ,prm_drgl_code    ,prm_drsubgl_code ,prm_dracct_no ,
                    prm_st_calc_flag,prm_cess_calc_flag,prm_st_cracct_no,prm_st_dracct_no,
                    prm_cess_cracct_no,prm_cess_dracct_no, prm_feeamnt_type,v_duration,
                    v_free_txncnt,v_intl_indicator,v_approve_stat,v_PIN_TXN ,prm_clawback,
            prm_fee_plan,v_reversal_code,v_tran_type,v_tran_code,v_tran_mode,v_merc_code,v_maxlimit,v_maxlimitfreq,v_cap_amt, --modified for ncgpr-438 by Naila on 14-08-2013
            PRM_FEE_DESC -- Added for MVCSD-4471
            ,v_frrefreq_change --Added for OTC changes
        FROM CMS_FEE_MAST, CMS_PRODCATTYPE_FEES, cms_fee_types, cms_fee_feeplan
        WHERE CFM_INST_CODE = prm_inst_code
        and  CFM_INST_CODE=CPF_INST_CODE
        and  cpf_prod_code  = prm_prod_code
        AND CPF_CARD_TYPE =  prm_card_type
         --AND ((cpf_valid_to IS NOT NULL AND (v_tran_date between cpf_valid_from and cpf_valid_to))
         --Commented and modified  on 05.09.2013 for 12277
        AND ((cpf_valid_to IS NOT NULL AND (trunc(sysdate) between cpf_valid_from and cpf_valid_to))
          --OR (cpf_valid_to IS NULL AND v_tran_date >= cpf_valid_from))  --Modified by Deepa on Aug 16 2012 to have two active FeePlan
        OR (cpf_valid_to IS NULL AND trunc(sysdate) >= cpf_valid_from))--Commented and modified  on 05.09.2013 for 12277    
        AND  CPF_FEE_PLAN = cff_fee_plan
        AND   cfm_feetype_code = cft_feetype_code
        AND   cfm_fee_code = cff_fee_code
        AND   cft_fee_freq = 'T'
        AND   cfm_delivery_channel = prm_del_channel
        AND   (cfm_tran_type        = prm_tran_type or cfm_tran_type        = 'A')
        AND   (cfm_tran_code        = prm_tran_code or cfm_tran_code        = 'A')
        AND ((prm_reversal_flag='N'  and  (cfm_tran_mode=prm_tran_mode or cfm_tran_mode='A')) or  prm_reversal_flag='R')
        AND ((nvl(CFM_NORMAL_RVSL,0)=nvl(decode(cfm_tran_type,'0','',prm_reversal_flag ),0)) --Modified by Deepa on July 04 2012 as the CFM_NORMAL_RVSL will be NULL for the Non-Financial txns
          --  OR (prm_del_channel IN('02') and prm_tran_code IN ('11') and CFM_NORMAL_RVSL=prm_reversal_flag ))--Added as the Preauth(Non financial) txn will have the reversal flag 'N'
                --Modified by Abdul Hameed for 15194
            OR (prm_del_channel IN('02','01','13','08') and prm_preauth_flag ='Y'  AND prm_cr_dr_flag='NA' and CFM_NORMAL_RVSL=prm_reversal_flag )) --Condition modified to include ATM Auth for 3.0.3 release
        AND (((prm_del_channel IN ('02','05') AND (CFM_MERC_CODE=prm_mcc_code ))--Modified by Deepa on Sep-25-2012 To calculate the MCC code Fee for the particular MCCode
         OR prm_del_channel NOT IN ('02','05')) or prm_reversal_flag='R')--Modified the reversal flag value from 'Y' to 'R'
        /*Added by Deepa on Sep-15 2012 as the query return more than one row if a separate
             FEE attached for the POS PIN,Signature transactions or for International,Domestic or Approve,Decline
             with all the other conditions are same*/
        AND (((prm_del_channel='02') AND (prm_reversal_flag='N') AND 
            (CFM_PIN_SIGN=NVL(prm_pos_verification,'S') OR CFM_PIN_SIGN='A')) --Modified for defect id 15696 PIN verification default to Signature   
            OR (prm_del_channel NOT IN ('02') OR (prm_reversal_flag='R') ))
            --PIN/Signatrue based fee applicable only for the Normal transactions of POS
            AND (((prm_del_channel IN ('02','01')) AND prm_reversal_flag='N' AND 
            (CFM_INTL_INDICATOR=NVL(prm_intl_indicator,'0') OR CFM_INTL_INDICATOR='A')) --Modified for defect id 15696 International indicator defaulted to Domestic  
            OR (prm_del_channel NOT IN ('02','01') OR (prm_reversal_flag='R') ))
            --Internation/Domestic txn based fee applicable only for the Normal transactions of ATM,POS
            AND (((prm_del_channel IN ('02','01')) AND prm_reversal_flag='N' AND
             (CFM_APPROVE_STATUS=decode(prm_response_code,'1','P','D') OR CFM_APPROVE_STATUS='A')) 
             OR (prm_del_channel NOT IN ('02','01') OR (prm_reversal_flag='R') ));  
             --Approve/Decline txn fee applicable only for the Normal transactions of ATM,POS      

        v_tran_fee := 1    ;
     EXCEPTION -- EXCEPTION 1
         WHEN NO_DATA_FOUND THEN
         BEGIN
         --Added by Deepa on Sep-25-2012 To calculate the MCC code Fee for the configuration of MCCode(ALL)
             SELECT  cfm_fee_code,  cfm_fee_amt, cfm_per_fees, cfm_min_fees,
                    cpf_crgl_catg, cpf_crgl_code,cpf_crsubgl_code,cpf_cracct_no,
                    cpf_drgl_catg,  cpf_drgl_code,cpf_drsubgl_code,cpf_dracct_no,
                    cpf_st_calc_flag ,cpf_cess_calc_flag,cpf_st_cracct_no,cpf_st_dracct_no,
                    cpf_cess_cracct_no,cpf_cess_dracct_no,cfm_feeamnt_type,cfm_duration,
                    cfm_free_txncnt,CFM_INTL_INDICATOR,CFM_APPROVE_STATUS,CFM_PIN_SIGN,
            CFM_CLAWBACK_FLAG,cpf_fee_plan,CFM_NORMAL_RVSL,cfm_tran_type,cfm_tran_code,cfm_tran_mode,CFM_MERC_CODE,CFM_MAX_LIMIT,CFM_MAXLMT_FREQ,cfm_cap_amt, --modified for ncgpr-438 by Naila on 14-08-2013 & added cfm_cap_amt for lyfehost-61
            cfm_fee_desc -- Added for MVCSD-4471
            ,cfm_duration_change --Added for OTC changes
            INTO    prm_fee_code,  prm_flat_fee, prm_per_fees, prm_min_fees,
                    prm_crgl_catg ,prm_crgl_code    ,prm_crsubgl_code ,prm_cracct_no    ,
                    prm_drgl_catg    ,prm_drgl_code    ,prm_drsubgl_code ,prm_dracct_no ,
                    prm_st_calc_flag,prm_cess_calc_flag,prm_st_cracct_no,prm_st_dracct_no,
                    prm_cess_cracct_no,prm_cess_dracct_no, prm_feeamnt_type,v_duration,
                    v_free_txncnt,v_intl_indicator,v_approve_stat,v_PIN_TXN ,prm_clawback,
            prm_fee_plan,v_reversal_code,v_tran_type,v_tran_code,v_tran_mode,v_merc_code,v_maxlimit,v_maxlimitfreq,v_cap_amt, --modified for ncgpr-438 by Naila on 14-08-2013
            PRM_FEE_DESC -- Added for MVCSD-4471
            ,v_frrefreq_change --Added for OTC changes
        FROM CMS_FEE_MAST, CMS_PRODCATTYPE_FEES, cms_fee_types, cms_fee_feeplan
        WHERE CFM_INST_CODE = prm_inst_code
        and  CFM_INST_CODE=CPF_INST_CODE
        and  cpf_prod_code  = prm_prod_code
        AND CPF_CARD_TYPE =  prm_card_type
         --AND ((cpf_valid_to IS NOT NULL AND (v_tran_date between cpf_valid_from and cpf_valid_to))
         --Commented and modified  on 05.09.2013 for 12277
        AND ((cpf_valid_to IS NOT NULL AND (trunc(sysdate) between cpf_valid_from and cpf_valid_to)) 
            --OR (cpf_valid_to IS NULL AND v_tran_date >= cpf_valid_from))  --Modified by Deepa on Aug 16 2012 to have two active FeePlan
        OR (cpf_valid_to IS NULL AND trunc(sysdate) >= cpf_valid_from)) --Commented and modified  on 05.09.2013 for 12277    
        AND  CPF_FEE_PLAN = cff_fee_plan
        AND   cfm_feetype_code = cft_feetype_code
        AND   cfm_fee_code = cff_fee_code
        AND   cft_fee_freq = 'T'
        AND   cfm_delivery_channel = prm_del_channel
        AND   (cfm_tran_type        = prm_tran_type or cfm_tran_type        = 'A')
        AND   (cfm_tran_code        = prm_tran_code or cfm_tran_code        = 'A')
        AND ((prm_reversal_flag='N'  and  (cfm_tran_mode=prm_tran_mode or cfm_tran_mode='A')) or  prm_reversal_flag='R')
        AND ((nvl(CFM_NORMAL_RVSL,0)=nvl(decode(cfm_tran_type,'0','',prm_reversal_flag ),0)) --Modified by Deepa on July 04 2012 as the CFM_NORMAL_RVSL will be NULL for the Non-Financial txns
          --  OR (prm_del_channel IN('02') and prm_tran_code IN ('11') and CFM_NORMAL_RVSL=prm_reversal_flag ))--Added as the Preauth(Non financial) txn will have the reversal flag 'N'
           --Modified by Abdul Hameed for 15194
       OR (prm_del_channel IN('02','01','13','08') and prm_preauth_flag ='Y' AND prm_cr_dr_flag='NA' and CFM_NORMAL_RVSL=prm_reversal_flag )) --Condition modified to include ATM Auth for 3.0.3 release
        AND (((prm_del_channel IN ('02','05') AND (CFM_MERC_CODE='A'))
         OR prm_del_channel NOT IN ('02','05')) or prm_reversal_flag='R')--Modified the reversal flag value from 'Y' to 'R'
        /*Added by Deepa on Sep-15 2012 as the query return more than one row if a separate
             FEE attached for the POS PIN,Signature transactions or for International,Domestic or Approve,Decline
             with all the other conditions are same*/
        AND (((prm_del_channel='02') AND (prm_reversal_flag='N') AND 
            (CFM_PIN_SIGN=NVL(prm_pos_verification,'S') OR CFM_PIN_SIGN='A')) --Modified for defect id 15696 PIN verification default to Signature   
            OR (prm_del_channel NOT IN ('02') OR (prm_reversal_flag='R') ))
            --PIN/Signatrue based fee applicable only for the Normal transactions of POS
            AND (((prm_del_channel IN ('02','01')) AND prm_reversal_flag='N' AND 
           (CFM_INTL_INDICATOR=NVL(prm_intl_indicator,'0') OR CFM_INTL_INDICATOR='A')) --Modified for defect id 15696 International indicator defaulted to Domestic 
            OR (prm_del_channel NOT IN ('02','01') OR (prm_reversal_flag='R') ))
            --Internation/Domestic txn based fee applicable only for the Normal transactions of ATM,POS
            AND (((prm_del_channel IN ('02','01')) AND prm_reversal_flag='N' AND
             (CFM_APPROVE_STATUS=decode(prm_response_code,'1','P','D') OR CFM_APPROVE_STATUS='A')) 
             OR (prm_del_channel NOT IN ('02','01') OR (prm_reversal_flag='R') ));  
             --Approve/Decline txn fee applicable only for the Normal transactions of ATM,POS      

        v_tran_fee := 1    ;
              
         EXCEPTION -- EXCEPTION 1
         WHEN NO_DATA_FOUND THEN
           prm_error := 'NO FEES ATTACHED'    ;
           RAISE exp_nofees; -- NO FEES ATTACHED RETURN -1
         --SN Added on 05.09.2013 for DFCHOST-340(review)
         WHEN OTHERS THEN
                prm_error := 'ERROR FROM MAIN 1 =>' || SQLERRM    ;
                RAISE exp_main;         
        --EN Added on 05.09.2013 for DFCHOST-340(review)  
         END;

    WHEN OTHERS THEN
            prm_error := 'ERROR FROM MAIN 1 =>' || SQLERRM    ;
            RAISE exp_main;
    END ; -- END 1

      IF prm_del_channel IN ('01','02') AND prm_reversal_flag='N' THEN
      
      --Commented by Deepa on Sep-15-2012 as the Domestic/International txn based fee is added in the query itself
      /*  IF v_intl_indicator='A' OR  prm_intl_indicator=v_intl_indicator THEN
            v_tran_fee := 1    ;
         ELSE
            v_tran_fee := 0    ;
        END IF;*/

        IF v_approve_stat='A'  THEN --BOTH Approve and decline Transactions
           IF prm_response_code='1' THEN
            v_tran_fee := 1    ;
           ELSE
            BEGIN
               SELECT COUNT (*)
              INTO v_decline_resp
              FROM cms_declinetxn_response
             WHERE cdr_inst_code = prm_inst_code
               AND cdr_delivery_channel = prm_del_channel
               AND cdr_tran_code = prm_tran_code
               AND cdr_msg_type = prm_msg_type
               AND cdr_respcde = prm_response_code
               AND CDR_REVERSAL_CODE = prm_reversal_code;
             --SN Added on 05.09.2013 for DFCHOST-340(review)
            EXCEPTION
            WHEN OTHERS THEN
                prm_error := 'Error while selecting count from declinetxn_response 1.0-'
                ||SUBSTR(SQLERRM,1,200);
                RAISE exp_main;
            --EN Added on 05.09.2013 for DFCHOST-340(review)       
            END;   

               IF v_decline_resp > 0 THEN
                   v_tran_fee := 1;
                   V_TXN_STATUS:='D';
                   v_free_declinetxn:=v_decline_resp;
               ELSE
                   v_tran_fee := 0;
               END IF;

           END IF;

        ELSIF  v_approve_stat='P' AND prm_response_code='1' THEN
            v_tran_fee := 1;
        ELSIF   v_approve_stat='D' THEN

        BEGIN
        SELECT COUNT (*)
          INTO v_decline_resp
          FROM cms_declinetxn_response
         WHERE cdr_inst_code = prm_inst_code
           AND cdr_delivery_channel = prm_del_channel
           AND cdr_tran_code = prm_tran_code
           AND cdr_msg_type = prm_msg_type
           AND cdr_respcde = prm_response_code
           AND CDR_REVERSAL_CODE = prm_reversal_code;
        --SN Added on 05.09.2013 for DFCHOST-340(review)
        EXCEPTION
            WHEN OTHERS THEN
                prm_error := 'Error while selecting count from declinetxn_response 1.1-'
                ||SUBSTR(SQLERRM,1,200);
                RAISE exp_main;
            --EN Added on 05.09.2013 for DFCHOST-340(review)      
        END;   

           IF v_decline_resp > 0 THEN
               v_tran_fee := 1;
               V_TXN_STATUS:='D';
              BEGIN
               select count(*) into v_free_declinetxn from cms_freetxn_response
                           where CFR_DELIVERY_CHANNEL = prm_del_channel
                           AND CFR_TRAN_CODE=prm_tran_code
                           AND CFR_INST_CODE=prm_inst_code
                           AND CFR_MSG_TYPE=prm_msg_type
                           AND CFR_REVERSAL_CODE=prm_reversal_code;
               --SN Added on 05.09.2013 for DFCHOST-340(review)
                EXCEPTION
                WHEN OTHERS THEN
                    prm_error := 'Error while selecting count from freetxn_response-'
                    ||SUBSTR(SQLERRM,1,200);
                    RAISE exp_main;
                --EN Added on 05.09.2013 for DFCHOST-340(review)                  
              END;            

           ELSE
               v_tran_fee := 0;
           END IF;
        ELSE
            v_tran_fee := 0 ;
        END IF;

    --Commented by Deepa on Sep-15-2012 as the PIN/Signature txn based fee is added in the query itself
      /*  IF prm_del_channel='02' THEN
           IF v_PIN_TXN='A' OR  prm_pos_verification=v_pin_txn THEN
           --Done Changes by Deepa on  July 02 2012 to verify the POS verification flag with Configured flag
              v_tran_fee := 1    ;
           ELSE
              v_tran_fee := 0    ;
           END IF;

            END IF;*/
    END IF;

EXCEPTION -- MAIN
    WHEN exp_nofees    THEN
    v_tran_fee := 0    ;
    WHEN exp_main THEN
        prm_error := prm_error    ;
        v_tran_fee := -1    ;
        prm_fee_attach :=-1;--Added on 02.09.2013 for DFCHOST-340
    WHEN OTHERS THEN
        prm_error := SQLERRM    ;
        v_tran_fee := -1    ;
        prm_fee_attach :=-1;--Added on 02.09.2013 for DFCHOST-340
END; -- MAIN
  IF v_tran_fee=1 THEN

         ----------------------------------------------------------------------------------------
         --SN: Modified for OTC changes
        ----------------------------------------------------------------------------------------  
        IF ((V_TXN_STATUS='A' and v_free_txncnt > 0) OR (V_TXN_STATUS='D' AND v_free_txncnt > 0 AND  v_free_declinetxn>0)) THEN
      IF prm_complfree_flag='N' THEN 
        BEGIN
               vmsfee.fee_freecnt_check (prm_acct_number,
                                         prm_fee_code,
                                         v_duration,
                                         v_free_txncnt,
                                         TRUNC(v_frrefreq_change),
                                         v_freetxn_flag,
                                         prm_error);

               IF prm_error <> 'OK'
               THEN
                  RAISE exp_main;
               END IF;                
--                 IF v_tran_type='A' THEN
--                      v_tran_typemast :=v_tran_type;
--                 ELSE
--                    SELECT decode(v_tran_type,'1','F','N')
--                        into v_tran_typemast
--                        from dual;
--                 END IF;

                /*IF v_duration='D'  THEN
                --SN Commented and modified on 05.09.2013 for 12277
                     /*v_from_date:=to_char(v_tran_date,'yyyymmdd');
                     v_to_date:=to_char(v_tran_date,'yyyymmdd');*/
                     /*v_from_date:=to_char(sysdate,'yyyymmdd');
                     v_to_date:=to_char(sysdate,'yyyymmdd'); 
                 --EN Commented and modified on 05.09.2013 for 12277    
                 ELSIF v_duration='W'  THEN
                 --SN Commented and modified on 05.09.2013 for 12277
                     /*v_from_date:=to_char(TRUNC(v_tran_date,'WW'),'yyyymmdd') ;
                     v_to_date:=to_char(next_day(v_tran_date,'saturday'),'yyyymmdd');*/
                     /*v_from_date:=to_char(TRUNC(sysdate,'WW'),'yyyymmdd') ;
                     v_to_date:=to_char(next_day(sysdate,'saturday'),'yyyymmdd'); 
                 --EN Commented and modified on 05.09.2013 for 12277    
                 ELSIF v_duration='M'  THEN
                 --SN Commented and modified on 05.09.2013 for 12277
                    /* v_from_date:=to_char(TRUNC(v_tran_date,'MM'),'yyyymmdd') ;
                     v_to_date:=to_char(trunc(LAST_DAY(v_tran_date)),'yyyymmdd');*/
                    /* v_from_date:=to_char(TRUNC(sysdate,'MM'),'yyyymmdd') ;
                     v_to_date:=to_char(trunc(LAST_DAY(sysdate)),'yyyymmdd');
                 --EN Commented and modified on 05.09.2013 for 12277    
                 ELSIF v_duration='Y'  THEN
                 --SN Commented and modified on 05.09.2013 for 12277
                    /*v_from_date:=to_char(TRUNC(v_tran_date,'YYYY'),'yyyymmdd') ;
                     v_to_date:=to_char(last_day(add_months(trunc(v_tran_date,'YYYY'), 11)),'yyyymmdd');*/
                     /*v_from_date:=to_char(TRUNC(sysdate,'YYYY'),'yyyymmdd') ;
                     v_to_date:=to_char(last_day(add_months(trunc(sysdate,'YYYY'), 11)),'yyyymmdd'); 
--               --EN Commented and modified on 05.09.2013 for 12277      
                 END IF;*/
                 --Sn Selecting Daily Free Transaction count
                        /*
                        IF v_tran_code='A' THEN
                          BEGIN  
                            SELECT COUNT (*)
                              INTO v_txn_done
                              FROM transactionlog
                             WHERE  add_ins_date between to_date(v_from_date||'000000','yyyymmddhh24miss')and to_date(v_to_date||'235959','yyyymmddhh24miss')
                             AND response_code =decode(prm_response_code,'1','00',prm_response_code)
                           AND delivery_channel = prm_del_channel
                           AND CUSTOMER_CARD_NO = v_hash_pan
                           AND MSGTYPE = prm_msg_type
                           AND ((v_tran_type='A' and txn_type in (0,1)) or txn_type=prm_tran_type)
                           AND ((prm_reversal_flag='N' AND ((v_tran_mode='A' and txn_mode in (0,1))
                            or txn_mode=prm_tran_mode) ) or  prm_reversal_flag='R')
                           AND txn_code IN (
                                      SELECT ctm_tran_code
                                        FROM cms_transaction_mast
                                       WHERE ctm_delivery_channel = prm_del_channel
                                         AND ((v_tran_typemast ='A' and ctm_tran_type in ('N','F')) or ctm_tran_type=v_tran_typemast)
                                        AND ctm_inst_code = prm_inst_code)
                           AND instcode = prm_inst_code
                           AND REVERSAL_CODE=prm_reversal_code
                           AND ((prm_del_channel IN ('01','02') AND ((v_intl_indicator='A' AND INTERNATION_IND_RESPONSE IN('0','1'))
                                OR (INTERNATION_IND_RESPONSE=v_intl_indicator))) or delivery_channel not IN ('01','02'))
                                AND ((prm_del_channel IN ('02') AND ((v_PIN_TXN='A' AND pos_verification IN('P','S'))
                                OR (pos_verification=v_PIN_TXN))) or delivery_channel not IN ('02'))
                                        AND (((prm_del_channel IN ('02','05') AND (MCCODE=prm_mcc_code OR  v_merc_code='A')) --Modified by Deepa on Sep-20 2012
                               /*MCCODE in transactionlog will not have the value 'A'.Fee Configured value in cms_fee_mast should be checked with 'A'(ALL)*/ 
                                        /*OR prm_del_channel NOT IN ('02','05'))or prm_reversal_flag='R');--Modified by Deepa on Sep-17-2012 to change the reversal flag value from 'Y' to 'R'
                                --Added by Deepa on July 03 2012 for checking International Indicator and POS verification
                           --SN Added on 05.09.2013 for DFCHOST-340(review)
                          EXCEPTION
                            WHEN OTHERS THEN
                                prm_error := 'Error while selecting count from txnlog 1.0 -'
                                ||SUBSTR(SQLERRM,1,200);
                                RAISE exp_main;
                            --EN Added on 05.09.2013 for DFCHOST-340(review)       
                          END; 
                        ELSE
                         BEGIN        
                           SELECT COUNT (*)
                              INTO v_txn_done
                              FROM transactionlog
                             WHERE  add_ins_date between to_date(v_from_date||'000000','yyyymmddhh24miss') and to_date(v_to_date||'235959','yyyymmddhh24miss')
                               AND response_code =decode(prm_response_code,'1','00',prm_response_code)
                               AND delivery_channel = prm_del_channel
                               AND CUSTOMER_CARD_NO = v_hash_pan
                               AND MSGTYPE = prm_msg_type
                               AND ((v_tran_type='A' and txn_type in (0,1)) or txn_type=prm_tran_type)
                              AND ((prm_reversal_flag='N' AND ((v_tran_mode='A' and txn_mode in (0,1))
                                 or txn_mode=prm_tran_mode) ) or  prm_reversal_flag='R')
                               AND txn_code IN ( prm_tran_code )
                               AND instcode = prm_inst_code
                               AND REVERSAL_CODE=prm_reversal_code
                               AND ((prm_del_channel IN ('01','02') AND ((v_intl_indicator='A' AND INTERNATION_IND_RESPONSE IN('0','1'))
                                OR (INTERNATION_IND_RESPONSE=v_intl_indicator))) or delivery_channel not IN ('01','02'))
                                AND ((prm_del_channel IN ('02') AND ((v_PIN_TXN='A' AND pos_verification IN('P','S'))
                                OR (pos_verification=v_PIN_TXN))) or delivery_channel not IN ('02'))
                                AND (((prm_del_channel IN ('02','05') AND (MCCODE=prm_mcc_code OR  v_merc_code='A')) --Modified by Deepa on Sep-20 2012
                               /*MCCODE in transactionlog will not have the value 'A'.Fee Configured value in cms_fee_mast should be checked with 'A'(ALL)*/ 
                               /* OR prm_del_channel NOT IN ('02','05')) or prm_reversal_flag='R');--Modified by Deepa on Sep-17-2012 to change the reversal flag value from 'Y' to 'R'
                                --Added by Deepa on July 03 2012 for checking International Indicator and POS verification
                         --SN Added on 05.09.2013 for DFCHOST-340(review)
                          EXCEPTION
                            WHEN OTHERS THEN
                                prm_error := 'Error while selecting count from txnlog 1.1 -'
                                ||SUBSTR(SQLERRM,1,200);
                                RAISE exp_main;
                            --EN Added on 05.09.2013 for DFCHOST-340(review)            
                         END;      
                        END IF;*/

        EXCEPTION
          --SN Added on 05.09.2013 for DFCHOST-340(review)
        WHEN exp_main THEN
         Raise exp_main; 
            --EN Added on 05.09.2013 for DFCHOST-340(review) 
        WHEN OTHERS THEN
        prm_error := 'Error While Selecting the transactions done'||SQLERRM    ;
        END;
      END IF;
       IF v_freetxn_flag='N' THEN --v_txn_done >= v_free_txncnt THEN
            v_tran_fee:=1;
        ELSE
            v_tran_fee:=0;
            v_freetxn_exceeded:='N';
        END IF;

      ELSE
        v_tran_fee:=1;
      END IF;
      ----------------------------------------------------------------------------------------
       --EN: Modified for OTC changes
      ----------------------------------------------------------------------------------------      
--START FOR  NCGPR-438 -- added by Naila on 14-08-2013
      IF v_tran_fee=1 AND v_maxlimit>0 THEN
 
          SP_ACCTLVL_FEELIMIT(prm_inst_code,
                              prm_card_number,
                              prm_tran_date,
                              prm_fee_code,
                              v_maxlimit,
                              v_maxlimitfreq,
                              v_maxlimit_exceeded,
                              v_error_msg); 
            IF v_error_msg='OK' AND v_maxlimit_exceeded='N' THEN
                v_tran_fee:=1; 
            
            ELSE 
              IF v_error_msg <>'OK' THEN
              
                v_tran_fee:=-1;
                prm_fee_attach := -1    ;--Added on 05.09.2013 for DFCHOST-340(review)
                prm_error:= v_error_msg;
                RETURN;
              ELSE 
                v_tran_fee:=0;
              END IF;
            END IF;
       END IF;
  --END FOR NCGPR-438
      IF v_tran_fee=1 THEN
        IF (prm_flat_fee > 0)  OR (prm_per_fees IS NOT NULL AND prm_per_fees <> 0) THEN
      IF prm_trn_amt IS NULL THEN
         v_trn_amt:=0;
      ELSE
      v_trn_amt:=prm_trn_amt;
      END IF;

           IF prm_feeamnt_type='A' THEN
                
                prm_tran_fee := v_trn_amt * (prm_per_fees / 100);
                
                --SN:Added for VMS-5856
                IF prm_surchrg_ind='0' THEN
                prm_tran_fee:=0;
                END IF;
                --EN:Added for VMS-5856
                prm_per_fees:=prm_tran_fee;
                prm_tran_fee := prm_tran_fee + prm_flat_fee;

                IF prm_tran_fee < prm_min_fees THEN

                prm_tran_fee := prm_min_fees;
                prm_feeamnt_type:='M';

                ELSE
                prm_feeamnt_type:='A';

                END IF;

           ELSIF prm_feeamnt_type ='O' THEN
            
            v_perc_fee := v_trn_amt * (prm_per_fees / 100);
            --SN:Added for VMS-5856
            IF prm_surchrg_ind='0' THEN
            v_perc_fee:=0;
            END IF;
            --EN:Added for VMS-5856
                IF v_perc_fee > prm_flat_fee THEN
                    prm_tran_fee:=v_perc_fee;
                ELSE
                    prm_tran_fee:=prm_flat_fee;
                END IF;

           ELSIF prm_feeamnt_type ='N' THEN

                prm_tran_fee := prm_flat_fee;

               END IF;
          END IF;
          ELSE
          prm_tran_fee:=0;
         END IF;
         
       -- added for lyfehost-61. cap amount will be tran fee amount.
          IF v_cap_amt > 0 AND  prm_tran_fee  > v_cap_amt  and  prm_tran_type ='1'  THEN    -- trna_type condition is add for defect id:12815
            
             prm_tran_fee :=v_cap_amt;
             prm_feeamnt_type :='C';
            END IF;
            
     END IF;

IF v_freetxn_exceeded='N' AND v_tran_fee=0 THEN

    v_tran_fee:=1;
    prm_freetxn_exceeded := v_freetxn_exceeded; -- Added by Trivikram on 26-July-2012, for logging fee of complementory free transactions
    SELECT DECODE(v_duration,
                  'D','Daily',
                  'W','Weekly',
                  'BW','BiWeekly',
                  'M','Monthly',
                  'BM','BiMonthly',
                  'Y','Yearly',
                  ' '
                  )
        INTO PRM_DURATION
        FROM DUAL;

END IF;
END IF;--Added on 02.09.2013 for DFCHOST-340
--prm_fee_attach:=v_tran_fee; --Commented on 02.09.2013 for DFCHOST-340
--Sn Added on 02.09.2013 for DFCHOST-340
       if v_card_activation='Y' and prm_tran_fee>0 then
            begin
                   update cms_acct_mast set cam_active_flag='Y'
                   where CAM_INST_CODE=prm_inst_code
                   and   CAM_ACCT_NO=prm_acct_number; 
             exception
                    when others then
                       PRM_ERROR := 'Error while updating cms_acct_mast' || SQLERRM;
                       RAISE EXP_MAIN;
             end;
      end if;
Exception
WHEN exp_nofees    THEN
    v_tran_fee := 0 ;
WHEN exp_main THEN
        prm_error := prm_error    ;
        prm_fee_attach := -1    ;
    WHEN OTHERS THEN
        prm_error := SQLERRM    ;
        prm_fee_attach := -1    ;
--En Added on 02.09.2013 for DFCHOST-340
END;
/
show error