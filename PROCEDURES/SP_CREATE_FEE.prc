CREATE OR REPLACE PROCEDURE  VMSCMS.SP_CREATE_FEE(
   instcode           IN       NUMBER,
   feetype            IN       NUMBER,
   feeamt             IN       NUMBER,
   feedesc            IN       VARCHAR2,
   delivery_channel   IN       VARCHAR2,
   intl_indicator     IN       VARCHAR2,
   approve_status     IN       VARCHAR2,
   --sivapragasam added on june 16 2012
   pin_signature      IN       VARCHAR2,
   tran_type          IN       VARCHAR2,
   tran_code          IN       VARCHAR2,
   tran_mode          IN       VARCHAR2,
   consodium_code     IN       NUMBER,
   partner_code       IN       NUMBER,
   currency_code      IN       VARCHAR2,
   per_fees           IN       NUMBER,
   min_fees           IN       NUMBER,
   spprt_key          IN       VARCHAR2,
   merccatgcode       IN       VARCHAR2,
      --ADDED BY VIKRANT MEHTA 14JULY08 FOR ADDING MERCHANT CATG IN DEFINE FEE
   -- Added by Trivikram on 11 June 2012 for Monthly Fee configuration
   assessment_type    IN       VARCHAR2,
   proration          IN       VARCHAR2,
   clawback           IN       VARCHAR2,
   freeTxnCount       IN       NUMBER,
   freeTxnPeriod      IN       VARCHAR2,
   feeAmtType         IN       VARCHAR2,
   normal_reversal    IN       VARCHAR2,
  maxlimit           IN       NUMBER DEFAULT 0, --MODIFIED FOR NCGPR-438 by Naila on 14-08-2013
   maxlimitfreq       IN       VARCHAR, --MODIFIED FOR NCGPR-438 by Naila on 14-08-2013
 
   feestartday        IN       VARCHAR2, --Added on 16.08.2013 for FWR-11
   feecapflag         IN       VARCHAR2, --Added on 16.08.2013 for FWR-11
   CR_FREEAMNT       IN       NUMBER, --Added for JH-13
   p_capAmount        IN       NUMBER, --Added for  lyfe host-61
   P_CRFREE_TXNCNT     IN       NUMBER, --Added on 20/12/13 for regarding JH-95,96,97,98
   
   LUPDUSER           IN       NUMBER,
  clawbackCount       IN       NUMBER, --Modified for FWR-64
  --DFCTNM-32
  clawbackOption       IN       VARCHAR2, 
  clawbackMaxAmt       IN       NUMBER, 
  firstMonthFeeAssessedDays       IN       NUMBER,  
   feecode            OUT      NUMBER,
   prm_errmsg         OUT      VARCHAR2
)
IS
   v_dmp1              NUMBER;
   v_dmp2              NUMBER;
   v_errmsg          VARCHAR2 (500);
   exp_un_violated   EXCEPTION;
