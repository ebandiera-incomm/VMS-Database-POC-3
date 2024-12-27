create or replace
PROCEDURE               VMSCMS.SP_IVR_GPR_CARD_ACTIVATE(P_INSTCODE    IN NUMBER,
                                                      P_CARDNUM          IN VARCHAR2,
                                                      P_RRN              IN VARCHAR2,    -- added for mvcsd-4099 additional changes on 14/Sept/2013
                                                      P_TRANDATE         IN VARCHAR2,     -- added for mvcsd-4099 additional changes on 14/Sept/2013
                                                      P_TRANTIME         IN VARCHAR2,    -- added for mvcsd-4099 additional changes on 14/Sept/2013
                                                      P_AUTH_ID          IN VARCHAR2,     -- added for mvcsd-4099 additional changes on 14/Sept/2013
                                                      P_RESP_CODE        OUT VARCHAR2,
                                                      P_ERRMSG           OUT VARCHAR2,
                                                      p_closed_card      IN  OUT VARCHAR2) AS

/*************************************************
     * Created Date     :  10-Dec-2011
     * Created By       :  Sivapragasam
     * PURPOSE          :  For Startercard
     * Reviewer         :  Nanda Kumar R.
     * Reviewed Date    :  21-May-2012
     * Build Number     : CMS3.5.1_RI0021.1_B0002
     * Modified By      :  Ramesh.A
     * Modified Date    :  19/NOV/2012
     * Modified Reason  :  Activation of GPR card if doesnt have startercard.
     
     
    * Modified By      : Siva Kumar M
    * Modified Date    : 14/Sept/2013
    * Modified Reason  : MVCSD-4099 Additional changes
    * Reviewer         : dhiraj
    * Reviewed Date    : 
    * Build Number     :RI0024.4_B0012
    
    * Modified By      : Ramesh
    * Modified Date    : 06/Mar/2013
    * Modified Reason  : MVCSD-4121 and FWR-43
    * Reviewer         : Dhiraj
    * Reviewed Date    : 06/Mar/2013
    * Build Number     : RI0027.2_B0002
    
    * Modified By      : Dinesh
    * Modified Date    : 06/Mar/2013
    * Modified Reason  : Review changes done for MVCSD-4121 and FWR-43
    * Reviewer         : Pankaj S.
    * Reviewed Date    : 01-April-2014
    * Build Number     : RI0027.2_B0003
    
    * Modified By      : Magesh
    * Modified Date    : 1/Apr/2016
    * Modified Reason  : VP-543
    * Reviewer         : Pankaj S.
    * Reviewed Date    : 01-April-2016
    * Build Number     : 
    
    * Modified by          : MageshKumar S.
    * Modified Date        : 19-July-16
    * Modified For         : FSS-4423
    * Modified reason      : Token LifeCycle Changes
    * Reviewer             : Saravanan/Spankaj
    * Build Number         : VMSGPRHOSTCSD4.6_B0001
    
    
      * Modified by          : Saravankumar A
    * Modified Date        : 07-September-16
    * Modified reason      : Performance Changes
    * Reviewer             : Spankaj
    * Build Number         : VMSGPRHOSTCSD4.9
    
    * Modified by          : T.Narayanaswamy
    * Modified Date        : 05-May-17
    * Modified reason      : B2B config moved to Category Level beg
    * Reviewer             : Saravanakumar
    * Build Number         : VMSGPRHOST_17.05    
    
    * Modified by          : Pankaj S.
    * Modified Date        : 23-May-17
    * Modified For         : FSS-5135 -Changes in Card replacement / renewal logic
    * Reviewer             : Saravanan
    * Build Number         : VMSGPRHOST_17.05    
     
 *************************************************/
  V_HASH_PAN            CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN            CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  EXP_MAIN_REJECT_RECORD EXCEPTION;
  V_RESPCODE        VARCHAR2(5);
  V_CAP_CARD_STAT   CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_FIRSTTIME_TOPUP CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_ACCT_NUMBER         CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_CAP_PROD_CATG       VARCHAR2(100);
  V_CAP_CAFGEN_FLAG CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
  V_APPL_CODE       CMS_APPL_MAST.CAM_APPL_CODE%TYPE;  
  V_MBRNUMB         CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  V_CUST_CODE           CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
  V_PROXUNUMBER         CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_STARTER_CARD       CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  
  /* START  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
  V_PROD_CODE CMS_APPL_PAN.CAP_PROD_CODE%type ; 
  V_CARD_TYPE CMS_APPL_PAN.CAP_CARD_TYPE%type ;
  V_INST_CODE CMS_APPL_PAN.CAP_INST_CODE%type ;
  v_lmtprfl         cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
  v_profile_level   cms_appl_pan.cap_prfl_levl%TYPE;  -- NUMBER (2);  --added by amit on 20-Jul-2012 for activation part in LIMITS modified by type Dhiraj
 /* END  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
   V_KYC_FLAG     CMS_CAF_INFO_ENTRY.CCI_KYC_FLAG%TYPE;  -- added for mvcsd-4099 additional changes on 14/Sept/2013
V_RENEWAL_CARD_HASH  CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  --Added for MVCSD-4121 & FWR-43
V_RENEWAL_CARD_ENCR  CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE; --Added for MVCSD-4121 & FWR-43

--l_b2bcard_status        cms_product_param.cpp_b2bcard_stat%TYPE;--added for B2B Card status change--added for B2B Card status change
l_b2bcard_status        CMS_APPL_PAN.CAP_CARD_STAT%TYPE; -- Changed to Product Category since B2B config moved to Category Level beg
v_oldcrd_clear varchar2(19);
l_user_id_type 		cms_prod_cattype.cpc_user_identify_type%type;
BEGIN

  P_ERRMSG := 'OK';
  P_RESP_CODE :='00';

  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_CARDNUM);
  EXCEPTION
    WHEN OTHERS THEN
     P_ERRMSG := 'Error while converting hash pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_CARDNUM);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '12';
     P_ERRMSG   := 'Error while converting encryption pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;


  --Sn select Pan detail
  BEGIN
    SELECT CAP_CARD_STAT,
           CAP_PROD_CATG,
           CAP_CAFGEN_FLAG,
           CAP_APPL_CODE,
           CAP_FIRSTTIME_TOPUP,
           CAP_MBR_NUMB,
           CAP_CUST_CODE,
           CAP_PROXY_NUMBER,
           CAP_ACCT_NO,
           CAP_PROD_CODE , -- Added by Dhiraj G Limits BRD 
           CAP_CARD_TYPE , -- Added by Dhiraj G Limits BRD 
           CAP_INST_CODE,--Added by Dhiraj G Limits BRD
           CAP_PRFL_CODE, -- Added on 30102012 Dhiraj 
             CAP_PRFL_LEVL -- Added on 30102012 Dhiraj 
      INTO V_CAP_CARD_STAT,
           V_CAP_PROD_CATG,
           V_CAP_CAFGEN_FLAG,
           V_APPL_CODE,
           V_FIRSTTIME_TOPUP,
           V_MBRNUMB,
           V_CUST_CODE,
           V_PROXUNUMBER,
           V_ACCT_NUMBER,
           V_PROD_CODE , -- Added by Dhiraj G Limits BRD 
           V_CARD_TYPE  ,-- Added by Dhiraj G Limits BRD 
           V_INST_CODE, --Added by Dhiraj G Limits BRD
            v_lmtprfl ,-- Added on 30102012 Dhiraj 
             v_profile_level  -- Added on 30102012 Dhiraj            
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN; -- P_acctno;

  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     P_ERRMSG := 'Invalid Card number ' || P_CARDNUM;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     P_ERRMSG := 'Error while selecting appl pan details for card number ' || P_CARDNUM;
     RAISE EXP_MAIN_REJECT_RECORD;

  END;
  
  -- Sn changes for MVCSD-4099 Additional changes on  14/Sept/2013
  
   BEGIN
       SELECT CCI_KYC_FLAG
       INTO V_KYC_FLAG
       FROM CMS_CAF_INFO_ENTRY
       WHERE CCI_INST_CODE=P_INSTCODE
       AND CCI_APPL_CODE=to_char(V_APPL_CODE);
       
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '21';
       P_ERRMSG   := 'KYC FLAG not found ';
       RAISE  EXP_MAIN_REJECT_RECORD;
   WHEN OTHERS THEN
      V_RESPCODE := '21';
      P_ERRMSG   := 'Error while selecting data from caf_info ' ||SUBSTR(SQLERRM, 1, 200);
      RAISE  EXP_MAIN_REJECT_RECORD;
   
   END;  
  
   -- En changes for MVCSD-4099 Additional changes..
  
  --En select Pan detail
IF v_lmtprfl IS NULL OR v_profile_level IS NULL -- Added on 30102012 Dhiraj 
   THEN
/* START   Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
       BEGIN
         SELECT cpl_lmtprfl_id
           INTO v_lmtprfl
           FROM cms_prdcattype_lmtprfl
          WHERE cpl_inst_code = V_INST_CODE
            AND cpl_prod_code = V_PROD_CODE
            AND cpl_card_type = V_CARD_TYPE;

         v_profile_level := 2;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT cpl_lmtprfl_id
                 INTO v_lmtprfl
                 FROM cms_prod_lmtprfl
                WHERE cpl_inst_code = V_INST_CODE
                  AND cpl_prod_code = V_PROD_CODE;

               v_profile_level := 3;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                 NULL;
               WHEN OTHERS
               THEN
                  V_RESPCODE := '21';
                  P_ERRMSG :=
                        'Error while selecting Limit Profile At Product Level'
                     || SQLERRM;
                  RAISE EXP_MAIN_REJECT_RECORD;
            END;
         WHEN OTHERS
         THEN
            V_RESPCODE := '21';
            P_ERRMSG :=
                  'Error while selecting Limit Profile At Product Catagory Level'
               || SQLERRM;
             RAISE EXP_MAIN_REJECT_RECORD;
      END;

   /* End  Added by Dhiraj G on 12072012 for  - LIMITS BRD   */
  END IF  ; -- Added on 30102012 Dhiraj 
  /* Start VP-543*/
         BEGIN
         
         -- Changed to Product Category since B2B config moved to Category Level beg
       /*         SELECT cpp_b2bcard_stat
               INTO l_b2bcard_status
               FROM cms_product_param
               WHERE cpp_prod_code=V_PROD_CODE;
       */
         SELECT cpC_b2bcard_stat,nvl(cpc_user_identify_type,'0')
          INTO l_b2bcard_status,l_user_id_type
          FROM CMS_PROD_CATTYPE  
          WHERE CPC_PROD_CODE=V_PROD_CODE AND
          CPC_CARD_TYPE = V_CARD_TYPE 
          AND CPC_INST_CODE=P_INSTCODE; 
  
