create or replace
PROCEDURE                     vmscms.SP_CARD_ISSUENCE_GPR(
    p_inst_code           IN NUMBER,
    p_rrn                 IN VARCHAR2,
    p_prod_code           IN VARCHAR2, 
    p_card_type           IN VARCHAR2,
    p_business_date       IN VARCHAR2,
    p_business_time       IN VARCHAR2,
    p_delivery_channel    IN VARCHAR2,
    p_txn_code            IN VARCHAR2,
    p_idologyid           IN VARCHAR2,
    p_firstname           IN VARCHAR2,
    p_lastname            IN VARCHAR2,
    p_physical_add_one    IN VARCHAR2,
    p_physical_add_two    IN VARCHAR2,
    p_city                IN VARCHAR2,
    p_cntry_code          IN VARCHAR2,
    P_STATE_CODE          in varchar2,
    p_zipcode             IN VARCHAR2,
    p_mobile_no           IN NUMBER,
    p_telnumber           IN VARCHAR2,
    p_email_add           IN VARCHAR2,
    p_dob                 IN VARCHAR2,
    p_mailing_add_one     IN VARCHAR2,
    p_mailing_add_two     IN VARCHAR2,
    p_mailing_city        IN VARCHAR2,
    p_mail_cntry_code     IN VARCHAR2,
    p_mail_state_code     IN VARCHAR2,
    p_mailing_zipcode     IN VARCHAR2,
    p_mothers_maiden_name IN VARCHAR2,
    p_rowID               IN NUMBER,
    p_id_number           IN VARCHAR2,
    p_document_verify     IN VARCHAR2,
    p_id_issuer           IN VARCHAR2,
    p_issuance_date       IN VARCHAR2,
    p_expiry_date         IN VARCHAR2,
    p_cci_a1              IN VARCHAR2,
    p_cci_a2              IN VARCHAR2,
    p_cci_a3              IN VARCHAR2,
    p_ipaddress           IN VARCHAR2,
    P_PACKAGE_TYPE        IN VARCHAR2 DEFAULT NULL, --Added for LYFEHOST-58
    P_PRODPACKAGE_FLAG    IN VARCHAR2 DEFAULT NULL, --Added for LYFEHOST-58
    P_RESP_CODE           OUT VARCHAR2,
    p_errmsg              OUT VARCHAR2,
    p_security_q1         OUT VARCHAR2,
    p_security_q2         OUT VARCHAR2,
    p_security_q3         OUT VARCHAR2,
    p_RespRowID           OUT VARCHAR2,
    p_switch_state_code   OUT VARCHAR2,  -- Added for MVHOST -355 by Amudhan S
    p_mailing_state_code  OUT VARCHAR2   -- Added for MVHOST -355 by Amudhan S
    ,p_cci_a4             IN VARCHAR2 DEFAULT NULL,
     p_security_q4        OUT VARCHAR2)