/*************************************************
     * Modified By      :  Sivapragasam M
     * Modified Date    :  22-June-2012
     * Modified Reason  :  Fee changes
     * Reviewer         :  B.Besky Anand
     * Reviewed Date    :  22-June-2012
     * Build Number     :  CMS3.5.1_RI0010_B0013
     
     * Modified By      :  MageshKumar S
     * Modified Date    :  16-Aug-2013
     * Modified Reason  :  FWR-11
     * Build Number     :  RI0024.4_B0004
     
     * Modified By      :  Naila Uzma S.N
     * Modified Date    :  21-Aug-2013
     * Modified Reason  :  NCGPR-438
     * Reviewer         :  dhiraj
     * Reviewed Date    :  21-Aug-2013
     * Build Number     :  RI0024.4_B0004
     
     * Modified By      : Ravi N
     * Modified Date    : 19/09/13
     * Modified Reason  : JH-13 for FeeWaiver Monthly Fee
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-09-2013 
     * Build Number     : RI0024.5_B0001 

     * Modified By      :  Siva Kumar M
     * Modified Date    :  16-Oct-2013
     * Modified Reason  :  LYFEHOST-61
     * Reviewer         :  Dhiraj 
     * Reviewed Date    :  17-Oct-2013
     * Build Number     :  RI0024.6_B0001
     
     * Modified By      :  Sachin P.
     * Modified Date    :  23-Oct-2013
     * Modified For     :  LYFEHOST-61(Review changes)
     * Modified Reason  :  Review observation for LYFEHOST-61
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  23-Oct-2013
     * Build Number     :  RI0024.6_B0004

     * Modified By      : Ravi N
     * Modified Date    : 20/12/13
     * Modified Reason  : JH-95,96,97,98 for FeeWaiver Monthly Fee
     * Reviewer         : Dhiraj
     * Reviewed Date    : 20/12/13 
     * Build Number     : RI0027_B0003
     
     * Modified By      : Bhagya Sree B
     * Modified Date    : 23-MAY-2014
     * Modified Reason  : FWR-64
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3_B0001
	 
     * Modified By      : A.Sivakaminathan
     * Modified Date    : 25-Mar-2015
     * Modified Reason  : DFCTNM-32 Monthly Fee Assessment - First Fee in First Month / Clawback MaxAmt Limit
     * Reviewer         : 
     * Build Number     : VMSGPRHOSTCSD_3.0   
	 
 *************************************************/
BEGIN
   BEGIN
      v_errmsg := 'OK';
      prm_errmsg := 'OK';

-- SN FOR UNIQUE CONSTRAINT CHECK
      IF v_errmsg = 'OK'
      THEN
         BEGIN                    -- SN FOR UNIQUE CONSTRAINT CHECK SPPRT_FEE
            SELECT COUNT (1)
              INTO v_dmp1
              FROM cms_fee_mast
             WHERE cfm_inst_code =instcode --Added on 23.10.2013 for LYFEHOST-61(Review changes) 
             AND cfm_spprt_key = spprt_key AND cfm_fee_amt = feeamt;

            IF v_dmp1 > 0
            THEN
               v_errmsg :=
                  'Fee having same amount already defined for this support function';
               RAISE exp_un_violated;
            END IF;
         EXCEPTION
            WHEN exp_un_violated
            THEN
               RAISE;
           /*WHEN NO_DATA_FOUND
            THEN
               NULL;*/ --Commented on 23.10.2013 for LYFEHOST-61(Review changes)
            WHEN OTHERS
            THEN
               v_errmsg := 'Error from FEE_MAST for SPPRT_FEE ';
              -- RAISE; --Commented and modified on 23.10.2013 for LYFEHOST-61(Review changes)
               RAISE exp_un_violated;
         END;                      -- EN FOR UNIQUE CONSTRAINT CHECK SPPRT_FEE

         BEGIN                  ---SN FOR UNIQUE CONSTRAINT CHECK FOR TRAN_FEE
            SELECT COUNT (1)
              INTO v_dmp2
              FROM cms_fee_mast
             WHERE cfm_inst_code =instcode --Added on 23.10.2013 for LYFEHOST-61(Review changes) 
               and cfm_fee_amt = feeamt
               AND cfm_delivery_channel = delivery_channel
               AND CFM_INTL_INDICATOR = intl_indicator
               AND CFM_APPROVE_STATUS = approve_status
               AND CFM_PIN_SIGN = pin_signature
               AND cfm_tran_type = tran_type
               AND cfm_tran_code = tran_code
               AND cfm_tran_mode = tran_mode
               AND NVL (TRIM (cfm_consodium_code), -1) = consodium_code
               AND NVL (TRIM (cfm_partner_code), -1) = partner_code
               AND cfm_currency_code = currency_code
               AND NVL (TRIM (cfm_per_fees), -1) = per_fees
               AND NVL (TRIM (cfm_min_fees), -1) = min_fees
               AND NVL (TRIM (CFM_CAP_AMT), -1) = p_capAmount; -- added for lyfe host-61
               

            IF v_dmp2 > 0
            THEN
               v_errmsg := 'Fees with given parameter already defined';
               RAISE exp_un_violated;
            END IF;
         EXCEPTION
            WHEN exp_un_violated
            THEN
               RAISE;
            /*WHEN NO_DATA_FOUND
            THEN
               NULL;*/--Commented on 23.10.2013 for LYFEHOST-61(Review changes)
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting fee detail '
                  || SUBSTR (SQLERRM, 1, 200);
               -- RAISE; --Commented and modified on 23.10.2013 for LYFEHOST-61(Review changes)
               RAISE exp_un_violated;
         END;                   -- EN FOR UNIQUE CONSTRAINT CHECK FOR TRAN_FEE
      END IF;