-- Changed to Product Category since B2B config moved to Category Level end

              EXCEPTION

              WHEN OTHERS THEN
                V_RESPCODE := '21';
                P_ERRMSG  := 'Error while checking b2b card status configured' ||SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_MAIN_REJECT_RECORD;

            END;
  
/* END VP-543*/
     IF  V_KYC_FLAG IN ('Y','P','O','I') THEN     -- added  if condition for mvcsd-4099 additional changes on 14/Sept/2013
  
      --Sn Activate the card / update the flag in appl_pan
       BEGIN
       /* START   Added by Dhiraj G on 12072012 for  - LIMITS BRD   */
          UPDATE CMS_APPL_PAN
             SET CAP_CARD_STAT = 1,CAP_ACTIVE_DATE=sysdate,CAP_FIRSTTIME_TOPUP = 'Y', --Modified by sivapragasam on May 14 2012 to maintain activation date
                 cap_prfl_code = v_lmtprfl,--Added by Dhiraj G on 12072012 for  - LIMITS BRD
                 cap_prfl_levl = v_profile_level, --Added by Dhiraj G on 12072012 for  - LIMITS BRD
                 cap_expry_date = NVL(cap_replace_exprydt, cap_expry_date),
                 cap_replace_exprydt =NULL
           WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;
           /* End  Added by Dhiraj G on 12072012 for  - LIMITS BRD   */
           IF sql%rowcount = 0 then
           V_RESPCODE := '21';
           P_ERRMSG   := 'Activating GPR card not updated for :' ||
                      V_HASH_PAN;
          RAISE EXP_MAIN_REJECT_RECORD;
           end if;
       EXCEPTION
         when EXP_MAIN_REJECT_RECORD then
         raise EXP_MAIN_REJECT_RECORD;
         WHEN OTHERS THEN
          V_RESPCODE := '21';
          P_ERRMSG   := 'Error while Activating GPR card' ||
                      SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
       END;
     --En update the flag in appl_pan

        --Sn select starter card detail
        
         --  Sn added for mvcsd-4099 additional changes on 14/Sept/2013
         
     ELSIF  V_KYC_FLAG IN ('F','E') or (V_KYC_FLAG='N' and l_b2bcard_status is not null ) THEN  -- modified for VP543
      BEGIN
      
          UPDATE CMS_APPL_PAN
             SET CAP_CARD_STAT = case when l_user_id_type in ('1','4') then 1 else 13 end,CAP_ACTIVE_DATE=sysdate,CAP_FIRSTTIME_TOPUP = 'Y', 
                 cap_prfl_code = v_lmtprfl,
                 cap_prfl_levl = v_profile_level 
           WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;
          
           IF sql%rowcount = 0 then
           V_RESPCODE := '21';
           P_ERRMSG   := 'Activating GPR card not updated for :' ||
                      V_HASH_PAN;
          RAISE EXP_MAIN_REJECT_RECORD;
           end if;
       EXCEPTION
         when EXP_MAIN_REJECT_RECORD then
         raise EXP_MAIN_REJECT_RECORD;
         WHEN OTHERS THEN
          V_RESPCODE := '21';
          P_ERRMSG   := 'Error while Activating GPR card' ||
                      SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
       END;
      -- Card Status logging  to Active UnRegistered
         BEGIN
           sp_log_cardstat_chnge (p_instcode,
                                  V_HASH_PAN,
                                  V_ENCR_PAN,
                                  P_AUTH_ID,
                                   '09',    
                                  P_RRN,              
                                  P_TRANDATE,
                                  P_TRANTIME,
                                  v_respcode,
                                  P_ERRMSG
                                 );

           IF v_respcode <> '00' AND P_ERRMSG <> 'OK'
           THEN
            RAISE exp_main_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_main_reject_record
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              v_respcode := '21';
              P_ERRMSG:=
                    'Error while logging system initiated card status change to Active UnRegistered'
                 || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
        END; 
                 
      END IF;
        -- en added for mvcsd-4099 additional changes on 14/Sept/2013
        
  BEGIN
    select CAP_PAN_CODE,clear_card
      INTO V_STARTER_CARD,v_oldcrd_clear
    from (SELECT CAP_PAN_CODE,fn_dmaps_main(cap_pan_code_encr) as clear_card
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INSTCODE AND CAP_ACCT_NO = V_ACCT_NUMBER
    AND CAP_STARTERCARD_FLAG='Y' AND CAP_CARD_STAT NOT IN ('9')
    order by cap_pangen_date desc) where rownum=1;

  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
    NULL;  --Added by Ramesh.A on 19/11/2012 for GPR card activation
     --P_ERRMSG := 'Invalid Account number ' || V_ACCT_NUMBER; --Commented by Ramesh.A on 19/11/2012 for GPR card activation
     --RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     P_ERRMSG := 'Error while selecting Starter Card number for Account No ' || V_ACCT_NUMBER;
     RAISE EXP_MAIN_REJECT_RECORD;

  END;

  --En select starter card detail