AS
  /**************************************************************************
  * Created Date       : 18_July_2013
  * Created By         : Arunprasath
  * Purpose            : Card Issuance Process GPR
  * Reviewer           : Dhiraj
  * Reviewed Date      : 19-aug-2013
  * Release Number     : RI024.4_B0002

   * Modified Date     : 22_Aug_2013
  * Modified By        : Ramesh
  * Purpose            : Defect : 12097
  * Reviewer           : Dhiraj
  * Reviewed Date      : 22_Aug_2013
  * Release Number     : RI0024.4_B0002

  * Modified By        : Amudhan S
  * Modified Date      : 22-Aug-2013
  * Modified Reason    : To get the state code for sending the idiology Server -MVHOST-355
  * Reviewer           : Dhiraj
  * Reviewed Date      : 22_Aug_2013
  * Release Number     : RI0024.4_B0003

  * Modified By        : Siva Kumar
  * Modified Date      : 11-Sept-2013
  * Modified Reason    : Defect id(s):12285
  * Reviewer           : Dhiraj
  * Reviewed Date      : 12-Sept-2013
  * Build Number       : RI0024.4_B0010

  * Modified By      : Ramesh A
  * Modified Date    : 17-Sept-2013
  * Modified Reason  : Defect id:12310
  * Reviewer         : Dhiraj
  * Reviewed Date    :
  * Build Number     : RI0024.4_B0016

  * Modified By      : Arun vijay
  * Modified Date    : 31-Sept-2013
  * Modified Reason  : LYFEHOST-58
  * Reviewer         : Dhiraj
  * Reviewed Date    : 19-09-2013
  * Build Number     : RI0024.5_B0001

  * Modified By      : Arun vijay
  * Modified Date    : 15-oct-2013
  * Modified Reason  : 12681
  * Reviewer         : Dhiraj
  * Reviewed Date    : 15-10-2013
  * Build Number     : RI0024.5_B0004

  * Modified By      : Ramesh
  * Modified Date    : 02-Jan-2014
  * Modified Reason  : FSS-1303 : Modified the v_seq_val variable from number to varchar2
  * Reviewer         : Dhiraj
  * Reviewed Date    : 02-Jan-2014
  * Build Number     : RI0024.6.4_B0001

  * Modified By      : MageshKumar S.
  * Modified Date    : 10-Jan-2014
  * Modified Reason  : MVHOST-822 -  Incorrect responsecode logged during card Registration
  * Reviewer         : Dhiraj
  * Reviewed Date    :
  * Build Number     : RI0027_B0005

  * Modified By      : DINESH B.
  * Modified Date    : 10-Apr-2014
  * Modified Reason  : MOB-62 - Adding delievery channel.
  * Reviewer         : spankaj
  * Reviewed Date    : 15-April-2014
  * Build Number     : RI0027.2_B0005
  
  * Modified By      : Abdul Hammed
  * Modified Reason  : FWR-70
  * Reviewer         : spankaj
  * Build Number     : RI0027.4_B0002
  
  * Modified By      : Siva Kumar 
  * Modified Reason  : mantis id:15857
  * Reviewer         : spankaj 
  * Build Number     : RI0027.4.3_B0004 
  
  * Modified by                  : MageshKumar S.
  * Modified Date                : 23-June-15
  * Modified For                 : MVCAN-77  
  * Modified reason              : Canada account limit check
  * Reviewer                     : Spankaj
  * Build Number                 : VMSGPRHOSTCSD3.1_B0001
  
  * Modified by                  : MageshKumar S.
  * Modified Date                : 22-June-15
  * Modified For                 : IDSCAN CHANGES
  * Reviewer                     : Spankaj
  * Build Number                 : VMSGPRHOSTCSD3.2_B0002
  
   * Modified by       :Siva kumar 
   * Modified Date    : 22-Mar-16
   * Modified For     : MVHOST-1323
   * Reviewer         : Saravanankumar/Pankaj
   * Build Number     : VMSGPRHOSTCSD_4.0_B006

  * Modified by      :  Vini Pushkaran
  * Modified Date    :  02-Feb-2018
  * Modified For     :  VMS-162
  * Reviewer         :  Saravanankumar
  * Build Number     :  VMSGPRHOSTCSD_18.01
  
    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18

  * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
  
  ****************************************************************************/

  v_prod_count               PLS_INTEGER;
  v_rrn_count                PLS_INTEGER;
  v_seq_val                  VARCHAR2(10); --Modified for fss-1303 on 02/01/14
  V_SEQ_VAL_TEMP             PLS_INTEGER;  --Added for fss-1303 on 02/01/14
  v_agecal                   PLS_INTEGER;
  v_kyc_age                  cms_prod_cattype.cpc_min_age_kyc%TYPE;
  v_serl_flag                cms_prod_cattype.cpc_serl_flag%TYPE;
  v_cbm_bran_code            cms_bran_mast.cbm_bran_code%TYPE;
  v_curr_code                gen_cntry_mast.gcm_curr_code%TYPE;
  v_gsm_switch_state_code    gen_state_mast.gsm_switch_state_code%TYPE;
  v_mail_gsm_switch_state_code  gen_state_mast.gsm_switch_state_code%TYPE;
  v_CPC_CUST_CATG            cms_prod_ccc.CPC_CUST_CATG%type;   
  v_ccc_catg_sname           CMS_CUST_CATG.ccc_catg_sname%type;
  v_cci_upld_stat            cms_caf_info_entry.cci_upld_stat%TYPE;
  v_card_dtl                 VARCHAR2 (4000);
  v_resp_cde                 transactionlog.response_id%type := '1';
  v_trans_desc               cms_transaction_mast.ctm_tran_desc%type;
  v_document_verify          cms_caf_info_entry.cci_document_verify%type; -- added for review changes on 16/Aug/2013.
  v_dob                      cms_caf_info_entry.cci_birth_date%type;
  --Start LYFEHOST-58
  V_PACKAGE_ID               CMS_PROD_CATTYPE.CPC_PACKAGE_ID%TYPE;
  V_PACKAGE_TYPE             CMS_CAF_INFO_ENTRY.cci_package_type%TYPE;
  V_PACKAGEID_CNT            NUMBER;
  V_PROD_PACKAGE_ID          CMS_PROD_CARDPACK.CPC_CARD_DETAILS%TYPE;   --added FOR MANTIS ID:15857 ON 13-NOV-2014
  --End LYFEHOST-58  
  V_FLDOB_HASHKEY_ID         CMS_CUST_MAST.CCM_FLNAMEDOB_HASHKEY%TYPE;  --Added for MVCAN-77 OF 3.1 RELEASE
  v_encrypt_enable           CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
  v_encr_telnum			     CMS_CAF_INFO_ENTRY.CCI_SEG12_HOMEPHONE_NO%TYPE;
  v_encr_firstname           CMS_CAF_INFO_ENTRY.CCI_SEG12_NAME_LINE1%TYPE;     
  v_encr_lastname            CMS_CAF_INFO_ENTRY.CCI_SEG12_NAME_LINE2%TYPE;     
  v_encr_p_add_one           CMS_CAF_INFO_ENTRY.CCI_SEG12_ADDR_LINE1%TYPE; 
  v_encr_p_add_two           CMS_CAF_INFO_ENTRY.CCI_SEG12_ADDR_LINE2%TYPE; 
  v_encr_city                CMS_CAF_INFO_ENTRY.CCI_SEG12_CITY%TYPE;    
  v_encr_zipcode             CMS_CAF_INFO_ENTRY.CCI_SEG12_POSTAL_CODE%TYPE;     
  v_encr_mobile_no           CMS_CAF_INFO_ENTRY.CCI_SEG12_MOBILENO%TYPE;    
  v_encr_email_add           CMS_CAF_INFO_ENTRY.CCI_SEG12_EMAILID%TYPE;     
  v_encr_m_add_one           CMS_CAF_INFO_ENTRY.CCI_SEG13_ADDR_LINE1%TYPE;                                    
  v_encr_m_add_two           CMS_CAF_INFO_ENTRY.CCI_SEG13_ADDR_LINE2%TYPE;                                   
  v_encr_m_city              CMS_CAF_INFO_ENTRY.CCI_SEG13_CITY%TYPE;                                  
  v_encr_m_zipcode           CMS_CAF_INFO_ENTRY.CCI_SEG13_POSTAL_CODE%TYPE;                                    
  v_encr_mothers_name        CMS_CAF_INFO_ENTRY.CCI_MOTHERS_MAIDEN_NAME%TYPE;
  v_encr_requester_name      CMS_CAF_INFO_ENTRY.CCI_REQUESTER_NAME%TYPE; 
  exp_reject_record          EXCEPTION; 
  v_Retperiod  date;  --Added for VMS-5733/FSP-991
  v_Retdate  date; --Added for VMS-5733/FSP-991   
  
