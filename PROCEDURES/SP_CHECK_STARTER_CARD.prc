create or replace
PROCEDURE        VMSCMS.SP_CHECK_STARTER_CARD (
   prm_inst_code          IN       NUMBER,
   prm_card_no            IN       VARCHAR2,
   prm_txn_code           IN       VARCHAR2,
   PRM_DELIVERY_CHANNEL   in       varchar2,
   prm_resp_code          OUT      VARCHAR2,--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
   prm_err_msg            OUT      VARCHAR2,
   prm_approve_flag       IN      VARCHAR2 DEFAULT 'Y'
)
/***************************************************************************************************
  * VERSION             :  1.0
  * Created Date        : 10/Apr/2012
  * Created By          : Rama Prabhu R
  * PURPOSE             : To check the given card is a valid starter card for manual registration
  * Modified By:        : Amit Sonar
  * Modified Reason     : Modified for Active Unregistered changes
  * Modified Date       : 25/SEP/2012
  * Modified By:        : Sagar M
  * Modified Reason     : To validate manual registration process based on cci_ssn_flag
  * Modified Date       : 19/FEB/2013
  * Build number        : RI0023.2_B0001
  * Reviewed date       : NA
  * Reviewed By:        : Dhiraj

  * Modified Date       : 04_Mar_2013
  * Modified By         : Pankaj S.
  * Purpose             : Mantis Id : 0010410
  * Reviewer            : Dhiraj
  * Release Number      : RI0023.2_B0009

  * Modified Date       : 04_Sept_2013
  * Modified By         : Santosh K
  * Purpose             : Mantis-0012284 - KYC Fail response code always logged as 21 in transactionlog table and resp id also incorrect
  * Modified Reason     : For logging proper response code against error messages
  * Release Number      : RI0024.4_B0009

  * Modified Date       : 23_Sept_2013
  * Modified By         : Santosh K
  * Purpose             : Mantis-0012443
  * Modified Reason     : Sale transaction check fail at CS Desktop
  * Release Number      : RI0024.4_B0018

  * Modified Date       : 12_Feb_2014
  * Modified By         : Dnyaneshwar J
  * Purpose             : FSS-695
  * Modified Reason     : Duplicate Check removed, To Allow Multiple Registration from Manual Registration in CSR
  * Release Number      : RI0027.1_B0001

  * Modified Date       : 17_Feb_2014
  * Modified By         : Dnyaneshwar J
  * Purpose             : Mantis-13693
  * Release Number      : RI0027.1_B0002

  * Modified Date       : 21_Feb_2014
  * Modified By         : Dnyaneshwar J
  * Purpose             : Mantis-13735

  * Modified Date       : 16_June_2014
  * Modified By         : Narsing I
  * Purpose             : MVCSD-5125
  * Build Number        : RI0027.3_B0001

  * Modified Date       : 29-SEP-2014
  * Modified By         : Abdul Hameed M.A
  * Modified for        : FWR 70
  * Reviewer            : Spankaj
  * Release Number      : RI0027.4_B0002
  
  * Modified by                  : MageshKumar S.
  * Modified Date                : 23-June-15
  * Modified For                 : MVCAN-77
  * Modified reason              : Canada account limit check
  * Reviewer                     : Spankaj
  * Build Number                 : VMSGPRHOSTCSD3.1_B0001
  
  * Modified by                  : Abdul Hameed M.A
  * Modified Date                : 04-Jan-16
  * Modified For                 : MVHOST-1263
  * Reviewer                     : Spankaj
  * Build Number                 : VMSGPRHOSTCSD3.3_B0002
*******************************************************************************************************/
IS
   v_starter_card_flag   cms_appl_pan.cap_startercard_flag%TYPE;
   v_card_stat           cms_appl_pan.cap_card_stat%TYPE;
   v_cap_pan_code        cms_appl_pan.cap_pan_code%TYPE;
   v_cardiss_stat        cms_cardissuance_status.ccs_card_status%TYPE;
   v_kyc_flag            cms_caf_info_entry.cci_kyc_flag%TYPE;
   v_saletxn_cnt         NUMBER (2)                                     := 0;
   v_exception           EXCEPTION;
   v_ccs_card_status     cms_cardissuance_status.ccs_card_status%TYPE;
   v_cap_expry_date      cms_appl_pan.cap_expry_date%TYPE;

   v_cci_appl_code       cms_caf_info_entry.cci_appl_code%type;
   v_success_cnt         number(2);
   V_Fail_Cnt            Number(2);

   v_cap_cust_code       Cms_Appl_Pan.Cap_Cust_Code%Type; --added by amit on 25-Sep-2012 for active unregistered
   v_ccm_kyc_flag        cms_cust_mast.ccm_kyc_flag%type; --added by amit on 25-Sep-2012 for active unregistered

   V_SSN_FLAG   CMS_CAF_INFO_ENTRY.CCI_SSN_FLAG%type;

   v_firsttime_topup  Cms_Appl_Pan.CAP_FIRSTTIME_TOPUP%Type;  --Added by Santosh K on 22 Sept 2013 For Mantis-0012284