IF V_STARTER_CARD IS NOT NULL THEN --Added by Ramesh.A on 19/11/2012 for GPR card activation
    --Sn close starter card
       BEGIN

          UPDATE CMS_APPL_PAN
             SET CAP_CARD_STAT = 9
           WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_STARTER_CARD;
          
          p_closed_card :=v_oldcrd_clear;
       EXCEPTION
         WHEN OTHERS THEN
          V_RESPCODE := '21';
          P_ERRMSG   := 'Error while closing the status of starter card ' ||
                      SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
       END;
     --En close starter card
END IF; --Added by Ramesh.A on 19/11/2012 for GPR card issue

--START ADDED FOR mvcsd-4121 AND FWR-43 ON 11/03/14
BEGIN

        select cap_pan_code,CAP_PAN_CODE_ENCR,fn_dmaps_main(CAP_PAN_CODE_ENCR) INTO V_RENEWAL_CARD_HASH ,V_RENEWAL_CARD_ENCR,v_oldcrd_clear
        from cms_appl_pan ,cms_cardrenewal_hist
        where cap_inst_code=CCH_INST_CODE and cap_pan_code=CCH_PAN_CODE 
        and cap_card_stat <>9 and cap_pan_code<>V_HASH_PAN
        and cap_acct_no=V_ACCT_NUMBER
        and cap_inst_code=P_INSTCODE;
                       
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
       NULL;
       WHEN OTHERS THEN
         V_RESPCODE := '21';
         P_ERRMSG   := 'Error while GETTING THE RENEWAL CARD DETAILS ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;      

