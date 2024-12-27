CREATE OR REPLACE PROCEDURE VMSCMS.SP_CREATE_CUST(PRM_INSTCODE     IN NUMBER,
                                    PRM_CUSTTYPE     IN NUMBER,
                                    PRM_CORPCODE     IN NUMBER,
                                    PRM_CUSTSTAT     IN CHAR,
                                    PRM_SALUTCODE    IN VARCHAR2,
                                    PRM_FIRSTNAME    IN VARCHAR2,
                                    PRM_MIDNAME      IN VARCHAR2,
                                    PRM_LASTNAME     IN VARCHAR2,
                                    PRM_DOB          IN DATE,
                                    PRM_GENDER       IN CHAR,
                                    PRM_MARSTAT      IN CHAR,
                                    PRM_PERMID       IN VARCHAR2,
                                    PRM_EMAIL1       IN VARCHAR2,
                                    PRM_EMAIL2       IN VARCHAR2,
                                    PRM_MOBL1        IN VARCHAR2,
                                    PRM_MOBL2        IN VARCHAR2,
                                    PRM_LUPDUSER     IN NUMBER,
                                    PRM_SSN          IN VARCHAR2,
                                    PRM_MAIDNAME     IN VARCHAR2,
                                    PRM_HOBBY        IN VARCHAR2,
                                    PRM_EMPID        IN VARCHAR2,
                                    PRM_CATG_CODE    IN VARCHAR2,
                                    PRM_CUSTID       IN NUMBER,
                                    PRM_GEN_CUSTDATA IN TYPE_CUST_REC_ARRAY,
                                    prm_prodcode      IN  VARCHAR2,   --Added for Partner ID Changes
                                    prm_cardtype       IN NUMBER,
                                    PRM_CUSTCODE     OUT NUMBER,
                                    PRM_ERRMSG       OUT VARCHAR2) AS

/**************************************************
     * Created Date                 : NA
     * Created By                   : NA
     * Purpose                      : To generate customers in master table
     * Last Modification Done by    : Sagar More
     * Last Modification Date       : 11/04/2012
     * Mofication Reason            : to keep custid same for starter to gpr issuance
     * Build Number                 : RI0005 B0004
     
    * Modified by                   : Pankaj S.
    * Modified Date                 : 18-Aug-2015    
    * Modified reason               : Partner ID Changes
    * Reviewer                      : Sarvanankumar 
    * Build Number                  :     
    
       * Modified by       :Siva kumar 
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006
       
              * Modified By      : Akhil
      * Modified Date    : 24-jan-2018
      * Purpose          : VMS-162
      * Reviewer         : Saravanakumar
      * Build Number     : VMSGPRHOST_18.1
      
      * Modified By      : UBAIDUR RAHMAN.H
      * Modified Date    : 09-JUL-2019
      * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
      * Reviewer         : Saravana Kumar.A
      * Release Number   : VMSGPRHOST_R18
 **************************************************/



  DUM                   PLS_INTEGER := 0;
  V_GRPCODE             CMS_CUST_GROUP.CCG_GROUP_CODE%TYPE;
  V_CORP                CMS_CUST_MAST.CCM_CORP_CODE%TYPE;
 
  V_SETDATA_ERRMSG      TRANSACTIONLOG.ERROR_MSG%TYPE; 
 
  V_CUSTREC_OUTDATA     TYPE_CUST_REC_ARRAY;
  V_CUST_ID             CMS_CUST_MAST.CCM_CUST_ID%TYPE; 
  v_partner_id          cms_product_param.cpp_partner_id%TYPE;  --Added for Partner ID Changes  
  v_encrypt_enable      cms_prod_cattype.cpc_encrypt_enable%type;
  v_first_name          cms_cust_mast.ccm_first_name%type;
  v_last_name           cms_cust_mast.ccm_last_name%type;
  v_mid_name            cms_cust_mast.ccm_mid_name%type;
  v_mother_name         cms_cust_mast.ccm_mother_name%type;
