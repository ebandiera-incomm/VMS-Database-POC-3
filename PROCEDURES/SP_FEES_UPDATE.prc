CREATE OR REPLACE PROCEDURE VMSCMS.SP_FEES_UPDATE(
   p_cfm_inst_code      IN       NUMBER,
   p_cfm_feetype_code   IN       NUMBER,
   p_cfm_fee_code       IN       NUMBER,
   p_cfm_fee_amt        IN       NUMBER,
   p_cfm_fee_desc       IN       VARCHAR2,
   p_cfm_delivery_channel       IN       VARCHAR2,
   p_cfm_intl_indicator     IN       VARCHAR2,
   p_cfm_approve_status     IN       VARCHAR2,
   --sivapragasam added on june 16 2012
   p_cfm_pin_signature      IN       VARCHAR2,
   p_cfm_tran_type       IN       VARCHAR2,
   p_cfm_tran_code       IN       VARCHAR2,
   p_cfm_tran_mode       IN       VARCHAR2,
   p_cfm_consodium_code       IN       NUMBER,
   p_cfm_partner_code       IN       NUMBER,
   p_cfm_currency_code       IN       VARCHAR2,
   p_cfm_per_fees       IN       NUMBER,
   p_cfm_min_fees       IN       NUMBER,
   p_cfm_spprt_key      IN       VARCHAR2,
   p_cfm_merc_code      IN       VARCHAR2,

   -- Added by Trivikram on 11 June 2012 for Monthly Fee configuration
   p_assessment_type    IN       VARCHAR2,
   p_proration          IN       VARCHAR2,
   p_clawback           IN       VARCHAR2,
   p_freeTxnCount       IN       NUMBER,
   p_freeTxnPeriod      IN       VARCHAR2,
   p_feeAmtType         IN       VARCHAR2,
   p_normal_rvsl        IN       VARCHAR2,
   p_maxlimit           IN       NUMBER, --MODIFIED FOR NCGPR-438 by Naila on 14-08-2013
   p_maxlimitfreq       IN       VARCHAR2, --MODIFIED FOR NCGPR-438 by Naila on 14-08-2013
   p_feecap_flag        IN       VARCHAR2,  --Added on 16.08.2013 for FWR-11
   p_date_start         IN       VARCHAR2,  --Added on 26.08.2013 for Defect id :15714
   p_freeTxn_amt        IN       NUMBER,     --Added by Ravi N on 25/09/13 for regarding JH-13
   p_cap_amt            IN       NUMBER,     --Added for lyfehost-61
   P_CRFREE_TXNCNT     IN       NUMBER, --Added on 20/12/13 for regarding JH-95,96,97,98
   P_CFM_LUPD_USER      IN       NUMBER,
   p_clawbackCount      IN       NUMBER,--Modified for FWR-64
   --DFCTNM-32
   p_clawbackOption       IN       VARCHAR2, 
   p_clawbackMaxAmt       IN       NUMBER, 
   p_firstMonthFeeAssessedDays       IN       NUMBER,      
   p_err                OUT      VARCHAR2
)
AS
   v_error               VARCHAR2 (100);
   v_message             NUMBER;
   v_count_prod          NUMBER         DEFAULT 0;
   v_count_prodcattype   NUMBER         DEFAULT 0;
   v_count_cardfee       NUMBER         DEFAULT 0;
   v_maxlimit            NUMBER; --Added for NCGPR-438 by Naila on 14-08-2013
   v_maxlimitfreq        VARCHAR2 (1); --Added for NCGPR-438 by Naila on 14-08-2013
   CURSOR FEECUR IS SELECT * FROM CMS_ACCTLVL_FEELIMIT WHERE
   CAF_INST_CODE   =p_cfm_inst_code  --Added for LYFEHOST-61(Review changes)
   AND CAF_FEE_CODE=p_cfm_fee_code;--Added for NCGPR-438
   v_maxlimit_used            NUMBER;--Added for NCGPR-438
   EXP_REJECT_RECORD          EXCEPTION;--Added for LYFEHOST-61(Review changes)
   v_exists                  NUMBER(1) ;--Added for LYFEHOST-61(Review changes)
     