BEGIN
   prm_err_msg := 'OK';
   prm_resp_code := '1';--Added by Santosh K on 04 Sept 2013 For Mantis-0012443


   SELECT cap_startercard_flag,
          cap_card_stat,
          cap_pan_code,
          CAP_EXPRY_DATE,
          CAP_CUST_CODE,
          nvl(CAP_FIRSTTIME_TOPUP,'N')              --Added by Santosh K on 22 Sept 2013 For Mantis-0012443
     INTO v_starter_card_flag,
          v_card_stat,
          v_cap_pan_code,
          v_cap_expry_date,
          V_CAP_CUST_CODE,
          v_firsttime_topup                         --Added by Santosh K on 22 Sept 2013 For Mantis-0012443
     FROM cms_appl_pan
    WHERE cap_inst_code = prm_inst_code
      AND cap_pan_code = gethash (prm_card_no);
   --Sn Commented by Pankaj S. for  Mantis Id : 0010410
   /*   --------------------------------------------------------------------------
      --SN:Added to validate manual registration process based on cci_ssn_flag
      --------------------------------------------------------------------------

    IF prm_delivery_channel ='03' and prm_txn_code = '03'
    then

       BEGIN

             select cci_ssn_flag
             into   v_ssn_flag
             from   cms_caf_info_entry
             where  cci_pan_code  = gethash (prm_card_no);

             if v_ssn_flag = 'E'
             then

                prm_err_msg   := 'The card is already in SSN / ID failed queue';
                RAISE v_exception;

             end if;


       EXCEPTION when v_exception
       then
           raise;

       WHEN NO_DATA_FOUND
       THEN
            prm_err_msg   := 'Card not found in caf_info_entry '||fn_mask(prm_card_no,'X','7','6');
            RAISE v_exception;

       WHEN OTHERS
       THEN
            prm_err_msg   := 'While fetching SSN flag '||substr(sqlerrm,1,100);
            RAISE v_exception;

       END;

    END IF;
      -------------------------------------------------------------------------
      --EN:Added to validate manual registration process based on cci_ssn_flag
      -------------------------------------------------------------------------*/
      --En Commented by Pankaj S. for  Mantis Id : 0010410



      BEGIN                               --added by amit on 25-Sep-2012 for active unregistered
              select ccm_kyc_flag
              into   v_ccm_kyc_flag
              from   cms_cust_mast
              where  ccm_inst_code = prm_inst_code
              and    ccm_cust_code = v_cap_cust_code;

      Exception when no_data_found
       then
            prm_resp_code := 49;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
            prm_err_msg   := 'KYC flag not found for custcode '||v_cap_cust_code;
            RAISE v_exception;
       when others
       then
            prm_resp_code := 21;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
            prm_err_msg   := 'Error while fetching KYC flag '||substr(sqlerrm,1,100);
            RAISE v_exception;

      END;

      If last_day(trunc(v_cap_expry_date)) < trunc(sysdate)  -- added by sagar on 24-May-2012 for expired card check
      then                                                   -- last day function added for expiry card check
          prm_resp_code := 13;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
          prm_err_msg := 'Expired starter card ';
          RAISE v_exception;

      End if;

   -- Check if the card is starter card
   IF v_starter_card_flag IS NULL OR v_starter_card_flag <> 'Y'
   then
      prm_resp_code := 120;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
      prm_err_msg := 'This is not a Starter Card ';
      RAISE v_exception;
   END IF;

   BEGIN
      SELECT ccs_card_status
        INTO v_ccs_card_status
        FROM cms_cardissuance_status
       WHERE ccs_inst_code = prm_inst_code
         AND ccs_pan_code = gethash (prm_card_no);
   EXCEPTION
      WHEN NO_DATA_FOUND
      then
         prm_resp_code := 49;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
         prm_err_msg := 'Application status not found';
         RAISE v_exception;
      WHEN OTHERS
      then
         prm_resp_code := 21;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
         prm_err_msg :=
             'While fetching application status ' || SUBSTR (SQLERRM, 1, 100);
         RAISE v_exception;
   END;


   IF prm_txn_code IN ('23','24') AND v_ccs_card_status not in('31','15')
   then
      prm_resp_code := 146;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
      prm_err_msg := 'Application Status Not In Shipped/Kyc Failed Status';
      RAISE v_exception;

   ELSE

       IF prm_txn_code NOT IN ('23','24','04') AND v_ccs_card_status not in('31','15')-- Condition modified to include trancode for MVCAN-77 --Modified by Dnyaneshwar J on 17 Feb 2014 Mantis-13693
       then
          prm_resp_code := 146;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
          prm_err_msg := 'Starter Card Not In Shipped State';
          RAISE v_exception;
       END IF;

   END IF;

