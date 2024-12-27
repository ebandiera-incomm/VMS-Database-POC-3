create or replace
PROCEDURE VMSCMS.SP_BATCHPROFILE_UPDATE (
   p_instcode           IN       NUMBER,
   p_rrn                IN       VARCHAR2,
   p_stan               IN       VARCHAR2,
   p_trandate           IN       VARCHAR2,
   p_trantime           IN       VARCHAR2,
   p_proxyno            IN       VARCHAR2,
   p_currcode           IN       VARCHAR2,
   p_msg_type           IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_mbr_numb           IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_first_name         IN       VARCHAR2,
   p_dob                IN       DATE,
   p_ssn                IN       VARCHAR2,
   p_last_name          IN       VARCHAR2,
   p_addr_lineone       IN       VARCHAR2,
   p_addr_linetwo       IN       VARCHAR2,
   p_city               IN       VARCHAR2,
   p_state              IN       NUMBER,
   p_zip                IN       VARCHAR2,
   p_cntry_code         IN       NUMBER,
   p_altid              IN       VARCHAR2,
   p_idtype             IN       VARCHAR2,
   p_idissuer           IN       VARCHAR2,
   p_idnumber           IN       VARCHAR2,
   p_idissudate         IN       DATE,
   p_idexpirdate        IN       DATE,
   p_mailing_addr1      IN       VARCHAR2,
   p_mailing_addr2      IN       VARCHAR2,
   p_mailing_city       IN       VARCHAR2,
   p_mailing_state      IN       VARCHAR2,  --Added by sivakumar.M
   p_mailing_zip        IN       VARCHAR2,
   p_mailing_country    IN       VARCHAR2,   --Added by sivakumar.M
   p_alternate_phone    IN       VARCHAR2,
   p_mobile_no          IN       VARCHAR2,
   p_mother_name        IN       VARCHAR2,
   p_email              IN       VARCHAR2,
   p_cpi_check          IN       VARCHAR2,
   P_CARD_NO            IN       VARCHAR2, -- added for defect Id:12838
   P_CARD_STAT          IN       VARCHAR2, -- added for defect Id:12838
   P_APPL_CODE          IN       VARCHAR2, -- added for defect Id:12838
   P_CUST_CODE          IN       NUMBER,   -- added for defect Id:12838
   P_PROD_CODE          IN       VARCHAR2, -- added for defect Id:12838
   P_PROD_CATG          IN       VARCHAR2, -- added for defect Id:12838
   P_ACCT_NO            IN       VARCHAR2,  -- added for defect Id:12838
   p_resp_code          OUT      VARCHAR2,
   p_errmsg             OUT      VARCHAR2
)
AS
/*************************************************
     * Created  By      : Nanda Kumar R.
     * Created  Date    : 04-05-2012
     * Modified By      : Nanda Kumar R
     * Modified Reason  : Modified for Phone Number Updation.
     * Modified Date    : 12-06-2012
     * Reviewer         : B.Besky Anand
     * Reviewed Date    : 08-06-2012
     * Build Number     : CMS3.5.1_RI0009 B0014

     * Modified By      : Siva Kumar M
     * Modified Reason  : Modified for Defect Id:12838
     * Modified Date    : 29/Oct/2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 29/Oct/2013
     * Build Number     : RI0024.6_B0004

     * Modified By      : Ramesh A
     * Modified Reason  : FSS-1961(Melissa)
     * Modified Date    : 12/DEC/2014
     * Reviewer         : Spankaj
     * Build Number     : RI0027.5_B0002
     * Modified By      : Ramesh A
     * Modified Reason  : Perf changes
     * Modified Date    : 06/MAR/2015
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 06/MAR/2015
     * Build Number     : 2.5

     * Modified By      : Abdul Hameed M.A
     * Modified Reason  : Mantis ID 16072
     * Modified Date    : 30-Mar-2015
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 30-Mar-2015
     * Build Number     : VMSGPRHOSTCSD_3.0_B0003

     * Modified by      :Spankaj
     * Modified Date    : 07-Sep-15
     * Modified For     : FSS-2321
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOSTCSD3.2

       * Modified by       :Siva kumar
       * Modified Date    : 18-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006

       * Modified by       :Mageshkumar S
       * Modified Date    : 31-May-16
       * Modified For     : Mantis id:16412
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.1_B0002

       * Modified by       :T.Narayanaswamy
       * Modified Date    : 24-March-17
       * Modified For     : JIRA-FSS-4647 (AVQ Status issue)
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_17.03_B0003
       
       * Modified by       :Vini
       * Modified Date    : 10-Jan-2018
       * Modified For     : VMS-162
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_17.12.1
	   
	   * Modified by      : Vini
       * Modified Date    : 18-Jan-2018
       * Modified For     : VMS-162
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_18.01 
	   
	   * Modified by      :  Vini Pushkaran
       * Modified Date    :  02-Feb-2018
       * Modified For     :  VMS-162
       * Reviewer         :  Saravanankumar
       * Build Number     :  VMSGPRHOSTCSD_18.01
	   
	* Modified By      : Vini Pushkaran
    * Modified Date    : 14-MAY-2018
    * Purpose          : VMS 207 - Added new field to VMS_AUDITTXN_DTLS.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST_R01
    
    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18
	
	* Modified By      : Saravana Kumar.A
    * Modified Date    : 24-DEC-2021
    * Purpose          : VMS-5378 : Need to update ccm_system_generate_profile flag in Retail / Card stock flow.
    * Reviewer         : Venkat. S
    * Release Number   : VMSGPRHOST_R56 Build 2.

	   
 *************************************************/
  v_errmsg                     transactionlog.error_msg%type;
  v_respcode                   transactionlog.response_id%type;
  v_hash_pan                   cms_appl_pan.cap_pan_code%TYPE;
  v_encr_pan                   cms_appl_pan.cap_pan_code_encr%TYPE;
  v_mailaddr_cnt               PLS_INTEGER;
  v_prod_cattype               cms_appl_pan.cap_card_type%TYPE;
  v_prod_code                  cms_appl_pan.cap_prod_code%TYPE;
  v_curr_code                  gen_cntry_mast.gcm_curr_code%TYPE;
  V_TIME_STAMP                 TIMESTAMP;
  v_trans_desc                 cms_transaction_mast.CTM_TRAN_DESC%TYPE;
  v_acct_bal                   cms_acct_mast.cam_acct_bal%TYPE;
  v_ledger_bal                 cms_acct_mast.cam_ledger_bal%TYPE;
  v_acct_type                  CMS_ACCT_MAST.CAM_TYPE_CODE%TYPE;
  V_ENCRYPT_ENABLE             CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
  V_ZIPCODE                    cms_addr_mast.cam_pin_code%type; 
  v_encr_addr_lineone 	       cms_addr_mast.CAM_ADD_ONE%type;
  v_encr_addr_linetwo 	       cms_addr_mast.CAM_ADD_TWO%type;
  v_encr_city         	       cms_addr_mast.CAM_CITY_NAME%type;
  v_encr_email        	       cms_addr_mast.CAM_EMAIL%type;
  v_encr_phone_no     	       cms_addr_mast.CAM_PHONE_ONE%type;
  v_encr_mob_one      	       cms_addr_mast.CAM_MOBL_ONE%type;        
  v_encr_first_name   	       cms_cust_mast.CCM_FIRST_NAME%type; 
  v_encr_last_name    	       cms_cust_mast.CCM_LAST_NAME%type;
  v_encr_mother_name           cms_cust_mast.CCM_MOTHER_NAME%type;
  v_phys_switch_state_code     cms_addr_mast.cam_state_switch%TYPE ;      -- Added for FSS-1961(Melissa)
  v_mailing_switch_state_code  cms_addr_mast.cam_state_switch%TYPE ;
  V_AVQ_STATUS                 VARCHAR2(1);
  V_CUST_ID                    CMS_CUST_MAST.CCM_CUST_ID%TYPE;
  V_FULL_NAME                  CMS_CUST_MAST.CCM_FIRST_NAME%TYPE;
  V_MAILADDR_LINEONE 		   cms_addr_mast.CAM_ADD_ONE%type;
  V_MAILADDR_LINETWO 		   cms_addr_mast.CAM_ADD_TWO%type;
  V_MAILADDR_CITY    	       cms_addr_mast.CAM_CITY_NAME%type;
  V_MAILADDR_ZIP  			   cms_addr_mast.cam_pin_code%type;
  v_gprhash_pan                CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  v_gprencr_pan                CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;       --END Added for FSS-1961(Melissa)
  v_encr_mothers_maiden_name   cms_caf_info_entry.cci_mothers_maiden_name%type;
  v_encr_cci_seg12_name_line1  cms_caf_info_entry.cci_seg12_name_line1%type;
  v_encr_cci_seg12_name_line2  cms_caf_info_entry.cci_seg12_name_line2%type;
  v_encr_cci_seg12_addr_line1  cms_caf_info_entry.cci_seg12_addr_line1%type;
  v_encr_cci_seg12_addr_line2  cms_caf_info_entry.cci_seg12_addr_line2%type;
  v_encr_cci_seg12_city        cms_caf_info_entry.cci_seg12_city%type;
  v_encr_cci_seg12_postal_code cms_caf_info_entry.cci_seg12_postal_code%type;
  v_encr_cci_seg12_mobileno    cms_caf_info_entry.cci_seg12_mobileno%type;
  v_encr_cci_seg12_emailid     cms_caf_info_entry.cci_seg12_emailid%type;
  v_encr_cci_seg13_addr_line1  cms_caf_info_entry.cci_seg13_addr_line1%type;
  v_encr_cci_seg13_addr_line2  cms_caf_info_entry.cci_seg13_addr_line2%type;
  v_encr_cci_seg13_city        cms_caf_info_entry.cci_seg13_city%type;
  v_encr_cci_seg13_postal_code cms_caf_info_entry.cci_seg13_postal_code%type;
  v_encr_full_name             cms_avq_status.cas_cust_name%type;  
  exp_reject_record            EXCEPTION;
  exp_main_reject_record       EXCEPTION;
  