/*************************************************
     * Modified By      :  Sivapragasam M
     * Modified Date    :  22-June-2012
     * Modified Reason  :  Fee changes
     * Reviewer         :  B.Besky Anand
     * Reviewed Date    :  21-June-2012
     * Build Number     :  CMS3.5.1_RI0010_B0013
    
     * Modified By      :  MageshKumar S
     * Modified Date    :  16-Aug-2013
     * Modified Reason  :  FWR-11
     * Build Number     :  RI0024.4_B0004
     
     * Modified By      :  Naila Uzma S.N
     * Modified Date    :  21-Aug-2013
     * Modified Reason  :  NCGPR-438
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  21-Aug-2013
     * Build Number     :  RI0024.4_B0004
     
     * Modified By      : Ravi N
     * Modified Date    : 25-Sep-2013
     * Modified Reason  : JH_13
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-09-2013
     * Build Number     : RI0024.5_B0001
     
     * Modified By      : Siva Kumar M
     * Modified Date    : 16-Oct-2013
     * Modified Reason  : LYFEHOST-61
     * Reviewer         : Dhiraj 
     * Reviewed Date    : 17-Oct-2013
     * Build Number     : RI0024.6_B0001
     
     * Modified By      :  Sachin P.
     * Modified Date    :  23-Oct-2013
     * Modified For     :  LYFEHOST-61(Review changes)
     * Modified Reason  :  Review observation for LYFEHOST-61
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  23-Oct-2013
     * Build Number     :  RI0024.6_B0004
     
     * Modified By      : Ravi N
     * Modified Date    : 20-DEC-2013
     * Modified Reason  : JH-95-98
     * Reviewer         : Dhiraj
     * Reviewed Date    : 20-DEC-2013
     * Build Number     : RI0027_B0003
     
     * Modified By      : Bhagya Sree B
     * Modified Date    : 23-MAY-2014
     * Modified Reason  : FWR-64
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3_B0001
     
     * Modified By      : Ramesh
     * Modified Date    : 26-AUG-2014
     * Modified Reason  : Defect id :15714
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3.1_B0006
	 
     * Modified By      : A.Sivakaminathan
     * Modified Date    : 25-Mar-2015
     * Modified Reason  : DFCTNM-32 Monthly Fee Assessment - First Fee in First Month / Clawback MaxAmt Limit
     * Reviewer         : 
     * Build Number     : VMSGPRHOSTCSD_3.0
	 
 ***********************************************/