--SN:Commented by Santosh K on 22 Sept 2013 For Mantis-0012443
/*
   SELECT COUNT (1)
     INTO v_saletxn_cnt
     FROM transactionlog
    WHERE instcode = prm_inst_code
      AND txn_code = '26'
      AND delivery_channel = '08'
      AND response_code = '00' --added by sagar on 18-Apr-2012 to fetch successful count
      AND customer_card_no = v_cap_pan_code;

   IF v_saletxn_cnt = 0
   then
      prm_resp_code := 126;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
      prm_err_msg := 'Sale Transaction Not Initiated For Starter Card';
      RAISE v_exception;
   END IF;

*/

--EN:Commented by Santosh K on 22 Sept 2013 For Mantis-0012443

--SN:Added by Santosh K on 22 Sept 2013 For Mantis-0012443

--SN:Modified by Narsing I on 16th June 2014 For MVCSD-5125
 -- IF v_firsttime_topup <> 'Y' And (prm_txn_code <> '03' And PRM_DELIVERY_CHANNEL <> '03')  then
    IF v_firsttime_topup <> 'Y' And (prm_txn_code not in( '03','90') And PRM_DELIVERY_CHANNEL <> '03')  then  --Modified for FWR 70
      prm_resp_code := 126;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
      prm_err_msg := 'Sale Transaction Not Initiated For Starter Card';
      RAISE V_EXCEPTION;
   end if;