BEGIN
  p_errmsg := 'OK';
  --Sn txn validation
  BEGIN
    SELECT ctm_tran_desc
    INTO v_trans_desc
    FROM cms_transaction_mast
    WHERE ctm_inst_code      = p_inst_code
    AND ctm_tran_code        = p_txn_code
    AND ctm_delivery_channel = p_delivery_channel;
    IF v_trans_desc         IS NULL THEN
      v_resp_cde            := '21';
      p_errmsg              := 'Transaction Not Defined';
      RAISE exp_reject_record;
    END IF;
  EXCEPTION
  WHEN exp_reject_record THEN
    RAISE;
  WHEN OTHERS THEN
    v_resp_cde := '21';
    p_errmsg   := 'Error while checking transaction mast details-'|| SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  --En txn validation
   BEGIN

   SELECT upper(p_document_verify)
   INTO  v_document_verify
   FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
        v_resp_cde := '21';
        p_errmsg  := 'Error while converting document_verify '|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
  END;
  --En converting the variable p_document_verify

  BEGIN
--Added for VMS-5733/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date), 1, 8), 'yyyymmdd');


  IF (v_Retdate>v_Retperiod)
    THEN
    SELECT COUNT (1)
    INTO v_rrn_count
    FROM transactionlog
    WHERE rrn            = p_rrn
    AND business_date    = p_business_date
    AND delivery_channel = p_delivery_channel
    AND instcode         = p_inst_code;
  else
    SELECT COUNT (1)
    INTO v_rrn_count
    FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
    WHERE rrn            = p_rrn
    AND business_date    = p_business_date
    AND delivery_channel = p_delivery_channel
    AND instcode         = p_inst_code;
  end if;
  IF v_rrn_count       > 0 THEN
      v_resp_cde        := '22';
      p_errmsg          := 'Duplicate RRN from the Terminal on ' || p_business_date;
      RAISE exp_reject_record;
    END IF;
  EXCEPTION
  WHEN exp_reject_record THEN
    RAISE;
  WHEN OTHERS THEN
    v_resp_cde := '21';
    p_errmsg   := 'Error while checking for duplicate RRN-'|| SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  --En Duplicate RRN Check
  --Sn Check the Product Code
  BEGIN
    SELECT COUNT(1)
    INTO v_prod_count
    FROM cms_prod_cattype
    WHERE cpc_prod_code =p_prod_code
    AND cpc_card_type   =p_card_type
    AND cpc_inst_code   =p_inst_code
    AND cpc_starter_card='N';
    IF v_prod_count     = 0 THEN
      v_resp_cde       := '21';
      p_errmsg         := 'Invalid Data for Product Category';
      RAISE exp_reject_record;
    END IF;
  EXCEPTION
  WHEN exp_reject_record THEN
    RAISE;
  WHEN OTHERS THEN
    v_resp_cde := '21';
    p_errmsg   := 'Error while checking for Product and Category:'|| SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
   --Start LYFEHOST-58
      IF  ( P_PACKAGE_TYPE IS NOT NULL ) AND ( P_PRODPACKAGE_FLAG IS NOT NULL) THEN

              BEGIN
                    
                   SELECT PAK.CPC_CARD_DETAILS
                    INTO V_PROD_PACKAGE_ID                    
                    FROM CMS_PROD_CATTYPE CAT,CMS_PROD_CARDPACK PAK
                    WHERE CAT.CPC_PROD_CODE = P_PROD_CODE
                    AND CAT.CPC_CARD_TYPE = P_CARD_TYPE
                    AND CAT.CPC_CARD_ID=PAK.CPC_CARD_ID
                    AND CAT.CPC_INST_CODE=PAK.CPC_INST_CODE
                    AND CAT.CPC_INST_CODE =P_INST_CODE;
 
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  V_RESP_CDE := '207';
                  P_ERRMSG   := 'PackageId/ProductId not configured for product';
                   RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                  V_RESP_CDE := '21';
                  P_ERRMSG   := 'Error while selecting PackageId'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
              END;

          BEGIN

          SELECT COUNT(*) INTO V_PACKAGEID_CNT FROM CMS_PRODPACKAGE_MAPPING
          WHERE CPM_PROD_CODE = P_PROD_CODE
          AND CPM_CARD_TYPE = P_CARD_TYPE
          AND CPM_PRODPACK_IDS = P_PACKAGE_TYPE
          AND CPM_INST_CODE = P_INST_CODE;
                     
              if   ( V_PACKAGEID_CNT = 0 and ((V_PROD_PACKAGE_ID is not null ) and (V_PROD_PACKAGE_ID <> P_PACKAGE_TYPE ) ) )
              THEN

              V_RESP_CDE := '207';
              P_ERRMSG := 'PackageId/ProductId not configured for product' || '--' || P_PACKAGE_TYPE;
              RAISE EXP_REJECT_RECORD;
              END IF;
          EXCEPTION
              WHEN EXP_REJECT_RECORD THEN
              RAISE EXP_REJECT_RECORD;
          WHEN OTHERS
              THEN
              V_RESP_CDE := '21';
              P_ERRMSG :=
              'Error while selecting V_PACKAGEID_CNT ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;

          END;

          IF V_PACKAGE_ID IS NOT NULL  AND V_PROD_PACKAGE_ID <> P_PACKAGE_TYPE 

          THEN

          V_PACKAGE_TYPE := P_PACKAGE_TYPE;

          ELSE

          V_PACKAGE_TYPE := NULL;

          END IF;

      END IF;
      --End LYFEHOST-58
      
      --Start Generate HashKEY for MVCAN-77
       BEGIN
           V_FLDOB_HASHKEY_ID := GETHASH (UPPER(p_firstname)||UPPER(p_lastname)||to_date(p_dob,'mmddyyyy'));
       EXCEPTION
        WHEN OTHERS
        THEN
        v_resp_cde := '21';
        p_errmsg :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
     END;
    --End Generate HashKEY for  MVCAN-77

  --En Check the Product Code
  IF p_idologyid IS NULL THEN
   IF p_delivery_channel IN ('06','03','13') AND p_txn_code IN('01','17') THEN --Modified for MOB-62
      --Sn txn validation
      --Sn card type validation
      BEGIN
        SELECT CPC_CUST_CATG
        INTO v_CPC_CUST_CATG
        FROM cms_prod_ccc
        WHERE CPC_INST_CODE=p_inst_code
        AND CPC_PROD_CODE  =p_prod_code
        AND cpc_card_type = p_card_type
        AND rownum         =1;
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_cde := '21';
        p_errmsg   := 'Error while selecting Card type-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En card type validation

      -- Sn DOB Validation.  add for review cahnges on 16/Aug/2013
      BEGIN

      v_dob:=to_date(p_dob,'mmddyyyy');

      EXCEPTION
        WHEN OTHERS THEN
        v_resp_cde := '21';
        p_errmsg   := 'Error while converting dob-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
       END;
      -- En DOB Validation.


      --Sn KYC age validation
      BEGIN
        v_agecal := (TRUNC(sysdate)-v_dob)/365;   --modified for review cahnges on 16/Aug/2013

        if v_agecal < 0 then

          v_resp_cde := '21';
          p_errmsg   := 'Error while calculating KYC age, DOB should not be future date';
         RAISE exp_reject_record;

        end if;
      EXCEPTION
      WHEN exp_reject_record THEN
       RAISE;
      WHEN OTHERS THEN
        v_resp_cde := '21';
        p_errmsg   := 'Error while calculating KYC age-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En KYC age validation
      BEGIN
        SELECT cpc_min_age_kyc,
          cpc_serl_flag,
		  cpc_encrypt_enable
        INTO v_kyc_age,
          v_serl_flag,
		  v_encrypt_enable
        FROM cms_prod_cattype
        WHERE cpc_prod_code=p_prod_code
        AND cpc_card_type  =p_card_type
        AND cpc_inst_code  =p_inst_code;
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_cde := '21';
        p_errmsg   := 'Error while selecting KYC Age-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En KYC age validation
      IF v_agecal   < v_kyc_age THEN
        v_resp_cde := '35';
        p_errmsg   := 'Age Limit Verification Failed';
        RAISE exp_reject_record;
      END IF;
      --Sn KYC branch validation
      --Sn Selecting Branch Code     --UnCommented for defect :12097 on 22/Aug/2013
      BEGIN
        SELECT cbm_bran_code
        INTO v_cbm_bran_code
        FROM cms_bran_mast
        WHERE cbm_inst_code=p_inst_code
        AND rownum         =1;
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_cde := '21';
        p_errmsg   := 'Error while selecting Brand Code-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En Selecting Branch Code
      --Sn selecting sequence number
      BEGIN
        SELECT seq_dirupld_rowid.nextval INTO v_seq_val_temp FROM dual; --Modified for fss-1303 on 02/01/14
        v_seq_val := to_char(v_seq_val_temp); --Added for fss-1303 on 02/01/14
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_cde := '21';
        p_errmsg   := 'Error while selecting Sequence Number-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En selecting sequence number
      --Sn selecting Customer catg
      BEGIN
        SELECT ccc_catg_sname
        INTO v_ccc_catg_sname
        FROM CMS_CUST_CATG
        WHERE CCC_INST_CODE = p_inst_code
        AND CCC_CATG_CODE   = v_CPC_CUST_CATG;
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_cde := '21';
        p_errmsg   := 'Error while selecting Customer Catg-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En selecting Customer catg
	  
      --Sn get currency code
      BEGIN
        SELECT gcm_curr_code
        INTO v_curr_code
        FROM gen_cntry_mast
        WHERE gcm_inst_code    = p_inst_code  -- Modified the query for review comments.
        AND gcm_cntry_code = p_cntry_code;
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_cde := '21';
        p_errmsg   :='Error while selecting country detail-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En get currency code
      --Sn validate state code for mailing and physical address state
      BEGIN
        SELECT gsm_switch_state_code
        INTO v_gsm_switch_state_code
        FROM gen_state_mast
        WHERE gsm_state_code = p_state_code
        AND gsm_cntry_code   = p_cntry_code
        AND gsm_inst_code    = p_inst_code;

        p_switch_state_code:=v_gsm_switch_state_code;  -- Added for getting state code as output param for MVHOST-355 amudhan

      EXCEPTION
      WHEN OTHERS THEN
        p_errmsg :='Error while selecting state detail-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;

      IF p_mail_state_code IS NOT NULL AND p_mail_cntry_code IS NOT NULL THEN
        --En validate state code for mailing address state if entered
        BEGIN
          SELECT gsm_switch_state_code
          INTO v_mail_gsm_switch_state_code
          FROM gen_state_mast
          WHERE gsm_inst_code  = p_inst_code -- Modified the query for review comments.
          AND gsm_cntry_code  = p_mail_cntry_code
          AND gsm_state_code = p_mail_state_code;

         p_mailing_state_code :=v_mail_gsm_switch_state_code;  -- Added for getting state code as output param for MVHOST-355 amudhan

        EXCEPTION
        WHEN OTHERS THEN
          v_resp_cde := '21';
          p_errmsg   := 'Error while selecting state-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
        --En validate state code for mailing address state if entered
      END IF;
 
      --Inserting Data into CMS_CAF_INFO_ENTRY
      IF v_encrypt_enable = 'Y' THEN
	     v_encr_telnum := fn_emaps_main(p_telnumber);
		 v_encr_firstname := fn_emaps_main(p_firstname);                
         v_encr_lastname := fn_emaps_main(p_lastname);                 
 		 v_encr_p_add_one := fn_emaps_main(p_physical_add_one);          
		 v_encr_p_add_two := fn_emaps_main(p_physical_add_two);         
		 v_encr_city := fn_emaps_main(p_city);                    
		 v_encr_zipcode := fn_emaps_main(p_zipcode);                  
		 v_encr_mobile_no := fn_emaps_main(p_mobile_no);                
		 v_encr_email_add := fn_emaps_main(p_email_add);                 
		 v_encr_m_add_one := fn_emaps_main(p_mailing_add_one);                                               
		 v_encr_m_add_two := fn_emaps_main(p_mailing_add_two);                                                
		 v_encr_m_city := fn_emaps_main(p_mailing_city);                                                 
		 v_encr_m_zipcode := fn_emaps_main(p_mailing_zipcode);                                                
		 v_encr_mothers_name := fn_emaps_main(p_mothers_maiden_name);
         v_encr_requester_name:=fn_emaps_main(p_firstname);
	  ELSE
	     v_encr_telnum := p_telnumber;
		 v_encr_firstname := p_firstname;                
         v_encr_lastname := p_lastname;                
 		 v_encr_p_add_one := p_physical_add_one;         
		 v_encr_p_add_two := p_physical_add_two;        
		 v_encr_city := p_city;                     
		 v_encr_zipcode := p_zipcode;                  
		 v_encr_mobile_no := p_mobile_no;                
		 v_encr_email_add := p_email_add;                
		 v_encr_m_add_one := p_mailing_add_one;                                               
		 v_encr_m_add_two := p_mailing_add_two;                                               
		 v_encr_m_city := p_mailing_city;                                                  
		 v_encr_m_zipcode := p_mailing_zipcode;                                               
		 v_encr_mothers_name := p_mothers_maiden_name;
                 v_encr_requester_name:=p_firstname;
	  END IF;
	  
	  BEGIN
        INSERT
        INTO cms_caf_info_entry
          (
            cci_inst_code,
            cci_fiid,
            cci_seg12_homephone_no,
            cci_seg12_name_line1,
            cci_seg12_name_line2,
            cci_seg12_addr_line1,
            cci_seg12_addr_line2,
            cci_seg12_city,
            cci_seg12_state,
            cci_seg12_postal_code,
            cci_seg12_country_code,
            cci_seg12_mobileno,
            cci_seg12_emailid,
            cci_prod_code,
            cci_requester_name,
            cci_ssn,
            cci_birth_date,
            cci_document_verify,
            cci_kyc_flag,
            cci_row_id,
            cci_ins_date,
            cci_lupd_date,
            cci_approved,
            cci_upld_stat,
            cci_entry_rec_type,
            cci_instrument_realised,
            cci_cust_catg,
            cci_comm_type,
            cci_seg13_addr_param9,
            cci_title,
            cci_id_issuer,
            cci_id_number,
            cci_seg13_addr_line1,
            cci_seg13_addr_line2,
            cci_seg13_city,
            cci_seg13_state,
            cci_seg13_postal_code,
            cci_seg13_country_code,
            cci_id_issuance_date,
            cci_id_expiry_date,
            cci_mothers_maiden_name,
            cci_card_type,
            CCI_SEG12_STATE_CODE,
            CCI_SEG13_STATE_CODE,
            CCI_PACKAGE_TYPE,  --LYFEHOST-58
            cci_id_number_encr,
            cci_ssn_encr,
			cci_seg12_name_line1_encr,
            cci_seg12_name_line2_encr,
            cci_seg12_addr_line1_encr,
            cci_seg12_addr_line2_encr,
			cci_seg12_city_encr,
			cci_seg12_postal_code_encr,
			cci_seg12_emailid_encr
                      )
          VALUES
          (
            p_inst_code,                
            v_cbm_bran_code,            --p_cci_fiid,
            v_encr_telnum,             
            v_encr_firstname,          
            v_encr_lastname,         
            v_encr_p_add_one,         
            v_encr_p_add_two,          
            v_encr_city,                
            v_gsm_switch_state_code,    
            v_encr_zipcode,             
            p_cntry_code,               
            v_encr_mobile_no,           
            v_encr_email_add,           
            p_prod_code,                
            v_encr_requester_name,    --firstName
            fn_maskacct_ssn(p_inst_code,DECODE(v_document_verify,'SSN',p_id_number),0),      --p_cci_ssn, --Modified for defect :12310 on 17/09/2013
            v_dob,                                                                           --p_cci_birth_date,  modified for review cahnges on 16/Aug/2013
            v_document_verify,                                                               -- Modified for the review changes on 16/aug/2013
            'N',                                                                             --p_cci_kyc_flag, --KYC flag 'N' for first entry
            v_seq_val,                                                                       --v_seq_val
            sysdate,                                                                         --sysdate r
            NULL,                                                                            --no need r
            'A',                                                                             --p_cci_approved,
            'P',                                                                             --p_cci_upld_stat,
            'P',                                                                             --p_cci_entry_rec_type,
            'Y',                                                                             --p_cci_instrument_realised,
            v_ccc_catg_sname,                                                                --p_cci_cust_catg,
            '0',                                                                             --p_cci_comm_type,
            v_curr_code,                                                                     --p_cci_seg13_addr_param9, -- v_curr_code(need to change)
            'MR',                                                                            --p_cci_title,
            DECODE(v_document_verify,'SSN',NULL,p_id_issuer),                                --p_id_issuer,   Modified for review changes on 16/Aug/2013
            fn_maskacct_ssn(p_inst_code,DECODE(v_document_verify,'SSN',NULL,p_id_number),0), --p_id_number,            Modified for review changes on 16/Aug/2013
            v_encr_m_add_one,                                                                --p_cci_seg13_addr_line1, --mailingAddressLineOne
            v_encr_m_add_two,                                                                --mailingAddressLineTwo
            v_encr_m_city,                                                                   --mailingAddressCity
            v_mail_gsm_switch_state_code,                                                    --mailingAddressState(input)
            v_encr_m_zipcode,                                                                --mailingAddressZip
            p_mail_cntry_code,                                                               --mailingAddresscntrycde
            DECODE(v_document_verify,'SSN',NULL,TO_DATE(p_issuance_date ,'mmddyyyy')),       --p_issuance_date,            Modified for review changes on 16/Aug/2013
            DECODE(v_document_verify,'SSN',NULL,TO_DATE(p_expiry_date ,'mmddyyyy')),         --p_expiry_date,              Modified for review changes on 16/Aug/2013
            v_encr_mothers_name,                                                             --MothersMaidenName---p_cci_mothers_maiden_name,
            p_card_type,
            p_state_code,                                                                    --physicalAddressState
            P_MAIL_STATE_CODE,                                                               --mailingAddressState(input)
            V_PACKAGE_TYPE,                                                                  --LYFEHOST-58
            fn_emaps_main(DECODE(v_document_verify,'SSN',NULL,p_id_number)),
            fn_emaps_main(DECODE(v_document_verify,'SSN',p_id_number)),
			fn_emaps_main(p_firstname),
			fn_emaps_main(p_lastname),                 
 		    fn_emaps_main(p_physical_add_one),         
		    fn_emaps_main(p_physical_add_two),        
		    fn_emaps_main(p_city),                    
		    fn_emaps_main(p_zipcode),                  
		    fn_emaps_main(p_email_add) 
          );
        IF SQL%ROWCOUNT <> 1 THEN
          V_RESP_CDE    := '21';
          p_errmsg      :='Insert not happen in CMS_CAF_INFO_ENTRY';
          RAISE exp_reject_record;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_resp_cde := '89';
        p_errmsg   := 'Error while inserting in cms_caf_info_entry ' || SUBSTR (SQLERRM, 1, 100);
        RAISE exp_reject_record;
      END;
    END IF;

     
    
      BEGIN
        sp_check_ssn_threshold (p_inst_code, p_id_number, p_prod_code,p_card_type, 'EN',v_card_dtl, v_resp_cde, p_errmsg,V_FLDOB_HASHKEY_ID );

      -- Sn Added 0n 10-01-2014 for MVHOST-822
       IF p_errmsg <> 'OK' THEN

         IF p_delivery_channel = '06' OR  p_delivery_channel  = '13'  THEN --Modified for MOB-62
            V_RESP_CDE := '144';
          END IF;

          IF p_delivery_channel = '03' THEN
            V_RESP_CDE := '158';
          END IF;

     -- En Added 0n 10-01-2014 for MVHOST-822

         BEGIN

          UPDATE cms_caf_info_entry
          SET cci_ssn_flag    = 'E',
            cci_ssnfail_dtls  = v_card_dtl,-- Modified 0n 10-01-2014 for MVHOST-822
            cci_process_msg   = p_errmsg
          WHERE cci_inst_code = p_inst_code
          AND cci_row_id      = v_seq_val;
          IF SQL%ROWCOUNT     = 0 THEN
            V_RESP_CDE       := '21';
            p_errmsg         :='Updation not happen in CMS_CAF_INFO_ENTRY for cci_ssn_flag E';
            RAISE exp_reject_record;
          END IF;

         EXCEPTION
           WHEN exp_reject_record THEN  -- Added for review comment changes on 16/Aug/2013
            RAISE;
           WHEN OTHERS THEN
           V_RESP_CDE       := '21';
            p_errmsg         :='Updation not happen in CMS_CAF_INFO_ENTRY for cci_ssn_flag E' ||SUBSTR(SQLERRM, 1, 100);
            RAISE exp_reject_record;

         END;

        ELSE

         BEGIN
          UPDATE cms_caf_info_entry
          SET cci_ssn_flag    = 'Y',
            cci_ssnfail_dtls  = v_card_dtl-- Modified 0n 10-01-2014 for MVHOST-822
          WHERE cci_inst_code = p_inst_code
          AND cci_row_id      = v_seq_val;
          IF SQL%ROWCOUNT     = 0 THEN
            V_RESP_CDE       := '21';
            p_errmsg         :='Updation not happen in CMS_CAF_INFO_ENTRY for cci_ssn_flag Y ' ||v_seq_val||':'||p_inst_code;
            RAISE exp_reject_record;
          END IF;

         EXCEPTION
          WHEN exp_reject_record THEN   -- Added for review comment changes on 16/Aug/2013
          RAISE;
          WHEN OTHERS THEN
            V_RESP_CDE      := '21';
            p_errmsg      :='Updation not happen in CMS_CAF_INFO_ENTRY for cci_ssn_flag E' || SUBSTR(SQLERRM, 1, 100);
            RAISE exp_reject_record;

          END;

        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_resp_cde := '21';
        p_errmsg   := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En SSN validations
  END IF; 
  IF p_idologyid IS NOT NULL THEN

     BEGIN
      SELECT CCI_TYPE_ONE,
        CCI_TYPE_TWO,
        CCI_TYPE_THREE,
        CCI_ROW_ID,
        CCI_UPLD_STAT,CCI_TYPE_FOUR
      INTO p_security_q1,
        p_security_q2,
        p_security_q3,
        v_seq_val,
        V_CCI_UPLD_STAT,p_security_q4
      FROM CMS_CAF_INFO_ENTRY
      WHERE CCI_INST_CODE=p_inst_code
      AND CCI_IDOLOGY_ID =p_idologyid;

      IF V_CCI_UPLD_STAT <> 'P' THEN
        v_resp_cde       := '65';
        p_errmsg         := 'Invalid Data for Idology ID' ;
        RAISE exp_reject_record;
      END IF;

      IF v_seq_val IS NULL THEN
        v_resp_cde := '65';
        p_errmsg   := 'Invalid Data for Idology ID' ;
        RAISE exp_reject_record;
      END IF;

    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN NO_DATA_FOUND THEN
      v_resp_cde := '65';
      p_errmsg   := 'Invalid Data for Idology ID';
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      p_errmsg   := 'Error while checking CMS_CAF_INFO_ENTRY values'|| SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
     
      
     
    BEGIN
      sp_check_ssn_threshold (p_inst_code, p_id_number, p_prod_code,p_card_type, 'EN',v_card_dtl, v_resp_cde, p_errmsg,V_FLDOB_HASHKEY_ID );

      -- Sn Added 0n 10-01-2014 for MVHOST-822
       IF p_errmsg <> 'OK' THEN

           IF p_delivery_channel = '06' OR  p_delivery_channel  = '13' THEN --Modified for MOB-62
            V_RESP_CDE := '144';
          END IF;

          IF p_delivery_channel = '03' THEN
            V_RESP_CDE := '158';
          END IF;

     -- En Added 0n 10-01-2014 for MVHOST-822


        BEGIN

        UPDATE cms_caf_info_entry
        SET cci_ssn_flag    = 'E',
          cci_ssnfail_dtls  = v_card_dtl,-- Modified 0n 10-01-2014 for MVHOST-822
          cci_process_msg   = p_errmsg
        WHERE cci_inst_code = p_inst_code
        AND cci_row_id      = v_seq_val;

        IF SQL%ROWCOUNT     = 0 THEN

          V_RESP_CDE       := '21';
          p_errmsg         :='Updation not happen in CMS_CAF_INFO_ENTRY for cci_ssn_flag E';
          RAISE exp_reject_record;
        END IF;

        EXCEPTION
          WHEN exp_reject_record THEN        -- Added for review comment changes on 16/Aug/2013
          RAISE;
          WHEN OTHERS THEN
             V_RESP_CDE      := '21';
             p_errmsg      :='Updation not happen in CMS_CAF_INFO_ENTRY for cci_ssn_flag E' || SUBSTR(SQLERRM, 1, 100);
             RAISE exp_reject_record;

        END;
      ELSE
         BEGIN
        UPDATE cms_caf_info_entry
        SET cci_ssn_flag    = 'Y',
          cci_ssnfail_dtls  = v_card_dtl -- Modified 0n 10-01-2014 for MVHOST-822
        WHERE cci_inst_code = p_inst_code
        AND cci_row_id      = v_seq_val;
        IF SQL%ROWCOUNT     = 0 THEN
          V_RESP_CDE       := '21';
          p_errmsg         :='Updation not happen in CMS_CAF_INFO_ENTRY for cci_ssn_flag Y'||v_seq_val||':'||p_inst_code;
          RAISE exp_reject_record;
        END IF;
       EXCEPTION
         WHEN  exp_reject_record THEN-- Added for review comment changes on 16/Aug/2013
         RAISE;
         WHEN OTHERS THEN
            V_RESP_CDE      := '21';
            p_errmsg      :='Updation not happen in CMS_CAF_INFO_ENTRY for cci_ssn_flag E' || SUBSTR(SQLERRM, 1, 100);
            RAISE exp_reject_record;

       END;

      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      p_errmsg   := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    BEGIN
      UPDATE CMS_CAF_INFO_ENTRY
      SET CCI_ANSWER_ONE =P_CCI_A1,
        CCI_ANSWER_TWO   =P_CCI_A2,
        CCI_ANSWER_THREE =P_CCI_A3,
        CCI_ANSWER_FOUR=p_cci_a4
      WHERE CCI_INST_CODE=p_inst_code
      AND CCI_IDOLOGY_ID =p_idologyid
      AND CCI_ROW_ID     =v_seq_val;
      IF SQL%ROWCOUNT    = 0 THEN
        V_RESP_CDE      := '21';
        p_errmsg        :='Updation not happen in CMS_CAF_INFO_ENTRY for answers';
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      V_RESP_CDE := '21';
      p_errmsg   :='Error while updating Answer detail in CMS_CAF_INFO_ENTRY-'|| SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
  END IF; 
  p_RespRowID := v_seq_val;
  BEGIN
    SELECT CMS_ISO_RESPCDE
    INTO P_RESP_CODE
    FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE      = P_INST_CODE
    AND CMS_DELIVERY_CHANNEL = TO_NUMBER(P_DELIVERY_CHANNEL)
    AND CMS_RESPONSE_ID      = DECODE(V_RESP_CDE, '00', '1',V_RESP_CDE);
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg   := 'Problem while selecting data from response master for respose code' || V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
    V_RESP_CDE := '21';
    RAISE EXP_REJECT_RECORD;
  END;
  
EXCEPTION--Main Exception--
WHEN exp_reject_record THEN
  ROLLBACK;
  BEGIN
    SELECT CMS_ISO_RESPCDE
    INTO P_RESP_CODE
    FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE      = P_INST_CODE
    AND CMS_DELIVERY_CHANNEL = TO_NUMBER(P_DELIVERY_CHANNEL)
    AND CMS_RESPONSE_ID      = TO_NUMBER(V_RESP_CDE);
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg   := 'Problem while selecting data from response master for respose code' || V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
    V_RESP_CDE := '21';
  END;
 
WHEN OTHERS THEN
  p_errmsg := 'Main Excp-' || SUBSTR (SQLERRM, 1, 200);
END;
/
show error