END;

IF V_RENEWAL_CARD_HASH IS NOT NULL  THEN
 BEGIN      
        
      UPDATE CMS_APPL_PAN
      SET CAP_CARD_STAT = 9
      WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_RENEWAL_CARD_HASH;
       
         IF SQL%ROWCOUNT = 0 THEN
             V_RESPCODE := '21';
              P_ERRMSG   := 'UPDATION OF RENEWAL CARD TO CLOSURE NOT HAPPENED'|| V_RENEWAL_CARD_HASH;
          RAISE EXP_MAIN_REJECT_RECORD;
         END IF;
        
        
        p_closed_card :=v_oldcrd_clear; 
        
            sp_log_cardstat_chnge (p_instcode,
                                   V_RENEWAL_CARD_HASH,
                                   V_RENEWAL_CARD_ENCR,
                                   P_AUTH_ID,
                                   '02',    
                                  P_RRN,              
                                  P_TRANDATE,
                                  P_TRANTIME,
                                  v_respcode,
                                  P_ERRMSG
                                 );

           IF v_respcode <> '00' AND P_ERRMSG <> 'OK'
           THEN
            RAISE exp_main_reject_record;
           END IF;        
           
       EXCEPTION    
       WHEN EXP_MAIN_REJECT_RECORD THEN
       RAISE;
       WHEN OTHERS THEN
         V_RESPCODE := '21';
         P_ERRMSG   := 'Error while CLOSING THE RENEWAL CARD ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;      

 END;
END IF;

--END

 EXCEPTION
   WHEN EXP_MAIN_REJECT_RECORD THEN
    ROLLBACK;
    P_RESP_CODE := V_RESPCODE;

  WHEN OTHERS THEN
   P_ERRMSG := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);
END;
/
SHOW ERROR