-- EN FOR UNIQUE CONSTRAINT CHECK
      SELECT     cct_ctrl_numb
            INTO feecode
            FROM cms_ctrl_table
           WHERE cct_ctrl_code = TO_CHAR (instcode)       -- datatype mismatch
             AND cct_ctrl_key = 'FEE CODE'
      FOR UPDATE;
      --SN Added BEGIN .. END BLOCK (exception handling separately)for LYFEHOST-61(Review changes)
      BEGIN
      INSERT INTO cms_fee_mast
                  (cfm_inst_code, cfm_feetype_code, cfm_fee_code,
                   cfm_fee_amt, cfm_fee_desc, cfm_ins_user, cfm_ins_date,
                   cfm_lupd_user, cfm_lupd_date,
                   cfm_delivery_channel,
                   cfm_tran_type, cfm_tran_code, cfm_tran_mode,
                   cfm_consodium_code,
                   cfm_partner_code,
                   cfm_currency_code, cfm_per_fees,
                   cfm_min_fees, cfm_spprt_key,
                   cfm_merc_code,
      --ADDED BY VIKRANT MEHTA 14JULY08 FOR ADDING MERCHANT CATG IN DEFINE FEE
                   CFM_DATE_ASSESSMENT,CFM_PRORATION_FLAG,CFM_CLAWBACK_FLAG,
                   CFM_DURATION, CFM_FREE_TXNCNT, CFM_FEEAMNT_TYPE,
                   CFM_INTL_INDICATOR,CFM_APPROVE_STATUS,CFM_PIN_SIGN,CFM_NORMAL_RVSL,CFM_DATE_START,CFM_FEECAP_FLAG --Added on 16.08.2013 for FWR-11
           ,CFM_MAX_LIMIT,CFM_MAXLMT_FREQ, --MODIFIED FOR NCGPR-438 by Naila on 14-08-2013
                   CFM_TXNFREE_AMT, --Added on 19/09/13 by Ravi N for regardin JH-13
                   CFM_CRFREE_TXNCNT, --Added on 20/12/13 by Ravi N for regardin JH-95-98
                   CFM_CAP_AMT , --Added   for lyfehost-61 changes
                   CFM_CLAWBACK_COUNT, --Modified for FWR-64
                   --DFCTNM-32
                   CFM_CLAWBACK_TYPE,
                   CFM_CLAWBACK_MAXAMT,
                   CFM_ASSESSED_DAYS                     				   
                  )
           VALUES (instcode, feetype, feecode,
                   feeamt, UPPER (feedesc), lupduser, SYSDATE,
                   lupduser, SYSDATE,
                   DECODE (delivery_channel, -1, NULL, delivery_channel),
                   tran_type, tran_code, tran_mode,
                   DECODE (consodium_code, -1, NULL, consodium_code),
                   DECODE (partner_code, -1, NULL, partner_code),
                   currency_code, DECODE (per_fees, -1, NULL, per_fees),
                   DECODE (min_fees, -1, NULL, min_fees), spprt_key,
                   merccatgcode,
      --ADDED BY VIKRANT MEHTA 14JULY08 FOR ADDING MERCHANT CATG IN DEFINE FEE
                   assessment_type,proration,clawback, freeTxnPeriod, freeTxnCount, feeAmtType,
                   intl_indicator,approve_status,pin_signature,normal_reversal,feestartday,feecapflag --Added on 16.08.2013 for FWR-11
           ,maxlimit,maxlimitfreq, --MODIFIED FOR NCGPR-438 by Naila on 14-08-2013                   
                    CR_FREEAMNT, --Added on 19/09/13 by Ravi N for regardin JH-13
                    P_CRFREE_TXNCNT,-- Newly added  on 20/12/13 by Ravi N for regarding JH-13
                    DECODE (P_CAPAMOUNT, -1, NULL, P_CAPAMOUNT),--Added   for lyfehost-61 changes
                    clawbackCount, --Modified for FWR-64
                    --DFCTNM-32
                    clawbackOption, 
                    clawbackMaxAmt, 
                    firstMonthFeeAssessedDays               					
                   );
      EXCEPTION             
      WHEN DUP_VAL_ON_INDEX THEN
             v_errmsg:= 'Fees with given parameter and description already defined' ;
           RAISE exp_un_violated;
      WHEN OTHERS
          THEN
            v_errmsg := 'Excp 1 Error while inserting data in fee master ' || '---' || SUBSTR(SQLERRM,1,200);
             RAISE exp_un_violated;                              
      END;   
      --EN Added BEGIN .. END BLOCK (exception handling separately)for LYFEHOST-61(Review changes)
             
      --SN Added BEGIN .. END BLOCK (exception handling separately)for LYFEHOST-61(Review changes)
      BEGIN
      UPDATE cms_ctrl_table
         SET cct_ctrl_numb = cct_ctrl_numb + 1,
             cct_lupd_user = lupduser
       WHERE cct_ctrl_code = TO_CHAR (instcode)           -- datatype mismatch
         AND cct_ctrl_key = 'FEE CODE';
      EXCEPTION
      WHEN EXP_UN_VIOLATED THEN
         RAISE;
      WHEN OTHERS THEN 
        v_errmsg := 'Error while updaing control number ' || '---' || substr(SQLERRM,1,200);
         RAISE exp_un_violated;   
      END;   
      --EN Added BEGIN .. END BLOCK (exception handling separately)for LYFEHOST-61(Review changes)

      v_errmsg := 'OK';
   EXCEPTION
    --SN Commented and handled up on 23.010.2013 for LYFEHOST-61(Review changes)
    /*WHEN DUP_VAL_ON_INDEX THEN
             v_errmsg:= 'Fees with given parameter and description already defined' ;
           RAISE exp_un_violated; */                                       --Exception 1
    --EN Commented and handled up on 23.010.2013 for LYFEHOST-61(Review changes)
      WHEN exp_un_violated
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         feecode := 1;
         
         --SN Added BEGIN .. END BLOCK (exception handling separately)for LYFEHOST-61(Review changes)
         BEGIN  
         INSERT INTO cms_fee_mast
                     (cfm_inst_code, cfm_feetype_code, cfm_fee_code,
                      cfm_fee_amt, cfm_fee_desc, cfm_ins_user, cfm_ins_date,
                      cfm_lupd_user, cfm_lupd_date,
                      cfm_delivery_channel,
                      cfm_tran_type, cfm_tran_code, cfm_tran_mode,
                      cfm_consodium_code,
                      cfm_partner_code,
                      cfm_currency_code, cfm_per_fees,
                      cfm_min_fees, cfm_spprt_key,
                      cfm_merc_code,
      --ADDED BY VIKRANT MEHTA 14JULY08 FOR ADDING MERCHANT CATG IN DEFINE FEE
                      CFM_DATE_ASSESSMENT,CFM_PRORATION_FLAG,CFM_CLAWBACK_FLAG,
                      CFM_DURATION, CFM_FREE_TXNCNT, CFM_FEEAMNT_TYPE,
                      CFM_INTL_INDICATOR,CFM_APPROVE_STATUS,CFM_PIN_SIGN,CFM_NORMAL_RVSL,CFM_DATE_START,CFM_FEECAP_FLAG --Added on 16.08.2013 for FWR-11
              ,CFM_MAX_LIMIT,CFM_MAXLMT_FREQ, --MODIFIED FOR NCGPR-438 by Naila on 14-08-2013                      
                     CFM_TXNFREE_AMT, --Added on 19/09/13 by Ravi N for regardin JH-13
                     CFM_CAP_AMT,--Added   for lyfehost-61 changes
                    CFM_CLAWBACK_COUNT,  --Modified for FWR-64
                   --DFCTNM-32
                   CFM_CLAWBACK_TYPE,
                   CFM_CLAWBACK_MAXAMT,
                   CFM_ASSESSED_DAYS                                        					
                     )
              VALUES (instcode, feetype, feecode,
                      feeamt, UPPER (feedesc), lupduser, SYSDATE,
                      lupduser, SYSDATE,
                      DECODE (delivery_channel, -1, NULL, delivery_channel),
                      tran_type, tran_code, tran_mode,
                      DECODE (consodium_code, -1, NULL, consodium_code),
                      DECODE (partner_code, -1, NULL, partner_code),
                      currency_code, DECODE (per_fees, -1, NULL, per_fees),
                      DECODE (min_fees, -1, NULL, min_fees), spprt_key,
                      merccatgcode,
      --ADDED BY VIKRANT MEHTA 14JULY08 FOR ADDING MERCHANT CATG IN DEFINE FEE
                      assessment_type,proration,clawback, freeTxnPeriod , freeTxnCount, feeAmtType,
                      intl_indicator,approve_status,pin_signature,normal_reversal,feestartday,feecapflag --Added on 16.08.2013 for FWR-11
              ,maxlimit,maxlimitfreq, --MODIFIED FOR NCGPR-438 by Naila on 14-08-2013
                      CR_FREEAMNT, --Added on 19/09/13 by Ravi N for regardin JH-13
                      DECODE (P_CAPAMOUNT, -1, NULL, P_CAPAMOUNT) , --Added   for lyfehost-61 changes
                     clawbackCount, --modified for FWR-64
                    --DFCTNM-32
                    clawbackOption, 
                    clawbackMaxAmt, 
                    firstMonthFeeAssessedDays                     					 
                      );
         EXCEPTION
         WHEN EXP_UN_VIOLATED THEN
           RAISE;
         WHEN OTHERS THEN
         v_errmsg := 'Excp 2 Error while inserting data in fee master ' || '---' || SUBSTR(SQLERRM,1,200);
             RAISE exp_un_violated;                
         END;     
        --EN Added BEGIN .. END BLOCK (exception handling separately)for LYFEHOST-61(Review changes)         
        
        --SN Added BEGIN .. END BLOCK (exception handling separately)for LYFEHOST-61(Review changes)   
         BEGIN
         INSERT INTO cms_ctrl_table
                     (cct_ctrl_code, cct_ctrl_key, cct_ctrl_numb,
                      cct_ctrl_desc,
                      cct_ins_user, cct_lupd_user
                     )
              VALUES (instcode, 'FEE CODE', 2,
                      'Fee Code for institution ' || instcode || ' .',
                      lupduser, lupduser
                     );
         EXCEPTION
         WHEN EXP_UN_VIOLATED THEN
           RAISE;
         WHEN OTHERS THEN              
          v_errmsg := 'Excp 2 Error while inserting data in CTRL table' || '---' || SUBSTR(SQLERRM,1,200);
          RAISE exp_un_violated;            
         END;            
        --EN Added BEGIN .. END BLOCK (exception handling separately)for LYFEHOST-61(Review changes)

         v_errmsg := 'OK';
      WHEN OTHERS
      THEN
        --v_errmsg := 'Excp 1 ' || '---' || SQLERRM; --Commented and modified for LYFEHOST-61(Review changes)
        v_errmsg := 'Excp 1 ' || '---' || SUBSTR(SQLERRM,1,200);
         RAISE exp_un_violated;
   END;

   prm_errmsg := 'OK';
EXCEPTION
   WHEN exp_un_violated
   THEN
      prm_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      v_errmsg := 'Main Exception ' || '---' || SQLERRM;
      prm_errmsg := v_errmsg;
END; 
/
SHOW ERROR