BEGIN
   p_err := 'OK';
   v_exists := 0 ;--Added for LYFEHOST-61(Review changes)

    BEGIN
      SELECT COUNT (cpf_fee_code)
        INTO v_count_prod
        FROM cms_prod_fees
       WHERE cpf_inst_code = p_cfm_inst_code
         AND cpf_fee_type = p_cfm_feetype_code
         AND cpf_fee_code = p_cfm_fee_code
         AND TRUNC (cpf_valid_from) <= TRUNC (SYSDATE);
   EXCEPTION
    --SN Commented for LYFEHOST-61(Review changes)
      /*WHEN NO_DATA_FOUND
      THEN
         v_count_prod := 0;*/
    --EN Commented for LYFEHOST-61(Review changes)         
      WHEN OTHERS
      THEN
         --p_err := 'Exception ' || SQLCODE || '---' || SQLERRM; --Commented AND modified for LYFEHOST-61(Review changes)
         p_err := 'Error while selecting count from prod fees --'||SUBSTR(SQLERRM,1,200);
         RAISE EXP_REJECT_RECORD;
   END;

   BEGIN
      SELECT COUNT (cpf_fee_code)
        INTO v_count_prodcattype
        FROM cms_prodcattype_fees
       WHERE cpf_inst_code = p_cfm_inst_code
         AND cpf_fee_type = p_cfm_feetype_code
         AND cpf_fee_code = p_cfm_fee_code
         AND TRUNC (cpf_valid_from) <= TRUNC (SYSDATE);
   EXCEPTION
   --SN Commented for LYFEHOST-61(Review changes)
      /*WHEN NO_DATA_FOUND
      THEN
         v_count_prodcattype := 0;*/
   --EN Commented for LYFEHOST-61(Review changes)      
      WHEN OTHERS
      THEN
      --   p_err := 'Exception ' || SQLCODE || '---' || SQLERRM;--Commented AND modified for LYFEHOST-61(Review changes)
       p_err := 'Error while selecting count from prodcattype fees --'||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;
   END;

   BEGIN
      SELECT COUNT (cce_fee_code)
        INTO v_count_cardfee
        FROM cms_card_excpfee
       WHERE cce_inst_code = p_cfm_inst_code
         AND cce_fee_type = p_cfm_feetype_code
         AND cce_fee_code = p_cfm_fee_code
         AND TRUNC (cce_valid_from) <= TRUNC (SYSDATE);
   EXCEPTION
   --SN Commented for LYFEHOST-61(Review changes)
      /*WHEN NO_DATA_FOUND
      THEN
         v_count_cardfee := 0;*/
   --EN Commented for LYFEHOST-61(Review changes)         
      WHEN OTHERS
      THEN
      --   p_err := 'Exception ' || SQLCODE || '---' || SQLERRM;--Commented AND modified for LYFEHOST-61(Review changes)
       p_err := 'Error while selecting count from cardexpfees --'||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;
   END;

   IF (v_count_prodcattype > 0) OR (v_count_cardfee > 0) OR (v_count_prod > 0)
   THEN
      p_err := 'This Fee Is already Attached';
      RAISE EXP_REJECT_RECORD;--Added for LYFEHOST-61(Review changes)
   ELSE
    --NCGPR-438 change starts by Naila on 14-08-2013
      BEGIN
        SELECT CFM_MAX_LIMIT,CFM_MAXLMT_FREQ
                INTO v_maxlimit,v_maxlimitfreq
                FROM cms_fee_mast
                WHERE cfm_inst_code = p_cfm_inst_code
                      AND cfm_feetype_code = p_cfm_feetype_code
                      AND cfm_fee_code = p_cfm_fee_code;
          EXCEPTION
           --SN Added for LYFEHOST-61(Review changes)
           WHEN NO_DATA_FOUND 
           THEN
               p_err := 'Fee not defined for institution code ='||p_cfm_inst_code ||' ,fee code ='|| p_cfm_fee_code ||' and fee type code ='||p_cfm_feetype_code;
               RAISE EXP_REJECT_RECORD;
           --EN Added for LYFEHOST-61(Review changes)            
            WHEN OTHERS
            THEN
             --   p_err := 'Exception ' || SQLCODE || '---' || SQLERRM;--Commented AND modified for LYFEHOST-61(Review changes)
            p_err := 'Error while selecting max limit and frequency --'||SUBSTR(SQLERRM,1,200);
            RAISE EXP_REJECT_RECORD;
      END;
      --NCGPR-438 change ends
      BEGIN
         UPDATE cms_fee_mast
            SET cfm_fee_amt = p_cfm_fee_amt,
                cfm_fee_desc = p_cfm_fee_desc,
                cfm_delivery_channel = p_cfm_delivery_channel,
                CFM_INTL_INDICATOR = p_cfm_intl_indicator,
                CFM_APPROVE_STATUS = p_cfm_approve_status,
                CFM_PIN_SIGN = p_cfm_pin_signature,
                cfm_tran_type = p_cfm_tran_type,
                cfm_normal_rvsl = p_normal_rvsl,
                cfm_tran_code = p_cfm_tran_code,
                cfm_tran_mode = p_cfm_tran_mode,
                cfm_consodium_code = DECODE (p_cfm_consodium_code, -1, NULL, p_cfm_consodium_code),
                cfm_partner_code = DECODE (p_cfm_partner_code, -1, NULL, p_cfm_partner_code),
                cfm_currency_code = p_cfm_currency_code,
                cfm_per_fees = DECODE (p_cfm_per_fees, -1, NULL, p_cfm_per_fees),
                cfm_min_fees = DECODE (p_cfm_min_fees, -1, NULL, p_cfm_min_fees),
                cfm_spprt_key = p_cfm_spprt_key,
                cfm_merc_code = p_cfm_merc_code,
                CFM_DATE_ASSESSMENT = p_assessment_type,
                CFM_CLAWBACK_FLAG = P_CLAWBACK,
                CFM_CLAWBACK_COUNT=p_clawbackCount,--Modified for FWR-64
                CFM_PRORATION_FLAG = p_proration,
                CFM_DURATION = p_freeTxnPeriod,
                CFM_FREE_TXNCNT = p_freeTxnCount,
                CFM_FEEAMNT_TYPE = p_feeAmtType, -- Added by Trivikram on 15 June 2012 for montly fee and free txn count configuration
                CFM_FEECAP_FLAG = p_feecap_flag, --Added on 16.08.2013 for FWR-11
                CFM_MAX_LIMIT=p_maxlimit, --MODIFIED FOR NCGPR-438
                CFM_MAXLMT_FREQ=p_maxlimitfreq, --MODIFIED FOR NCGPR-438
                CFM_TXNFREE_AMT=p_freeTxn_amt, --Added on 25/09/13  by Ravi N for regarding JH-13 
                CFM_CAP_AMT =DECODE (p_cap_amt, -1, NULL, p_cap_amt), -- Added  for lyfe host-61 changes.
                CFM_CRFREE_TXNCNT=P_CRFREE_TXNCNT,-- Added on 20-12-13 for JH-95-98
                cfm_date_start=p_date_start,  --Added on 26.08.2013 for Defect id :15714
                --DFCTNM-32
                CFM_CLAWBACK_TYPE=p_clawbackOption,
                CFM_CLAWBACK_MAXAMT=p_clawbackMaxAmt,
                CFM_ASSESSED_DAYS=p_firstMonthFeeAssessedDays            				
          WHERE cfm_inst_code = p_cfm_inst_code
            AND cfm_feetype_code = p_cfm_feetype_code
            AND cfm_fee_code = p_cfm_fee_code;

         IF SQL%ROWCOUNT = 0
         THEN
          --  p_err := 'Error while updating fee_mast';--Commented AND modified for LYFEHOST-61(Review changes)
            p_err := 'No records updated in fee master';
            RAISE EXP_REJECT_RECORD;
         END IF;
      EXCEPTION
         WHEN VALUE_ERROR
         THEN
            p_err := 'value eror come while updating cms_fee_mast';
            RAISE EXP_REJECT_RECORD;--Added for LYFEHOST-61(Review changes)
         WHEN OTHERS
         THEN
            --p_err := 'Error while updating fee mast';--Commented AND modified for LYFEHOST-61(Review changes)
            p_err := 'Error while updating fee mast--'||SUBSTR(SQLERRM,1,200);
            RAISE EXP_REJECT_RECORD;
      END;
      
      --NCGPR-438 change starts by Naila on 14-08-2013
      BEGIN
    
          IF (v_maxlimit>=0 AND v_maxlimit<>p_maxlimit) OR 
          (v_maxlimit>0 AND v_maxlimit<>p_maxlimit AND v_maxlimitfreq<>p_maxlimitfreq)OR
          (v_maxlimit>0 AND v_maxlimitfreq<>p_maxlimitfreq) THEN
              BEGIN
                  FOR i IN FEECUR
                    LOOP
                    
                     v_exists := 1;
                    
                      BEGIN
                          BEGIN
                                INSERT INTO CMS_ACCTLVL_FEELIMIT_HIST(CAH_ACCT_ID,
                                              CAH_FEE_CODE,
                                              CAH_LIMIT_USED,
                                              CAH_MAX_LIMIT,
                                              CAH_FREQ_TYPE,
                                              CAH_INS_DATE,
                                              CAH_INST_CODE)
                                        VALUES(i.caf_acct_id,
                                        i.caf_fee_code,
                                        i.caf_max_limit,
                                        v_maxlimit,
                                        v_maxlimitfreq,
                                        SYSDATE,
                                        i.caf_inst_code                                        
                                        );
                               EXCEPTION
                                WHEN OTHERS
                                THEN
                                  --p_err := 'Exception while inserting in CMS_ACCTLVL_FEELIMIT_HIST' || SQLCODE ||'---' || SQLERRM;
                                  --Commented AND modified for LYFEHOST-61(Review changes)
                                  p_err := 'Exception while inserting in CMS_ACCTLVL_FEELIMIT_HIST ' ||SUBSTR(SQLERRM,1,200);
                                  RAISE EXP_REJECT_RECORD;
                          END;
                          
                          --SN Commented AND moved down for LYFEHOST-61(Review changes)
                          /*BEGIN
                         
                              DELETE FROM CMS_ACCTLVL_FEELIMIT 
                              WHERE CAF_INST_CODE = i.caf_inst_code
                              AND CAF_FEE_CODE = i.caf_fee_code;
                           EXCEPTION
                                WHEN OTHERS
                                THEN
                                  p_err := 'Exception while deleting from CMS_ACCTLVL_FEELIMIT  ' || SQLCODE || '---' || SQLERRM;
                          END;*/ 
                          --EN Commented AND moved down for LYFEHOST-61(Review changes)
                      END;
                    END LOOP;
                    
                   --SN Added AND moved herefor LYFEHOST-61(Review changes)                   
                   IF v_exists = 1 THEN
                     BEGIN                         
                              DELETE FROM CMS_ACCTLVL_FEELIMIT 
                              WHERE CAF_INST_CODE = p_cfm_inst_code
                              AND CAF_FEE_CODE = p_cfm_fee_code;
                              
                            IF SQL%ROWCOUNT = 0
                            THEN                            
                              p_err := 'No records deleted from accont level fee master';
                              RAISE EXP_REJECT_RECORD;
                            END IF;        
                              
                     EXCEPTION
                     WHEN OTHERS
                     THEN                   
                        p_err := 'Exception while deleting from CMS_ACCTLVL_FEELIMIT  ' ||SUBSTR(SQLERRM,1,200);
                        RAISE EXP_REJECT_RECORD;
                     END; 
                   END IF;     
                  --EN Added AND moved herefor LYFEHOST-61(Review changes) 
                                    
              END;
          END IF;
        END;
       --NCGPR-438 change ends
   END IF;
EXCEPTION
  --SN  Added for LYFEHOST-61(Review changes)
   WHEN EXP_REJECT_RECORD
   THEN 
     p_err :=p_err ;
  --EN  Added for LYFEHOST-61(Review changes)   
   WHEN OTHERS
   THEN
    --  p_err := 'Main Exception ' || SQLCODE || '---' || SQLERRM; --Commented AND modified down for LYFEHOST-61(Review changes)
      p_err := 'Main Exception ' ||substr(SQLERRM,1,200);
END; 
/
SHOW ERROR