BEGIN
  --Main Begin Block Starts Here
  PRM_ERRMSG := 'OK';
  IF PRM_CORPCODE = 0 THEN
    V_CORP := NULL;
  ELSE
    V_CORP := PRM_CORPCODE;
  END IF;
  BEGIN
    --Begin 1 Starts Here
    SELECT 1
     INTO DUM
     FROM CMS_INST_MAST
    WHERE CIM_INST_CODE = PRM_INSTCODE;
  EXCEPTION
    --Begin 1 Exception
    WHEN NO_DATA_FOUND THEN
     PRM_ERRMSG := 'No such Institution ' || PRM_INSTCODE ||
                ' exists in Institution master ';
     RETURN;
    WHEN OTHERS THEN
     PRM_ERRMSG := 'Exception 1 ' || SQLCODE || '---' || SQLERRM;
     RETURN;
  END; --Begin 1 Ends Here+
  IF DUM = 1 THEN
    --if 1
    BEGIN
      
     BEGIN
       SELECT SEQ_CUSTCODE.NEXTVAL INTO PRM_CUSTCODE FROM DUAL;
     EXCEPTION
       WHEN OTHERS THEN
        PRM_ERRMSG := 'Error while selecting the value from sequence ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RETURN;
     END;
  

     BEGIN
       SELECT MIN(CCG_GROUP_CODE)
        INTO V_GRPCODE
        FROM CMS_CUST_GROUP
        WHERE CCG_INST_CODE = PRM_INSTCODE;

       IF V_GRPCODE IS NULL THEN
        V_GRPCODE := 1;
        BEGIN
          INSERT INTO CMS_CUST_GROUP
            (CCG_INST_CODE,
            CCG_GROUP_CODE,
            CCG_GROUP_DESC,
            CCG_INS_USER,
            CCG_INS_DATE,
            CCG_LUPD_USER,
            CCG_LUPD_DATE)
          VALUES
            (PRM_INSTCODE,
            V_GRPCODE,
            'DEFAULT GROUP',
            PRM_LUPDUSER,
            SYSDATE,
            PRM_LUPDUSER,
            SYSDATE);
        EXCEPTION
          WHEN OTHERS THEN
            PRM_ERRMSG := 'Error while inserting data for customer group ' ||
                       SUBSTR(SQLERRM, 1, 200);
            RETURN;
        END;
       END IF;

     EXCEPTION
       WHEN OTHERS THEN
        PRM_ERRMSG := 'Error while fetching group code ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RETURN;
     END;

     IF PRM_CATG_CODE = 'P' and PRM_CUSTID is not null
     THEN

        V_CUST_ID := PRM_CUSTID;

     elsif PRM_CATG_CODE = 'P' and PRM_CUSTID is null
     then

         BEGIN -- Sn; Added by sagar on 02-apr-2012 for customer id generation requirement

           SELECT SEQ_CUST_ID.NEXTVAL INTO V_CUST_ID FROM DUAL;
         EXCEPTION
           WHEN OTHERS THEN
            PRM_ERRMSG := 'Error while selecting the value for customer id ' ||
                        SUBSTR(SQLERRM, 1, 200);
            RETURN;

         END; -- Sn; Added by sagar on 02-apr-2012 for customer id generation requirement

       -- IF PREPAID THEN
       --V_CUST_ID := PRM_CUSTCODE; -- Commneted by sagar on 02-apr-2012 for customer id generation requirement
     END IF;

     IF PRM_CATG_CODE IN ('D', 'A') THEN
       -- IF DEBIT THEN
       V_CUST_ID := PRM_CUSTID;
     END IF;
     --Sn set the generic variable
     SP_SET_GEN_CUSTDATA(PRM_INSTCODE,
                     PRM_GEN_CUSTDATA,
                     V_CUSTREC_OUTDATA,
                     V_SETDATA_ERRMSG);
     IF V_SETDATA_ERRMSG <> 'OK' THEN
       PRM_ERRMSG := 'Error in set gen parameters   ' || V_SETDATA_ERRMSG;
       RETURN;
     END IF;
     --En set the generic variable
     --Sn Added for Partner ID Changes
     BEGIN
        SELECT cpp_partner_id
          INTO v_partner_id
          FROM cms_product_param
         WHERE cpp_prod_code = prm_prodcode AND cpp_inst_code = prm_instcode;
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           prm_errmsg :='Product code '|| prm_prodcode || ' is not defined in the product param master';
           return;
        WHEN OTHERS THEN
           prm_errmsg :='Error while selecting partner dtls- ' || SUBSTR (SQLERRM, 1, 200);
           return;
     END;
     --En Added for Partner ID Changes     
    BEGIN
        SELECT cpc_encrypt_enable
          INTO v_encrypt_enable
          FROM cms_prod_cattype
         WHERE cpc_inst_code=PRM_INSTCODE
         and cpc_prod_code=prm_prodcode
         and cpc_card_type=prm_cardtype;
     EXCEPTION
        WHEN OTHERS THEN
           prm_errmsg :='Error while selecting from prod cattype ' || SUBSTR (SQLERRM, 1, 200);
           return;
     END;
        
     if v_encrypt_enable='Y' then
         v_first_name:=fn_emaps_main(UPPER(PRM_FIRSTNAME));
         v_mid_name:=fn_emaps_main(UPPER(PRM_MIDNAME));
         v_last_name:=fn_emaps_main(UPPER(PRM_LASTNAME));
         v_mother_name := fn_emaps_main(PRM_MAIDNAME);
     else
          v_first_name:=UPPER(PRM_FIRSTNAME);
         v_mid_name:=UPPER(PRM_MIDNAME);
         v_last_name:=UPPER(PRM_LASTNAME);
         v_mother_name := PRM_MAIDNAME;
    end if;
     BEGIN
       INSERT INTO CMS_CUST_MAST
        (CCM_INST_CODE,
         CCM_CUST_CODE,
         CCM_GROUP_CODE,
         CCM_CUST_TYPE,
         CCM_CORP_CODE,
         CCM_CUST_STAT,
         CCM_SALUT_CODE,
         CCM_FIRST_NAME,
         CCM_MID_NAME,
         CCM_LAST_NAME,
         CCM_BIRTH_DATE,
         CCM_PERM_ID,
         CCM_EMAIL_ONE,
         CCM_EMAIL_TWO,
         CCM_MOBL_ONE,
         CCM_MOBL_TWO,
         CCM_INS_USER,
         CCM_LUPD_USER,
         CCM_GENDER_TYPE,
         CCM_MARITAL_STAT,
         CCM_SSN,
         CCM_MOTHER_NAME,
         CCM_HOBBIES,
         CCM_CUST_ID,
         CCM_EMP_ID,
         CCM_CUST_PARAM1,
         CCM_CUST_PARAM2,
         CCM_CUST_PARAM3,
         CCM_CUST_PARAM4,
         CCM_CUST_PARAM5,
         CCM_CUST_PARAM6,
         CCM_CUST_PARAM7,
         CCM_CUST_PARAM8,
         CCM_CUST_PARAM9,
         CCM_CUST_PARAM10,
         ccm_partner_id,  --Added for Partner ID Changes
         ccm_ssn_encr,
         ccm_prod_code,
         ccm_card_type,
         CCM_FIRST_NAME_ENCR,
         CCM_LAST_NAME_ENCR
         )
       VALUES
        (PRM_INSTCODE,
         PRM_CUSTCODE,
         V_GRPCODE,
         PRM_CUSTTYPE,
         V_CORP,
         PRM_CUSTSTAT,
         PRM_SALUTCODE,
         v_first_name,
         v_mid_name,
         v_last_name,
         PRM_DOB,
         PRM_PERMID,
         PRM_EMAIL1,
         PRM_EMAIL2,
         PRM_MOBL1,
         PRM_MOBL2,
         PRM_LUPDUSER,
         PRM_LUPDUSER,
         PRM_GENDER,
         PRM_MARSTAT,
         fn_maskacct_ssn(prm_instcode,PRM_SSN,0),
         v_mother_name,
         PRM_HOBBY,
         V_CUST_ID,
         PRM_EMPID,
         V_CUSTREC_OUTDATA(1),
         V_CUSTREC_OUTDATA(2),
         V_CUSTREC_OUTDATA(3),
         V_CUSTREC_OUTDATA(4),
         V_CUSTREC_OUTDATA(5),
         V_CUSTREC_OUTDATA(6),
         V_CUSTREC_OUTDATA(7),
         V_CUSTREC_OUTDATA(8),
         V_CUSTREC_OUTDATA(9),
         V_CUSTREC_OUTDATA(10),
         v_partner_id, --Added for Partner ID Changes
         fn_emaps_main(prm_ssn),
         prm_prodcode,
         prm_cardtype,
         fn_emaps_main(UPPER(PRM_FIRSTNAME)),
         fn_emaps_main(UPPER(PRM_LASTNAME))
         );
     EXCEPTION
       WHEN DUP_VAL_ON_INDEX THEN
        PRM_ERRMSG := 'Error while creating customer data in master duplicate record found ';
        RETURN;
       WHEN OTHERS THEN
        PRM_ERRMSG := 'Error while creating customer data in master' ||
                    SUBSTR(SQLERRM, 1, 150);
        RETURN;
     END;
     
    END;  
  END IF; --if 1
 
EXCEPTION
  --Main block Exception
  WHEN OTHERS THEN
    PRM_ERRMSG := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
END;
/
show error