--EN:Added by Santosh K on 22 Sept 2013 For Mantis-0012443

   BEGIN
      /* -- Commented  on 11 May 2012 Dhiraj Gaikwad as per discussion with tejas
         If prm_txn_code in( '03','24')  and v_card_stat <> '0'
         then

         prm_err_msg := 'Starter Card Not In Inactive State';
         RAISE v_exception;
         */
     /*        --commented on 12-JUN-2012 by sagar as per dicussion with tejas
      IF prm_txn_code = '18' AND v_card_stat = '0'
      THEN
         prm_err_msg := 'Starter Card Is In Inactive State';
         RAISE v_exception;
     */

    /*--sn-Commented by Dnyaneshwar J on 21 Feb 2014 Mantis-13735
      IF prm_txn_code IN ('03', '24') AND v_card_stat not in('0','13') --'13' added by amit for active unregistered
      then
       prm_resp_code := 10;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
       prm_err_msg := 'Starter Card Not In Inactive/Active unregistered State';
         RAISE v_exception;
      end if;
    */--en-Commented by Dnyaneshwar J on 21 Feb 2014 Mantis-13735

    --sn:Added by Dnyaneshwar J on 21 Feb 2014 For Mantis-13735
   -- IF prm_txn_code IN ('03','90') AND v_card_stat not in('0','13')    --Modified for FWR 70
   IF prm_txn_code IN ('03','90') AND v_card_stat ='5' AND prm_approve_flag='N'
      then
      prm_resp_code := 10;
      prm_err_msg := 'Starter Card Not In Inactive/Active unregistered State';
      RAISE v_exception;
    end if;

    IF prm_txn_code IN ('24') AND v_card_stat not in('0','13','14')
      then
      PRM_RESP_CODE := 10;
      prm_err_msg := 'Starter Card Not In Inactive/Active unregistered/Spend Down State';
      RAISE V_EXCEPTION;
    end if;
    --en:Added by Dnyaneshwar J on 21 Feb 2014 For Mantis-13735

      if prm_txn_code not in ('03','24','90','04') and v_card_stat <> '0'  --Modified for FWR 70
      then
         prm_resp_code := 10;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
         prm_err_msg := 'Starter Card Not In Inactive State';
         RAISE v_exception;
      END IF;

      BEGIN

         SELECT count(1)
           INTO v_success_cnt
           FROM cms_caf_info_entry
          --WHERE cci_card_number = v_cap_pan_code  --- Commented by Dhina for change the column Name on 060812
          WHERE CCI_PAN_CODE = v_cap_pan_code       --- Added by Dhina for change the column Name on 060812
          AND cci_appl_code IS NOT NULL
          and cci_kyc_flag in('Y','P','O');  --commented on 25-May-2012 -- In condition added by sagar on 16Aug2012 for KYC changes



         -- added by tejas on 18-Apr-2012;
         IF v_success_cnt > 0 AND prm_txn_code IN ('03', '24', '26','90','04') -- Condition modified to include trancode for MVCAN-77 --Modified for FWR 70
         then
            prm_resp_code := 143;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
            prm_err_msg := 'Registration Already Done For This Starter Card';
            RAISE v_exception;

         END IF;
      /*--sn Commented by Dnyaneshwar J on 12 Feb 2014 for FSS-695
        SELECT count(1)
           INTO v_fail_cnt
           FROM cms_caf_info_entry
         -- WHERE cci_card_number = v_cap_pan_code --- Commented by Dhina for change the column Name on 060812
          WHERE CCI_PAN_CODE = v_cap_pan_code      --- Added by Dhina for change the column Name on 060812
          and cci_kyc_flag in ('E','F');


         IF v_fail_cnt > 0 AND prm_txn_code IN ('03', '26')
         then
            prm_resp_code := 143;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
            prm_err_msg := 'Starter Card Already In KYC Fail Queue';
            RAISE v_exception;

         end if;
      */--en Commented by Dnyaneshwar J on 12 Feb 2014 for FSS-695
      EXCEPTION WHEN v_exception
      then
            raise;

         WHEN OTHERS
         then
            prm_resp_code := 21;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
            prm_err_msg :='While fetching KYC flag' || SUBSTR (SQLERRM, 1, 100);
            RAISE v_exception;
      END;
   EXCEPTION
      WHEN NO_DATA_FOUND
      then
         PRM_RESP_CODE := 49;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
         prm_err_msg := 'Invalid Starter Card';
      WHEN v_exception
      THEN
         RAISE v_exception;
      WHEN OTHERS
      then
         PRM_RESP_CODE := 21;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
         prm_err_msg :='Error while validating starter card' || SUBSTR (SQLERRM, 1, 200);
         RAISE v_exception;
   END;
EXCEPTION
   WHEN NO_DATA_FOUND
   then
      PRM_RESP_CODE := 49;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
      prm_err_msg := 'Invalid Starter Card';
   WHEN v_exception
   THEN
      NULL;
   WHEN OTHERS
   then
      PRM_RESP_CODE := 21;--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
      prm_err_msg :='Error while validating starter card' || SUBSTR (SQLERRM, 1, 200);
END;
/
SHOW ERROR;