BEGIN
   p_errmsg := 'OK';
   p_resp_code := '00';
    V_TIME_STAMP :=SYSTIMESTAMP; -- added for defect Id:12838

  /*  BEGIN   commented for defect id:12838. query is moved to java
      SELECT distinct cap_cust_code,cap_appl_code--, cap_pan_code, cap_prod_code, cap_prod_catg,
            -- cap_card_type,cap_pan_code_encr
        INTO v_cust_code,v_appl_code--, v_hash_pan, v_prod_code, v_prodcatg,
            --v_prod_cattype, v_appl_code,v_encr_pan
        FROM cms_appl_pan
       WHERE cap_inst_code = p_instcode AND cap_proxy_number = p_proxyno and CAP_CARD_STAT <> '9';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'PAN details not available in CMS_APPL_PAN';
         v_respcode := '21';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while fetching data from pan master '
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_reject_record;
   END;
*/

---- added for defect Id:12838
     BEGIN
        v_hash_pan := GETHASH(P_CARD_NO);
      EXCEPTION
        WHEN OTHERS THEN
         v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
         RAISE exp_reject_record;
      END;

  --EN CREATE HASH PAN

-- added for defect Id:12838
      --SN create encr pan
      BEGIN
        v_encr_pan := FN_EMAPS_MAIN(P_CARD_NO);
      EXCEPTION
        WHEN OTHERS THEN
         v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
         RAISE exp_reject_record;
      END;
      -- added for defect Id:12838
     
      BEGIN   
      SELECT cap_prod_code, cap_card_type
        INTO v_prod_code, v_prod_cattype
        FROM cms_appl_pan
       WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
     EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'PAN details not available in CMS_APPL_PAN';
         v_respcode := '21';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while fetching data from pan master '
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_reject_record;
      END;
     
      --Sn check if Encrypt Enabled
      BEGIN
       SELECT  CPC_ENCRYPT_ENABLE
         INTO  V_ENCRYPT_ENABLE
         FROM  CMS_PROD_CATTYPE
        WHERE CPC_INST_CODE = P_INSTCODE 
          AND CPC_PROD_CODE = V_PROD_CODE
          AND CPC_CARD_TYPE = V_PROD_CATTYPE;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_respcode := '16';
            v_errmsg   := 'Invalid Prod Code Card Type ' || V_PROD_CODE || ' ' || V_PROD_CATTYPE;
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
            v_respcode := '12';
            v_errmsg   := 'Problem while selecting product category details' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
      END;
    --En check if Encrypt Enabled     
     
       BEGIN

            select CTM_TRAN_DESC
            into v_trans_desc
            from cms_transaction_mast
            where ctm_inst_code=p_instcode
            and ctm_delivery_channel=p_delivery_channel
            and ctm_tran_code=p_txn_code;

        EXCEPTION
             WHEN OTHERS  THEN
             v_errmsg :='Error while selecting trans description'|| SUBSTR (SQLERRM, 1, 200);
             v_respcode := '21';
             RAISE exp_reject_record;

       END;
      -- added for defect Id:12838
      BEGIN

        select cam_acct_bal,cam_ledger_bal,cam_type_code
        into v_acct_bal,v_ledger_bal,v_acct_type
        from cms_acct_mast
        where cam_inst_code=p_instcode
        and cam_acct_no=P_ACCT_NO;

      EXCEPTION
         WHEN OTHERS  THEN
         v_errmsg :='Error while selecting Acct Balance'|| SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_reject_record;

      END;

  -- Added for FSS-1961(Melissa)
    IF p_cntry_code IS NOT NULL THEN
      BEGIN
                SELECT GCM_CURR_CODE
                INTO v_curr_code
                FROM GEN_CNTRY_MAST
                WHERE GCM_CNTRY_CODE = p_cntry_code
                AND GCM_INST_CODE = P_INSTCODE;
      EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
             v_respcode := '168';
             v_errmsg := 'Invalid Data for Country Code' || p_cntry_code;
             RAISE exp_reject_record;
       WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting currency code ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
      END;

        IF p_state IS NOT NULL THEN --Added for MVHOST-382 on 13/06/2013

           BEGIN
               SELECT GSM_SWITCH_STATE_CODE
               INTO v_phys_switch_state_code
               FROM  GEN_STATE_MAST
               WHERE  GSM_STATE_CODE = p_state
               AND GSM_CNTRY_CODE = p_cntry_code
               AND GSM_INST_CODE = p_instcode;
            EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_respcode := '167';
                 v_errmsg := 'Invalid Data for Physical Address State' || p_state;
                 RAISE exp_reject_record;
            WHEN OTHERS THEN
             v_respcode := '21';
             V_ERRMSG := 'Error while selecting switch state code ' || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
          END;
      END IF;
   END IF;

     IF p_mailing_country IS NOT NULL THEN  --Added for melisa
        BEGIN

                SELECT GCM_CURR_CODE
                INTO v_curr_code
                FROM GEN_CNTRY_MAST
                WHERE GCM_CNTRY_CODE = p_mailing_country
                AND GCM_INST_CODE = p_instcode;

             EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
             v_respcode := '6';
             v_errmsg := 'Invalid Data for Mailing Address Country Code' || p_mailing_country;
             RAISE exp_reject_record;
              WHEN OTHERS THEN
              v_respcode := '21';
              V_ERRMSG := 'Error while selecting mailing country code ' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
             END;

         IF  p_mailing_state IS NOT NULL THEN

            BEGIN

            SELECT GSM_SWITCH_STATE_CODE
            INTO v_mailing_switch_state_code
            FROM  GEN_STATE_MAST
            WHERE  GSM_STATE_CODE = p_mailing_state
            AND GSM_CNTRY_CODE = p_mailing_country
            AND GSM_INST_CODE = p_instcode;

            EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
             v_respcode := '169';
             v_errmsg := 'Invalid Data for Mailing Address State' || p_mailing_state;
             RAISE exp_reject_record;
             WHEN OTHERS THEN
             v_respcode := '21';
             V_ERRMSG := 'Error while selecting mailing switch state code ' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
            END;
        END IF;
      END IF;
      --END Added for FSS-1961(Melissa)

    --Sn Added for FSS-2321
    BEGIN
       INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
            VALUES (p_rrn, p_delivery_channel, p_txn_code, p_cust_code,1);
    EXCEPTION
       WHEN OTHERS THEN
          v_respcode := '21';
          v_errmsg := 'Error while inserting audit dtls ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;
    --En Added for FSS-2321

   -- Customer information update
   BEGIN
      BEGIN
         if V_ENCRYPT_ENABLE = 'Y' then
				 v_zipcode := fn_emaps_main(p_mailing_zip);
				 v_encr_addr_lineone := fn_emaps_main(p_addr_lineone);
				 v_encr_addr_linetwo := fn_emaps_main(p_addr_linetwo);
				 v_encr_city := fn_emaps_main(p_city);
				 v_encr_phone_no := fn_emaps_main(p_alternate_phone);
				 v_encr_mob_one := fn_emaps_main(p_mobile_no);
				 v_encr_email := fn_emaps_main(p_email);
			  else
				 v_zipcode := p_mailing_zip;
				 v_encr_addr_lineone := p_addr_lineone;
				 v_encr_addr_linetwo := p_addr_linetwo;
				 v_encr_city := p_city;
				 v_encr_phone_no := p_alternate_phone;
				 v_encr_mob_one := p_mobile_no;
				 v_encr_email := p_email;
			  end if;
		 
		 UPDATE cms_addr_mast
            SET cam_add_one = v_encr_addr_lineone,
                cam_add_two = v_encr_addr_linetwo,
                cam_city_name = v_encr_city,
                cam_pin_code = V_ZIPCODE,
                cam_state_code = p_state,
                cam_cntry_code = p_cntry_code,
                cam_phone_one = DECODE (v_encr_phone_no,   --Added by sivakumar.M
                                        NULL,cam_phone_one,
                                        v_encr_phone_no),
                cam_email = DECODE (v_encr_email, NULL, cam_email, v_encr_email),
                cam_mobl_one =
                         DECODE (v_encr_mob_one,
                                 NULL, cam_mobl_one,
                                 v_encr_mob_one
                                ),
              cam_state_switch=NVL(v_phys_switch_state_code,cam_state_switch), -- Added for FSS-1961(Melissa)
              CAM_ADD_ONE_ENCR = fn_emaps_main(p_addr_lineone),
              CAM_ADD_TWO_ENCR = fn_emaps_main(p_addr_linetwo),
              CAM_CITY_NAME_ENCR = fn_emaps_main(p_city),
              CAM_PIN_CODE_ENCR = fn_emaps_main(p_mailing_zip),
              CAM_EMAIL_ENCR = fn_emaps_main(p_email)
          WHERE cam_cust_code = P_CUST_CODE   -- Modified for defect Id:12838
            AND cam_inst_code = p_instcode
            AND cam_addr_flag = 'P';

             IF sql%rowcount = 0 then
                    v_respcode := '21';
                    v_errmsg :='Update in Address master failed 1-- '|| P_CUST_CODE;  -- Modified for defect Id:12838
                   RAISE exp_reject_record;
              end if;

      EXCEPTION
         when exp_reject_record then
                raise;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                     'ERROR IN ADDR MAST UPDATE:- ' || P_CUST_CODE|| '--'||SUBSTR (SQLERRM, 1, 200);  -- Modified for defect Id:12838
            RAISE exp_reject_record;
      END;

      BEGIN
         if V_ENCRYPT_ENABLE = 'Y' then
				 v_encr_first_name := fn_emaps_main(p_first_name);
				 v_encr_last_name := fn_emaps_main(p_last_name);
                                 v_encr_mother_name := fn_emaps_main(p_mother_name);
		 else
				 v_encr_first_name := p_first_name;
				 v_encr_last_name := p_last_name;
                                 v_encr_mother_name := p_mother_name;
			  end if;
		 
		 UPDATE cms_cust_mast
            SET ccm_birth_date = p_dob,
                ccm_first_name = v_encr_first_name,
                ccm_last_name = v_encr_last_name,
                ccm_mother_name =
                   DECODE (v_encr_mother_name,
                           NULL, ccm_mother_name,
                           v_encr_mother_name
                          ),
                CCM_FIRST_NAME_ENCR = fn_emaps_main(p_first_name), 
                CCM_LAST_NAME_ENCR  = fn_emaps_main(p_last_name),
				CCM_SYSTEM_GENERATED_PROFILE = 'N'
          WHERE ccm_cust_code = P_CUST_CODE AND ccm_inst_code = p_instcode;  -- Modified for defect Id:12838

           IF sql%rowcount = 0 then
            v_respcode := '21';
            v_errmsg := 'Update in Customer master failed -- '|| P_CUST_CODE;  -- Modified for defect Id:12838
            RAISE exp_reject_record;
          end if;

      EXCEPTION
         when exp_reject_record then
                raise;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                     'ERROR IN CUST MAST UPDATE:- ' ||P_CUST_CODE|| '--'||SUBSTR (SQLERRM, 1, 200);  -- Modified for defect Id:12838
            RAISE exp_reject_record;
      END;

      SELECT COUNT (*)
        INTO v_mailaddr_cnt
        FROM cms_addr_mast
       WHERE cam_inst_code = p_instcode
         AND cam_cust_code = P_CUST_CODE  -- Modified for defect Id:12838
         AND cam_addr_flag = 'O';

      IF p_mailing_addr1 IS NOT NULL
      THEN
	     if V_ENCRYPT_ENABLE = 'Y' then
				 v_zipcode := fn_emaps_main(p_mailing_zip);
				 v_encr_addr_lineone := fn_emaps_main(p_mailing_addr1);
				 v_encr_addr_linetwo := fn_emaps_main(p_mailing_addr2);
				 v_encr_city := fn_emaps_main(p_mailing_city);
				 v_encr_phone_no := fn_emaps_main(p_alternate_phone);
				 v_encr_mob_one := fn_emaps_main(p_mobile_no);
		 else
				 v_zipcode := p_mailing_zip;
				 v_encr_addr_lineone := p_mailing_addr1;
				 v_encr_addr_linetwo := p_mailing_addr2;
				 v_encr_city := p_mailing_city;
				 v_encr_phone_no := p_alternate_phone;
				 v_encr_mob_one := p_mobile_no;
		 end if;
         IF v_mailaddr_cnt > 0
         THEN
           BEGIN
              UPDATE cms_addr_mast
                 SET cam_add_one = NVL(v_encr_addr_lineone,' '),
                     cam_add_two = (v_encr_addr_linetwo),
                     cam_city_name = nvl(v_encr_city,' '), 
                     cam_pin_code = V_ZIPCODE, 
                      cam_state_code = p_mailing_state,
                      cam_cntry_code =nvl(p_mailing_country,' '),
                      cam_phone_one  = v_encr_phone_no,
                      cam_mobl_one   = v_encr_mob_one,
                      cam_state_switch = NVL(v_mailing_switch_state_code,cam_state_switch), -- Added for FSS-1961(Melissa)
                      CAM_ADD_ONE_ENCR = NVL(fn_emaps_main(p_mailing_addr1),fn_emaps_main(' ')) ,
                      CAM_ADD_TWO_ENCR = fn_emaps_main(p_mailing_addr2),
                      CAM_CITY_NAME_ENCR = nvl(fn_emaps_main(p_mailing_city),fn_emaps_main(' ')),
                      CAM_PIN_CODE_ENCR = fn_emaps_main(p_mailing_zip) 
                WHERE cam_inst_code = p_instcode
                 AND cam_cust_code = P_CUST_CODE  -- Modified for defect Id:12838
                 AND cam_addr_flag = 'O';

                   IF sql%rowcount = 0 then
                    v_respcode := '21';
                    v_errmsg :='Update in Address master failed -- '|| P_CUST_CODE;  -- Modified for defect Id:12838
                   RAISE exp_reject_record;
                  end if;

           EXCEPTION
               when exp_reject_record then
                raise;
               WHEN OTHERS
              THEN
                  v_errmsg :=
                        'Error while updating mailing addr for custcode -- '
                    || P_CUST_CODE
                   || SUBSTR (SQLERRM, 1, 200);   -- Modified for defect Id:12838
                 v_respcode := '21';
                 RAISE exp_reject_record;
            END;
         ELSE
            BEGIN
			   INSERT INTO cms_addr_mast
                           (cam_inst_code, cam_cust_code, cam_addr_code,
                            cam_add_one, cam_add_two, cam_pin_code,
                            cam_phone_one, cam_mobl_one,
                            cam_cntry_code, cam_city_name, cam_addr_flag,
                            cam_state_code, cam_comm_type, cam_ins_user,
                            cam_ins_date, cam_lupd_user, cam_lupd_date,cam_state_switch,
                            CAM_ADD_ONE_ENCR,CAM_ADD_TWO_ENCR,CAM_CITY_NAME_ENCR,CAM_PIN_CODE_ENCR
                           )
                    VALUES (p_instcode, P_CUST_CODE, seq_addr_code.NEXTVAL,  -- Modified for defect Id:12838
                            v_encr_addr_lineone, v_encr_addr_linetwo, V_ZIPCODE,
                            v_encr_phone_no, v_encr_mob_one,
                            p_mailing_country, v_encr_city, 'O',
                            p_mailing_state, 'R', 1,
                            SYSDATE, 1, SYSDATE,v_mailing_switch_state_code,  -- Added for FSS-1961(Melissa)
                            fn_emaps_main(p_mailing_addr1),fn_emaps_main(p_mailing_addr2),
                            fn_emaps_main(p_mailing_city),fn_emaps_main(p_mailing_zip)
                            );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while inserting mailing addr for custcode -- '
                     || P_CUST_CODE
                     || SUBSTR (SQLERRM, 1, 200);  -- Modified for defect Id:12838
                  v_respcode := '21';
                  RAISE exp_reject_record;
            END;
         END IF;
         else -- Added for FSS-1961(Melissa)
           IF v_mailaddr_cnt = 0 THEN
            BEGIN
               if V_ENCRYPT_ENABLE = 'Y' then
				 v_zipcode := fn_emaps_main(p_zip);
				 v_encr_addr_lineone := fn_emaps_main(p_addr_lineone);
				 v_encr_addr_linetwo := fn_emaps_main(p_addr_linetwo);
				 v_encr_city := fn_emaps_main(p_city);
				 v_encr_phone_no := fn_emaps_main(p_alternate_phone);
				 v_encr_mob_one := fn_emaps_main(p_mobile_no);
			   else
				 v_zipcode := p_zip;
				 v_encr_addr_lineone := p_addr_lineone;
				 v_encr_addr_linetwo := p_addr_linetwo;
				 v_encr_city := p_city;
				 v_encr_phone_no := p_alternate_phone;
				 v_encr_mob_one := p_mobile_no;
			   end if;
			   INSERT INTO cms_addr_mast
                           (cam_inst_code, cam_cust_code, cam_addr_code,
                            cam_add_one, cam_add_two, cam_pin_code,
                            cam_phone_one, cam_mobl_one,
                            cam_cntry_code, cam_city_name, cam_addr_flag,
                            cam_state_code, cam_comm_type, cam_ins_user,
                            cam_ins_date, cam_lupd_user, cam_lupd_date,cam_state_switch,
                            CAM_ADD_ONE_ENCR,CAM_ADD_TWO_ENCR,CAM_CITY_NAME_ENCR,CAM_PIN_CODE_ENCR
                           )
                    VALUES (p_instcode, P_CUST_CODE, seq_addr_code.NEXTVAL,
                            v_encr_addr_lineone, v_encr_addr_linetwo, v_zipcode,
                            v_encr_phone_no, v_encr_mob_one,
                            p_cntry_code, v_encr_city, 'O',
                            p_state, 'O', 1,
                            SYSDATE, 1, SYSDATE,v_mailing_switch_state_code,
                            fn_emaps_main(p_addr_lineone),fn_emaps_main(p_addr_linetwo),
                            fn_emaps_main(p_city),fn_emaps_main(p_zip)
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while inserting mailing addr for custcode -- '
                     || P_CUST_CODE
                     || SUBSTR (SQLERRM, 1, 200);  -- Modified for defect Id:12838
                  v_respcode := '21';
                  RAISE exp_reject_record;
            END;
        --END Added for FSS-1961(Melissa)
          END IF;
      END IF;
   EXCEPTION
       WHEN   exp_reject_record
       THEN
        RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'ERROR IN PROFILE UPDATE -- Addr/Cust Mast ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
     -- Added for FSS-1961(Melissa)
     BEGIN

           SELECT cust.ccm_cust_id,
			decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cust.ccm_first_name),cust.ccm_first_name)||' '||
			decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cust.ccm_last_name),cust.ccm_last_name),
			addr.cam_add_one, addr.cam_add_two, addr.cam_city_name, 
			addr.cam_state_switch, addr.cam_pin_code
           INTO V_CUST_ID,V_FULL_NAME,V_MAILADDR_LINEONE,V_MAILADDR_LINETWO,
           V_MAILADDR_CITY,v_mailing_switch_state_code,V_MAILADDR_ZIP
           FROM CMS_CUST_MAST cust,cms_addr_mast addr
           WHERE addr.cam_inst_code = cust.ccm_inst_code
           AND addr.cam_cust_code = cust.ccm_cust_code
           AND cust.CCM_INST_CODE = P_INSTCODE
           AND cust.CCM_CUST_CODE = P_CUST_CODE
           and addr.cam_addr_flag='O';

       EXCEPTION
         WHEN NO_DATA_FOUND THEN
         v_respcode := '21';
         V_ERRMSG := 'Mailing Addess Not Found';
          RAISE EXP_MAIN_REJECT_RECORD;
         WHEN OTHERS THEN
         v_respcode := '21';
         V_ERRMSG := 'Error while selecting mailing address ' || SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;

      END;

      BEGIN

          SELECT COUNT(1) INTO V_AVQ_STATUS
          FROM CMS_AVQ_STATUS
          WHERE CAS_INST_CODE=P_INSTCODE AND CAS_CUST_ID=V_CUST_ID AND CAS_AVQ_FLAG='P';

            IF V_AVQ_STATUS = 1 THEN
            
                IF  V_ENCRYPT_ENABLE = 'Y' then
                  v_encr_full_name := fn_emaps_main(V_FULL_NAME);
                ELSE
                   v_encr_full_name := V_FULL_NAME;
                END IF;  
                

                UPDATE CMS_AVQ_STATUS
                      SET CAS_ADDR_ONE=nvl(V_MAILADDR_LINEONE,CAS_ADDR_ONE),
                          CAS_ADDR_TWO=nvl(V_MAILADDR_LINETWO,CAS_ADDR_TWO),
                          CAS_CITY_NAME =nvl(V_MAILADDR_CITY,CAS_CITY_NAME),
                          CAS_STATE_NAME=NVL(v_mailing_switch_state_code,CAS_STATE_NAME),
                          CAS_POSTAL_CODE =nvl(V_MAILADDR_ZIP,CAS_POSTAL_CODE),
                          CAS_LUPD_USER=1,
                          CAS_LUPD_DATE=sysdate
                WHERE CAS_INST_CODE=P_INSTCODE AND CAS_CUST_ID=V_CUST_ID AND CAS_AVQ_FLAG='P';

                    -- SQL%ROWCOUNT =0 not required
            else

                BEGIN
                  SELECT COUNT(1) INTO V_AVQ_STATUS
                  FROM CMS_AVQ_STATUS
                  WHERE CAS_INST_CODE=P_INSTCODE AND CAS_CUST_ID=V_CUST_ID AND CAS_AVQ_FLAG='F';

                  IF V_AVQ_STATUS <> 0 THEN


                       BEGIN
                         SELECT pan.cap_pan_code ,pan.cap_pan_code_encr
                           INTO v_gprhash_pan ,v_gprencr_pan
                           FROM cms_appl_pan pan, cms_cardissuance_status issu
                          WHERE pan.cap_appl_code = issu.ccs_appl_code
                            AND pan.cap_pan_code = issu.ccs_pan_code
                            AND pan.cap_inst_code = issu.ccs_inst_code
                            AND pan.cap_inst_code = P_INSTCODE
                            AND issu.ccs_card_status='17'
                            AND pan.cap_cust_code =P_CUST_CODE
                            AND pan.cap_startercard_flag = 'N';
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                        NULL;
                         WHEN OTHERS
                         THEN
                            v_respcode := '21';
                            V_ERRMSG := 'Error while selecting (gpr card)details from appl_pan :'
                               || SUBSTR (SQLERRM, 1, 200);
                            RAISE EXP_MAIN_REJECT_RECORD;
                      end;

                      IF(v_gprhash_pan IS NOT NULL) THEN
                      INSERT INTO CMS_AVQ_STATUS
                      (CAS_INST_CODE,
                       CAS_AVQSTAT_ID,
                       CAS_CUST_ID,
                       CAS_PAN_CODE,
                       CAS_PAN_ENCR,
                       CAS_CUST_NAME,
                       CAS_ADDR_ONE,
                       CAS_ADDR_TWO,
                       CAS_CITY_NAME,
                       CAS_STATE_NAME,
                       CAS_POSTAL_CODE,
                       CAS_AVQ_FLAG,
                       CAS_INS_USER,
                       CAS_INS_DATE)
                      VALUES
                      (P_INSTCODE,
                       AVQ_SEQ.NEXTVAL,
                       V_CUST_ID,
                       --V_HASH_PAN,
                       --V_ENCR_PAN,
                       v_gprhash_pan,
                       v_gprencr_pan,
                       v_encr_full_name,
                       V_MAILADDR_LINEONE,
                       V_MAILADDR_LINETWO,
                       V_MAILADDR_CITY,
                       v_mailing_switch_state_code,
                       V_MAILADDR_ZIP,
                       'P',
                       1,
                       SYSDATE);
                       END IF;
                  END IF;
                 EXCEPTION
                   when EXP_MAIN_REJECT_RECORD then
                  raise;
                  WHEN OTHERS THEN
                   V_RESPCODE := '21';
                   V_ERRMSG := 'Exception while Inserting in CMS_AVQ_STATUS Table ' ||
                             SUBSTR(SQLERRM, 1, 200);
                   RAISE EXP_MAIN_REJECT_RECORD;
              END;


            END IF;
          EXCEPTION
             WHEN EXP_MAIN_REJECT_RECORD THEN
              RAISE;
             WHEN OTHERS THEN
               v_respcode := '21';
               V_ERRMSG := 'Error while updating mailing address(AVQ) ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
      END;
       --END Added for FSS-1961(Melissa)

   -- appl pan update starts
   BEGIN
         UPDATE CMS_APPL_PAN
            SET CAP_DISP_NAME = p_first_name
            WHERE CAP_INST_CODE = p_instcode
            and CAP_PROXY_NUMBER = p_proxyno
            and CAP_CARD_STAT <> '9';
          IF sql%rowcount = 0 then
          v_respcode := '21';
            v_errmsg := 'Display name in applpan not get updated for proxy number:'||p_proxyno;
           RAISE exp_reject_record;
          end if;
      EXCEPTION
         when exp_reject_record
         THEN
        RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                     'ERROR IN CMS_APPL_PAN UPDATE:- ' ||P_CUST_CODE|| '--'||SUBSTR (SQLERRM, 1, 200);  -- Modified for defect Id:12838
            RAISE exp_reject_record;
      END;
   -- appl pan update ends
   --- CAF INFO ENTRY UPDATE START
   BEGIN
   
          IF v_encrypt_enable = 'Y' then
              v_encr_mothers_maiden_name :=fn_emaps_main(p_mother_name);
              v_encr_cci_seg12_name_line1:=fn_emaps_main(p_first_name);
              v_encr_cci_seg12_name_line2:=fn_emaps_main(p_last_name);
              v_encr_cci_seg12_addr_line1:=fn_emaps_main(p_addr_lineone);
              v_encr_cci_seg12_addr_line2:=fn_emaps_main(p_addr_linetwo);
              v_encr_cci_seg12_city:=fn_emaps_main(p_city);
              v_encr_cci_seg12_postal_code:=fn_emaps_main(p_zip);
              v_encr_cci_seg12_mobileno:=fn_emaps_main(p_mobile_no);
              v_encr_cci_seg12_emailid :=fn_emaps_main(p_email);
              v_encr_cci_seg13_addr_line1:=fn_emaps_main(p_mailing_addr1);
              v_encr_cci_seg13_addr_line2:=fn_emaps_main(p_mailing_addr2);
              v_encr_cci_seg13_city:=fn_emaps_main(p_mailing_city);
              v_encr_cci_seg13_postal_code:=fn_emaps_main(p_mailing_zip);
            else
              v_encr_mothers_maiden_name:= p_mother_name;
              v_encr_cci_seg12_name_line1:=p_first_name;
              v_encr_cci_seg12_name_line2:= p_last_name;
              v_encr_cci_seg12_addr_line1:=p_addr_lineone;
              v_encr_cci_seg12_addr_line2:=p_addr_linetwo;
              v_encr_cci_seg12_city:=p_city;
              v_encr_cci_seg12_postal_code:=p_zip;
              v_encr_cci_seg12_mobileno:=p_mobile_no;
              v_encr_cci_seg12_emailid:=p_email;
              v_encr_cci_seg13_addr_line1:=p_mailing_addr1;
              v_encr_cci_seg13_addr_line2:=p_mailing_addr2;
              v_encr_cci_seg13_city:=p_mailing_city;
              v_encr_cci_seg13_postal_code:=p_mailing_zip;
   
          END IF;    
      UPDATE cms_caf_info_entry
         SET cci_document_verify =  p_idtype,
             cci_id_issuer = p_idissuer ,
             cci_id_number = fn_maskacct_ssn(p_instcode,p_idnumber,0),
             cci_id_number_encr = fn_emaps_main(p_idnumber),
             cci_id_issuance_date =p_idissudate, 
             cci_id_expiry_date = p_idexpirdate,  
             cci_birth_date = p_dob,
             cci_mothers_maiden_name = v_encr_mothers_maiden_name,
             cci_ssn = fn_maskacct_ssn(p_instcode,p_ssn,0),
             cci_seg12_name_line1 = v_encr_cci_seg12_name_line1,
             cci_seg12_name_line2 = v_encr_cci_seg12_name_line2,
             cci_seg12_addr_line1 = v_encr_cci_seg12_addr_line1,
             cci_seg12_addr_line2 = v_encr_cci_seg12_addr_line2,
             cci_seg12_city = v_encr_cci_seg12_city,
             cci_seg12_state = p_state,
             cci_seg12_postal_code = v_encr_cci_seg12_postal_code,
             cci_seg12_country_code = p_cntry_code,
             cci_seg12_mobileno = v_encr_cci_seg12_mobileno,
             cci_seg12_emailid = v_encr_cci_seg12_emailid,
             cci_seg13_addr_line1 =  v_encr_cci_seg13_addr_line1,
             cci_seg13_addr_line2 =  v_encr_cci_seg13_addr_line2,
             cci_seg13_city = v_encr_cci_seg13_city,
             cci_seg13_state = p_mailing_state,
             cci_seg13_country_code = p_mailing_country,
             cci_seg13_postal_code = v_encr_cci_seg13_postal_code,
             cci_alternate_id = p_altid,
             cci_cip_check = p_cpi_check,
             cci_ssn_encr = fn_emaps_main(p_ssn),
             CCI_SEG12_NAME_LINE1_ENCR = fn_emaps_main(p_first_name),
             CCI_SEG12_NAME_LINE2_ENCR  = fn_emaps_main(p_last_name),
             CCI_SEG12_ADDR_LINE1_ENCR  = fn_emaps_main(p_addr_lineone),
             CCI_SEG12_ADDR_LINE2_ENCR  = fn_emaps_main(p_addr_linetwo),          
             CCI_SEG12_CITY_ENCR 	   = fn_emaps_main(p_city),
             CCI_SEG12_POSTAL_CODE_ENCR = fn_emaps_main(p_zip),
             CCI_SEG12_EMAILID_ENCR	   = fn_emaps_main(p_email)	
       WHERE cci_appl_code = P_APPL_CODE;  -- Modified for defect Id:12838

      IF SQL%ROWCOUNT = 0
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Record not get updated in  cms_caf_info_entry:-'||P_APPL_CODE||'--'
            || SUBSTR (SQLERRM, 1, 200); -- Modified for defect Id:12838
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while updating cms_caf_info_entry'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
--- CAF INFO ENTRY UPDATE END  -- added columns in transactionlog and transactionlog_dtl  for defect Id:12838
 BEGIN
          INSERT INTO transactionlog
                     (MSGTYPE,
                     RRN,
                     delivery_channel,
                     date_time,
                     txn_code,
                     txn_mode,
                     txn_status,
                     response_code,
                     business_date,
                     business_time,
                     instcode,
                     error_msg,
                     CUSTOMER_ACCT_NO,   --Added by Besky on 09-nov-12
                     CUSTOMER_CARD_NO,
                     CUSTOMER_CARD_NO_ENCR,
                     PRODUCTID,
                     CATEGORYID,
                     TRANS_DESC,
                     ACCT_BALANCE,
                     LEDGER_BALANCE,
                     TXN_TYPE,
                     CR_DR_FLAG,
                     ADD_INS_USER,
                     REVERSAL_CODE,
                     PROXY_NUMBER,
                     RESPONSE_ID,
                     CARDSTATUS,
                     ACCT_TYPE,
                     TIME_STAMP,CURRENCYCODE
                     )
              VALUES ('0200',
                     p_rrn,
                     p_delivery_channel,
                     SYSDATE,
                     p_txn_code,
                     p_txn_mode,
                     'C',
                     p_resp_code,
                     p_trandate,
                     p_trantime,
                     p_instcode,
                     p_errmsg,
                     P_ACCT_NO,  --Added by Besky on 09-nov-12
                     v_hash_pan,
                     v_encr_pan,
                     P_prod_code,
                     P_PROD_CATG,
                     v_trans_desc,
                     v_acct_bal,
                     v_ledger_bal,
                     '0',
                     'NA',
                     '1',
                     '0',
                     p_proxyno,
                     '1',  --response id
                     P_CARD_STAT,
                     v_acct_type, 
                     V_TIME_STAMP,p_currcode
                     );

      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '99';
            p_errmsg :='Problem while inserting data into transaction log '|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

     BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel,
                      ctd_txn_code,
                      ctd_txn_type,
                      ctd_business_date,
                      ctd_business_time,
                      ctd_customer_card_no,
                      ctd_txn_curr,
                      ctd_process_flag,
                      ctd_process_msg,
                      ctd_rrn,
                      ctd_customer_card_no_encr,
                      ctd_msg_type,
                      ctd_cust_acct_number,
                      ctd_inst_code
                     )
              VALUES (p_delivery_channel,
                      p_txn_code,
                      '0',
                      p_trandate,
                      p_trantime,
                      v_hash_pan,
                      p_currcode,
                      'Y',
                      'Successful',
                      p_rrn,
                      v_encr_pan,
                      p_msg_type,
                      NULL,
                      p_instcode
                     );

      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '99';
            p_errmsg :='Problem while inserting data into  cms_transaction_log_dtl-1'|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;


EXCEPTION
   WHEN exp_reject_record
   THEN
   p_errmsg := v_errmsg;
      ROLLBACK;

-- added for defect Id:12838
 BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO p_resp_code
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INSTCODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = v_respcode ;

    EXCEPTION
     WHEN OTHERS THEN
       p_errmsg  := 'Problem while selecting data from response master ' || SUBSTR(SQLERRM, 1, 200);
       p_resp_code := '69';
         RETURN;
    END;

-- added columns in transactionlog and transactionlog_dtl  for defect Id:12838
BEGIN
        INSERT INTO transactionlog
                     (MSGTYPE,
                     RRN,
                     delivery_channel,
                     date_time,
                     txn_code,
                     txn_mode,
                     txn_status,
                     response_code,
                     business_date,
                     business_time,
                     instcode,
                     error_msg,
                     CUSTOMER_ACCT_NO,   --Added by Besky on 09-nov-12
                     CUSTOMER_CARD_NO,
                     CUSTOMER_CARD_NO_ENCR,
                     PRODUCTID,
                     CATEGORYID,
                     TRANS_DESC,
                     ACCT_BALANCE,
                     LEDGER_BALANCE,
                     TXN_TYPE,
                     CR_DR_FLAG,
                     ADD_INS_USER,
                     REVERSAL_CODE,
                     PROXY_NUMBER,
                     RESPONSE_ID,
                     CARDSTATUS,
                     ACCT_TYPE,
                     TIME_STAMP,CURRENCYCODE
                     )
              VALUES ('0200',
                     p_rrn,
                     p_delivery_channel,
                     SYSDATE,
                     p_txn_code,
                     p_txn_mode,
                     'F',
                     p_resp_code,
                     p_trandate,
                     p_trantime,
                     p_instcode,
                     p_errmsg,
                     P_ACCT_NO,  --Added by Besky on 09-nov-12
                     v_hash_pan,
                     v_encr_pan,
                     P_prod_code,
                     P_PROD_CATG,
                     v_trans_desc,
                     v_acct_bal,
                     v_ledger_bal,
                     '0',
                     'NA',
                     '1',
                     '0',
                     p_proxyno,
                     v_respcode,  
                     P_CARD_STAT, 
                     v_acct_type, 
                     V_TIME_STAMP,p_currcode
                     );

      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '99';
            p_errmsg :='Problem while inserting data into transaction log '|| SUBSTR (SQLERRM, 1, 200);

      END;


      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel,
                      ctd_txn_code,
                      ctd_txn_type,
                      ctd_business_date,
                      ctd_business_time,
                      ctd_customer_card_no,
                      ctd_txn_curr,
                      ctd_process_flag,
                      ctd_process_msg,
                      ctd_rrn,
                      ctd_customer_card_no_encr,
                      ctd_msg_type,
                      ctd_cust_acct_number,
                      ctd_inst_code
                     )
              VALUES (p_delivery_channel,
                      p_txn_code,
                      '0',
                      p_trandate,
                      p_trantime,
                      v_hash_pan,
                      p_currcode,
                      'E',
                      v_errmsg,
                      p_rrn,
                      v_encr_pan,
                      p_msg_type,
                      NULL,
                      p_instcode
                     );

      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '99';
            p_errmsg :='Problem while inserting data into cms_transaction_log_dtl-2'|| SUBSTR (SQLERRM, 1, 200);
      END;
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_errmsg :=
            'ERROR IN PROFILE UPDATE MAIN'
         || '--'
         || SUBSTR (SQLERRM, 1, 200);
      p_resp_code := '89';
END;

/
show error;