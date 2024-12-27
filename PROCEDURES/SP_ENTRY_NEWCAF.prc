CREATE OR REPLACE PROCEDURE VMSCMS.SP_ENTRY_NEWCAF(PRM_INSTCODE IN NUMBER,
								    PRM_LUPDUSER IN NUMBER,
								    PRM_ERRMSG   OUT VARCHAR2) IS
  V_CUSTCATG_CODE      CMS_CUST_CATG.CCC_CATG_CODE%TYPE;
  V_CUST_CODE          CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
  V_GCM_CNTRY_CODE     GEN_CNTRY_MAST.GCM_CNTRY_CODE%TYPE;
  V_COMM_ADDR_LIN1     CMS_CAF_INFO_ENTRY.CCI_SEG12_ADDR_LINE1%TYPE;
  V_COMM_ADDR_LIN2     CMS_CAF_INFO_ENTRY.CCI_SEG12_ADDR_LINE2%TYPE;
  V_COMM_POSTAL_CODE   CMS_CAF_INFO_ENTRY.CCI_SEG12_POSTAL_CODE%TYPE;
  V_COMM_HOMEPHONE_NO  CMS_CAF_INFO_ENTRY.CCI_SEG12_HOMEPHONE_NO%TYPE;
  V_COMM_MOBILENO      CMS_CAF_INFO_ENTRY.CCI_SEG12_MOBILENO%TYPE;
  V_COMM_EMAILID       CMS_CAF_INFO_ENTRY.CCI_SEG12_EMAILID%TYPE;
  V_COMM_CNTRYCODE     CMS_CAF_INFO_ENTRY.CCI_SEG12_COUNTRY_CODE%TYPE;
  V_COMM_CITY          CMS_CAF_INFO_ENTRY.CCI_SEG12_CITY%TYPE;
  V_COMM_STATE         CMS_CAF_INFO_ENTRY.CCI_SEG12_STATE%TYPE;
  V_OTHER_ADDR_LIN1    CMS_CAF_INFO_ENTRY.CCI_SEG13_ADDR_LINE1%TYPE;
  V_OTHER_ADDR_LIN2    CMS_CAF_INFO_ENTRY.CCI_SEG13_ADDR_LINE2%TYPE;
  V_OTHER_POSTAL_CODE  CMS_CAF_INFO_ENTRY.CCI_SEG13_POSTAL_CODE%TYPE;
  V_OTHER_HOMEPHONE_NO CMS_CAF_INFO_ENTRY.CCI_SEG13_HOMEPHONE_NO%TYPE;
  V_OTHER_MOBILENO     CMS_CAF_INFO_ENTRY.CCI_SEG13_MOBILENO%TYPE;
  V_OTHER_EMAILID      CMS_CAF_INFO_ENTRY.CCI_SEG13_EMAILID%TYPE;
  V_OTHER_CNTRYCODE    CMS_CAF_INFO_ENTRY.CCI_SEG12_COUNTRY_CODE%TYPE;
  V_OTHER_CITY         CMS_CAF_INFO_ENTRY.CCI_SEG13_CITY%TYPE;
  V_OTHER_STATE        CMS_CAF_INFO_ENTRY.CCI_SEG12_STATE%TYPE;
  V_COMM_ADDRCODE      CMS_ADDR_MAST.CAM_ADDR_CODE%TYPE;
  V_OTHER_ADDRCODE     CMS_ADDR_MAST.CAM_ADDR_CODE%TYPE;
  V_ACCT_TYPE          CMS_ACCT_TYPE.CAT_TYPE_CODE%TYPE;
  V_ACCT_STAT          CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
  V_ACCT_NUMB          CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
  V_ACCT_ID            CMS_ACCT_MAST.CAM_ACCT_ID%TYPE;
  V_DUP_FLAG           VARCHAR2(1);
  V_PROD_CODE          CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CCC           CMS_PROD_CCC.CPC_PROD_SNAME%TYPE;
  V_CUSTCATG           CMS_CUST_CATG.CCC_CATG_SNAME%TYPE;
  V_APPL_CODE          CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
  V_ERRMSG             VARCHAR2(300);
  V_SAVEPOINT          NUMBER DEFAULT 1;
  V_GENDER             VARCHAR2(1);
  V_EXPRYPARAM         CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_HOLDPOSN           CMS_CUST_ACCT.CCA_HOLD_POSN%TYPE;
  --v_brancheck             NUMBER (1);
  V_FUNC_CODE           CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_SPPRT_FUNCCODE      CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_FUNC_DESC           CMS_FUNC_MAST.CFM_FUNC_DESC%TYPE;
  V_SPPRTFUNC_DESC      CMS_FUNC_MAST.CFM_FUNC_DESC%TYPE;
  V_CATG_CODE           CMS_PROD_MAST.CPM_CATG_CODE%TYPE;
  V_CHECK_FUNCCODE      NUMBER(1);
  V_CHECK_SPPRTFUNCCODE NUMBER(1);
  V_INITIAL_SPPRTFLAG   VARCHAR2(1);
  V_KYC_FLAG            VARCHAR2(1);
  V_INSTRUMENT_REALISED VARCHAR2(1);
  V_COMM_TYPE           CHAR(1);
  V_CUST_DATA           TYPE_CUST_REC_ARRAY;
  V_ADDR_DATA1          TYPE_ADDR_REC_ARRAY;
  V_ADDR_DATA2          TYPE_ADDR_REC_ARRAY;
  V_APPL_DATA           TYPE_APPL_REC_ARRAY;
  V_SEG31ACCTNUM_DATA   TYPE_ACCT_REC_ARRAY;
  V_CHECK_BRANCH        NUMBER(1);
  V_CHECK_BIN_STAT      CMS_BIN_MAST.CBM_BIN_STAT%TYPE;
  V_PRODCODE            CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_CHECK_PRODUCT       NUMBER(1);
  V_CARD_TYPE           CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_GCM_OTHERCNTRY_CODE GEN_CNTRY_MAST.GCM_CNTRY_CODE%TYPE;
  EXP_REJECT_RECORD EXCEPTION;
  EXP_PROCESS_RECORD EXCEPTION;
  V_COMM_OFFICENO  CMS_CAF_INFO_ENTRY.CCI_SEG12_OFFICEPHONE_NO%TYPE;
  V_OTHER_OFFICENO CMS_CAF_INFO_ENTRY.CCI_SEG13_OFFICEPHONE_NO%TYPE;
  V_CNT            NUMBER(10);
  CURSOR C IS
    SELECT CCI_INST_CODE,
		 CCI_FILE_NAME,
		 CCI_ROW_ID,
		 CCI_APPL_CODE,
		 CCI_APPL_NO,
		 CCI_PAN_CODE,
		 CCI_MBR_NUMB,
		 CCI_CRD_STAT,
		 CCI_EXP_DAT,
		 CCI_REC_TYP,
		 CCI_CRD_TYP,
		 CCI_REQUESTER_NAME,
		 CCI_PROD_CODE,
		 CCI_CARD_TYPE,
		 CCI_SEG12_BRANCH_NUM,
		 CCI_FIID,
		 CCI_TITLE,
		 CCI_SEG12_NAME_LINE1,
		 CCI_SEG12_NAME_LINE2,
		 CCI_BIRTH_DATE,
		 CCI_MOTHERS_MAIDEN_NAME,
		 CCI_SSN,
		 CCI_HOBBIES,
		 CCI_CUST_ID,
		 CCI_COMM_TYPE,
		 CCI_SEG12_ADDR_LINE1,
		 CCI_SEG12_ADDR_LINE2,
		 CCI_SEG12_CITY,
		 CCI_SEG12_STATE,
		 CCI_SEG12_POSTAL_CODE,
		 CCI_SEG12_COUNTRY_CODE,
		 CCI_SEG12_MOBILENO,
		 CCI_SEG12_HOMEPHONE_NO,
		 CCI_SEG12_OFFICEPHONE_NO,
		 CCI_SEG12_EMAILID,
		 CCI_SEG13_ADDR_LINE1,
		 CCI_SEG13_ADDR_LINE2,
		 CCI_SEG13_CITY,
		 CCI_SEG13_STATE,
		 CCI_SEG13_POSTAL_CODE,
		 CCI_SEG13_COUNTRY_CODE,
		 CCI_SEG13_MOBILENO,
		 CCI_SEG13_HOMEPHONE_NO,
		 CCI_SEG13_OFFICEPHONE_NO,
		 CCI_SEG13_EMAILID,
		 CCI_SEG31_LGTH,
		 CCI_SEG31_ACCT_CNT,
		 CCI_SEG31_TYP,
		 CCI_SEG31_NUM,
		 CCI_SEG31_STAT,
		 CCI_PROD_AMT,
		 CCI_FEE_AMT,
		 CCI_TOT_AMT,
		 CCI_PAYMENT_MODE,
		 CCI_INSTRUMENT_NO,
		 CCI_INSTRUMENT_AMT,
		 CCI_DRAWN_DATE,
		 CCI_PAYREF_NO,
		 CCI_EMP_ID,
		 CCI_KYC_REASON,
		 CCI_KYC_FLAG,
		 CCI_ADDON_FLAG,
		 CCI_VIRTUAL_ACCT,
		 CCI_DOCUMENT_VERIFY,
		 CCI_EXCHANGE_RATE,
		 CCI_UPLD_STAT,
		 CCI_APPROVED,
		 CCI_MAKER_USER_ID,
		 CCI_MAKER_DATE,
		 CCI_CHECKER_USER_ID,
		 CCI_CHEKER_DATE,
		 CCI_AUTH_USER_ID,
		 CCI_AUTH_DATE,
		 CCI_INS_USER,
		 CCI_INS_DATE,
		 CCI_LUPD_USER,
		 CCI_LUPD_DATE,
		 CCI_COMMENTS,
		 CCI_CUST_CATG,
		 --Sn Customer generic data
		 CCI_CUSTOMER_PARAM1,
		 CCI_CUSTOMER_PARAM2,
		 CCI_CUSTOMER_PARAM3,
		 CCI_CUSTOMER_PARAM4,
		 CCI_CUSTOMER_PARAM5,
		 CCI_CUSTOMER_PARAM6,
		 CCI_CUSTOMER_PARAM7,
		 CCI_CUSTOMER_PARAM8,
		 CCI_CUSTOMER_PARAM9,
		 CCI_CUSTOMER_PARAM10,

		 --En customer generic data
		 --Sn select addrss seg12 detail
		 CCI_SEG12_ADDR_PARAM1,
		 CCI_SEG12_ADDR_PARAM2,
		 CCI_SEG12_ADDR_PARAM3,
		 CCI_SEG12_ADDR_PARAM4,
		 CCI_SEG12_ADDR_PARAM5,
		 CCI_SEG12_ADDR_PARAM6,
		 CCI_SEG12_ADDR_PARAM7,
		 CCI_SEG12_ADDR_PARAM8,
		 CCI_SEG12_ADDR_PARAM9,
		 CCI_SEG12_ADDR_PARAM10,

		 --En select ddrss seg12 detail
		 --Sn select addrss seg12 detail
		 CCI_SEG13_ADDR_PARAM1,
		 CCI_SEG13_ADDR_PARAM2,
		 CCI_SEG13_ADDR_PARAM3,
		 CCI_SEG13_ADDR_PARAM4,
		 CCI_SEG13_ADDR_PARAM5,
		 CCI_SEG13_ADDR_PARAM6,
		 CCI_SEG13_ADDR_PARAM7,
		 CCI_SEG13_ADDR_PARAM8,
		 CCI_SEG13_ADDR_PARAM9,
		 CCI_SEG13_ADDR_PARAM10,

		 --Sn select acct data
		 CCI_SEG31_NUM_PARAM1,
		 CCI_SEG31_NUM_PARAM2,
		 CCI_SEG31_NUM_PARAM3,
		 CCI_SEG31_NUM_PARAM4,
		 CCI_SEG31_NUM_PARAM5,
		 CCI_SEG31_NUM_PARAM6,
		 CCI_SEG31_NUM_PARAM7,
		 CCI_SEG31_NUM_PARAM8,
		 CCI_SEG31_NUM_PARAM9,
		 CCI_SEG31_NUM_PARAM10,

		 --Sn select appl data
		 CCI_CUSTAPPL_PARAM1,
		 CCI_CUSTAPPL_PARAM2,
		 CCI_CUSTAPPL_PARAM3,
		 CCI_CUSTAPPL_PARAM4,
		 CCI_CUSTAPPL_PARAM5,
		 CCI_CUSTAPPL_PARAM6,
		 CCI_CUSTAPPL_PARAM7,
		 CCI_CUSTAPPL_PARAM8,
		 CCI_CUSTAPPL_PARAM9,
		 CCI_CUSTAPPL_PARAM10,
		 ROWID R
	 FROM CMS_CAF_INFO_ENTRY
	WHERE CCI_APPROVED = 'A' AND CCI_INST_CODE = PRM_INSTCODE AND
		 CCI_UPLD_STAT = 'P';
BEGIN
  --<< MAIN BEGIN >>
  --SN  Loop for record pending for processing
  V_CUST_DATA         := TYPE_CUST_REC_ARRAY();
  V_ADDR_DATA1        := TYPE_ADDR_REC_ARRAY();
  V_ADDR_DATA2        := TYPE_ADDR_REC_ARRAY();
  V_APPL_DATA         := TYPE_APPL_REC_ARRAY();
  V_SEG31ACCTNUM_DATA := TYPE_ACCT_REC_ARRAY();
  PRM_ERRMSG          := 'OK';

  DELETE FROM PCMS_UPLOAD_LOG;

  FOR I IN C LOOP
    --Initialize the common loop variable
    V_ERRMSG := 'OK';
    V_CUST_DATA.DELETE;
    V_ADDR_DATA1.DELETE;
    V_ADDR_DATA2.DELETE;
    V_SEG31ACCTNUM_DATA.DELETE;
    V_APPL_DATA.DELETE;
    V_SAVEPOINT := V_SAVEPOINT + 1;
    SAVEPOINT V_SAVEPOINT;

    BEGIN
	 --Loop begin I
	 --Sn check branch
	 BEGIN
	   SELECT 1
		INTO V_CHECK_BRANCH
		FROM CMS_BRAN_MAST
	    WHERE CBM_BRAN_CODE = I.CCI_FIID AND CBM_INST_CODE = PRM_INSTCODE;
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		V_ERRMSG := 'Branch is not defined in master';
		RAISE EXP_REJECT_RECORD;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting branch detail' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En check brach
	 --Sn Check Sale condition
	 BEGIN
	   SELECT 1
		INTO V_CHECK_BRANCH
		FROM CMS_BRAN_MAST
	    WHERE CBM_BRAN_CODE = I.CCI_FIID AND CBM_SALE_TRANS = 1 AND
			CBM_INST_CODE = PRM_INSTCODE;
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		V_ERRMSG := 'Branch is not allowed for new card issuance ';
		RAISE EXP_REJECT_RECORD;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting branch status' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En Check Sale condition
	 --Sn check cntry mast
	 --                BEGIN
	 --                     SELECT gcm_cntry_code
	 --                     INTO v_gcm_cntry_code
	 --                     FROM gen_cntry_mast
	 --                    WHERE gcm_curr_code = i.cci_seg12_country_code
	 --                AND   gcm_inst_code = prm_instcode;
	 --                EXCEPTION
	 --                   WHEN NO_DATA_FOUND
	 --                   THEN
	 --                      v_errmsg :=
	 --                            'Country is not defined in master'
	 --                         || i.cci_seg12_country_code;
	 --                      RAISE exp_reject_record;
	 --                   WHEN OTHERS
	 --                   THEN
	 --                      v_errmsg :=
	 --                            'Error while selecting country detail'
	 --                         || SUBSTR (SQLERRM, 1, 200);
	 --                      RAISE exp_reject_record;
	 --                END;
	 --                --En check cntry mast
	 --Sn check cust catg
	 BEGIN
	   SELECT CCC_CATG_CODE, CCC_CATG_SNAME
		INTO V_CUSTCATG_CODE, V_CUSTCATG
		FROM CMS_CUST_CATG
	    WHERE CCC_CATG_SNAME = I.CCI_CUST_CATG AND
			CCC_INST_CODE = PRM_INSTCODE;
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		V_ERRMSG := ' Customer category ' || I.CCI_CUST_CATG ||
				  ' is not present in master';
		RAISE EXP_REJECT_RECORD;
		-- v_custcatg := 'DEF';
	   --Master setup need to be done for 'DEF'
	   --  v_custcatg_code := 1;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting customer category' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En check cust catg
	 --Sn check bin status
	 BEGIN
	   SELECT CBM_BIN_STAT
		INTO V_CHECK_BIN_STAT
		FROM CMS_BIN_MAST
	    WHERE CBM_INST_BIN = I.CCI_PAN_CODE AND
			CBM_INST_CODE = PRM_INSTCODE;

	   IF V_CHECK_BIN_STAT <> '1' THEN
		V_ERRMSG := 'Not a active Bin ' || I.CCI_PAN_CODE;
		RAISE EXP_REJECT_RECORD;
	   END IF;
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		V_ERRMSG := 'Bin ' || I.CCI_PAN_CODE || ' not found in master ';
		RAISE EXP_REJECT_RECORD;
	   WHEN EXP_REJECT_RECORD THEN
		RAISE;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting bin details from master ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En check bin status

	 --Sn check prod bin
	 BEGIN
	   SELECT CPB_PROD_CODE
		INTO V_PRODCODE
		FROM CMS_PROD_BIN
	    WHERE CPB_INST_CODE = PRM_INSTCODE AND
			CPB_INST_BIN = I.CCI_PAN_CODE AND
			CPB_MARC_PRODBIN_FLAG = 'N' AND CPB_ACTIVE_BIN = 'Y';
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		V_ERRMSG := 'Not a valid Bin ' || I.CCI_PAN_CODE;
		RAISE EXP_REJECT_RECORD;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting product and bin dtl ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En check prod bin
	 --Sn check product
	 BEGIN
	   SELECT 1
		INTO V_CHECK_PRODUCT
		FROM CMS_PROD_MAST
	    WHERE CPM_INST_CODE = PRM_INSTCODE AND CPM_PROD_CODE = V_PRODCODE AND
			CPM_MARC_PROD_FLAG = 'N';
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		V_ERRMSG := 'Not a valid Product ' || V_PRODCODE;
		RAISE EXP_REJECT_RECORD;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting product ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En check product
	 --Sn check card type
	 BEGIN
	   SELECT CPC_CARD_TYPE
		INTO V_CARD_TYPE
		FROM CMS_PROD_CATTYPE
	    WHERE CPC_INST_CODE = PRM_INSTCODE AND CPC_PROD_CODE = V_PRODCODE AND
			CPC_CARD_TYPE = I.CCI_CARD_TYPE;
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		V_ERRMSG := 'Product code' || V_PRODCODE ||
				  'is not attached to cattype' || I.CCI_CARD_TYPE;
		RAISE EXP_REJECT_RECORD;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting product cattype ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En check card type
	 -- Sn find entry in prod ccc
	 BEGIN
	   SELECT CPC_PROD_SNAME
		INTO V_PROD_CCC
		FROM CMS_PROD_CCC
	    WHERE CPC_INST_CODE = PRM_INSTCODE AND CPC_PROD_CODE = V_PRODCODE AND
			CPC_CARD_TYPE = V_CARD_TYPE AND
			CPC_CUST_CATG = V_CUSTCATG_CODE;
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		BEGIN
		  /*  INSERT INTO cms_prod_ccc
                   (cpc_inst_code, cpc_cust_catg,
                    cpc_card_type, cpc_prod_code,
                    cpc_ins_user, cpc_ins_date,
                    cpc_lupd_user, cpc_lupd_date,
                    cpc_vendor, cpc_stock, cpc_prod_sname
                   )
            VALUES (prm_instcode, v_custcatg_code,
                    v_card_type, v_prodcode,
                    prm_lupduser, SYSDATE,
                    prm_lupduser, SYSDATE,
                    '1', '1', 'Default'
                   );*/
		  V_ERRMSG := ' Customer category ' || I.CCI_CUST_CATG ||
				    ' is not attached to product';
		  RAISE EXP_REJECT_RECORD;
		EXCEPTION
		  WHEN OTHERS THEN
		    V_ERRMSG := 'Error while creating a entry in prod_ccc';
		    RAISE EXP_REJECT_RECORD;
		END;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting prodccc detail from master ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --Sn check product catg code
	 BEGIN
	   SELECT CPM_CATG_CODE
		INTO V_CATG_CODE
		FROM CMS_PROD_MAST
	    WHERE CPM_INST_CODE = PRM_INSTCODE AND CPM_PROD_CODE = V_PRODCODE AND
			CPM_MARC_PROD_FLAG = 'N';
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		V_ERRMSG := 'Not a valid Product ' || V_PRODCODE;
		RAISE EXP_REJECT_RECORD;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting product ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En check product catg code
	 IF V_CATG_CODE = 'P' --Prod catg
	  THEN
	   --Sn KYC Flage approvel check
	   BEGIN
		SELECT CCI_KYC_FLAG
		  INTO V_KYC_FLAG
		  FROM CMS_CAF_INFO_ENTRY
		 WHERE CCI_PAN_CODE = I.CCI_PAN_CODE AND
			  CCI_INST_CODE = PRM_INSTCODE AND ROWID = I.R AND
			  CCI_KYC_FLAG = 'N';
	   EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  V_ERRMSG := 'KYC is pending for Approval';
		  RAISE EXP_PROCESS_RECORD;
		WHEN OTHERS THEN
		  V_ERRMSG := 'Error while selecting KYC Flag' ||
				    SUBSTR(SQLERRM, 1, 200);
		  RAISE EXP_PROCESS_RECORD;
	   END;

	   --En KYC Flage approvel check

	   -- Sn Check instrument_realised first is Y or not
	   BEGIN
		SELECT CCI_INSTRUMENT_REALISED
		  INTO V_INSTRUMENT_REALISED
		  FROM CMS_CAF_INFO_ENTRY
		 WHERE CCI_INST_CODE = PRM_INSTCODE AND ROWID = I.R AND
			  CCI_INSTRUMENT_REALISED = 'Y';
	   EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  V_ERRMSG := 'Instrument Realised is pending for approval ';
		  RAISE EXP_PROCESS_RECORD;
		WHEN OTHERS THEN
		  V_ERRMSG := 'Error while selecting Instrument Realised ' ||
				    SUBSTR(SQLERRM, 1, 200);
		  RAISE EXP_PROCESS_RECORD;
	   END;

	   --En Check instrument realised first is Y or not

	   -----------------Sn check card issuance
	   BEGIN
		SELECT CFM_FUNC_CODE, CFM_FUNC_DESC
		  INTO V_FUNC_CODE, V_FUNC_DESC
		  FROM CMS_FUNC_MAST
		 WHERE CFM_TXN_CODE = 'CI' AND CFM_TXN_MODE = '0' AND
			  CFM_DELIVERY_CHANNEL = '05' AND
			  CFM_INST_CODE = PRM_INSTCODE;
	   EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  V_ERRMSG := 'Master data is not available for card issuance';
		  RAISE EXP_REJECT_RECORD;
		WHEN OTHERS THEN
		  V_ERRMSG := 'Error while selecting funccode detail from master ' ||
				    SUBSTR(SQLERRM, 1, 200);
		  RAISE EXP_REJECT_RECORD;
	   END;

	   BEGIN
		SELECT 1
		  INTO V_CHECK_FUNCCODE
		  FROM CMS_FUNC_PROD
		 WHERE CFP_PROD_CODE = V_PRODCODE AND
			  CFP_PROD_CATTYPE = V_CARD_TYPE AND
			  CFP_FUNC_CODE = V_FUNC_CODE AND
			  CFP_INST_CODE = PRM_INSTCODE;
	   EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  V_ERRMSG := V_FUNC_DESC || ' is not attached to product code ' ||
				    V_PRODCODE || ' card type ' || I.CCI_CARD_TYPE;
		  RAISE EXP_REJECT_RECORD;
		WHEN OTHERS THEN
		  V_ERRMSG := 'Error while verifing  funccode attachment to Product code and card type ' ||
				    SUBSTR(SQLERRM, 1, 200);
		  RAISE EXP_REJECT_RECORD;
	   END;

	   --En check card issuance
	   --Sn check initial load
	   IF I.CCI_PROD_AMT > 0 THEN
		--Sn check initial load spprt func
		BEGIN
		  SELECT CFM_FUNC_CODE, CFM_FUNC_DESC
		    INTO V_SPPRT_FUNCCODE, V_SPPRTFUNC_DESC
		    FROM CMS_FUNC_MAST
		   WHERE CFM_TXN_CODE = 'IL' AND CFM_TXN_MODE = '0' AND
			    CFM_DELIVERY_CHANNEL = '05' AND
			    CFM_INST_CODE = PRM_INSTCODE;
		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
		    V_ERRMSG := 'Master data is not available for initial load';
		    RAISE EXP_REJECT_RECORD;
		  WHEN OTHERS THEN
		    V_ERRMSG := 'Error while selecting funccode detail from master for initial load ' ||
					 SUBSTR(SQLERRM, 1, 200);
		    RAISE EXP_REJECT_RECORD;
		END;

		--En check initial load spprt function
		--Sn Check card initial load attached to product and Cardtype
		BEGIN
		  SELECT 1
		    INTO V_CHECK_SPPRTFUNCCODE
		    FROM CMS_FUNC_PROD
		   WHERE CFP_PROD_CODE = V_PRODCODE AND
			    CFP_PROD_CATTYPE = V_CARD_TYPE AND
			    CFP_FUNC_CODE = V_SPPRT_FUNCCODE AND
			    CFP_INST_CODE = PRM_INSTCODE;

		  V_INITIAL_SPPRTFLAG := 'Y';
		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
		    V_ERRMSG := V_SPPRTFUNC_DESC ||
					 ' is not attached to product code ' || V_PRODCODE ||
					 ' card type ' || I.CCI_CARD_TYPE;
		    RAISE EXP_REJECT_RECORD;
		  WHEN OTHERS THEN
		    V_ERRMSG := 'Error while verifing  funccode attachment to Product code and card type for initial load' ||
					 SUBSTR(SQLERRM, 1, 200);
		    RAISE EXP_REJECT_RECORD;
		END;
		--En Check card initial load attached to product and Cardtype
	   END IF; -- end if prod catg
	 END IF;

	 --Sn find customer
	 BEGIN
	   SELECT CCM_CUST_CODE
		INTO V_CUST_CODE
		FROM CMS_CUST_MAST
	    WHERE CCM_INST_CODE = PRM_INSTCODE
		    ---AND ccm_cust_code = i2.cci_cust_id;
			AND CCM_CUST_ID = I.CCI_CUST_ID;
	   --As per Discussion With Shyam.
	   /*IF SQL%FOUND
        THEN
           v_errmsg := 'Custome Code is already present in master ';
           RAISE exp_reject_record;
        END IF;*/
	   /*  BEGIN
         SELECT CAM_ADDR_CODE INTO v_comm_addrcode FROM CMS_ADDR_MAST
          WHERE CAM_INST_CODE =prm_instcode
          AND CAM_CUST_CODE =v_cust_code
          AND CAM_ADDR_FLAG = 'P';
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
          v_errmsg :=
                     'No Data found while selecting Addr code '
                  || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
         WHEN TOO_MANY_ROWS THEN
          v_errmsg :=
                     'Multiplal Rows found while selecting Addr code '
                  || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
         WHEN OTHERS THEN
          v_errmsg :=
                     'Error while selecting Addr code  '
                  || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
        END;
        */
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		--Sn create customer
		BEGIN
		  SELECT DECODE(UPPER(I.CCI_TITLE),
					 'MR.',
					 'M',
					 'MRS.',
					 'F',
					 'MISS.',
					 'F')
		    INTO V_GENDER
		    FROM DUAL;

		  --Sn assign records to customer gen variable
		  BEGIN
		    SELECT TYPE_CUST_REC_ARRAY(I.CCI_CUSTOMER_PARAM1,
								 I.CCI_CUSTOMER_PARAM2,
								 I.CCI_CUSTOMER_PARAM3,
								 I.CCI_CUSTOMER_PARAM4,
								 I.CCI_CUSTOMER_PARAM5,
								 I.CCI_CUSTOMER_PARAM6,
								 I.CCI_CUSTOMER_PARAM7,
								 I.CCI_CUSTOMER_PARAM8,
								 I.CCI_CUSTOMER_PARAM9,
								 I.CCI_CUSTOMER_PARAM10)
			 INTO V_CUST_DATA
			 FROM DUAL;
		  EXCEPTION
		    WHEN OTHERS THEN
			 V_ERRMSG := 'Error while cutomer gen data ' ||
					   SUBSTR(SQLERRM, 1, 200);
			 RAISE EXP_REJECT_RECORD;
		  END;

		  --En assign records to customer gen variable
		  SP_CREATE_CUST(PRM_INSTCODE,
					  1,
					  0,
					  'Y',
					  I.CCI_TITLE,
					  I.CCI_SEG12_NAME_LINE1,
					  NULL,
					  ' ',
					  I.CCI_BIRTH_DATE,
					  V_GENDER,
					  NULL,
					  NULL,
					  NULL,
					  NULL,
					  NULL,
					  NULL,
					  PRM_LUPDUSER,
					  I.CCI_SSN,
					  I.CCI_MOTHERS_MAIDEN_NAME,
					  I.CCI_HOBBIES,
					  I.CCI_EMP_ID,
					  V_CATG_CODE,
					  I.CCI_CUST_ID,
					  V_CUST_DATA,
					  V_CUST_CODE,
					  V_ERRMSG);

		  IF V_ERRMSG <> 'OK' THEN
		    V_ERRMSG := 'Error from create cutomer ' || V_ERRMSG;
		    RAISE EXP_REJECT_RECORD;
		  END IF;
		EXCEPTION
		  WHEN EXP_REJECT_RECORD THEN
		    RAISE;
		  WHEN OTHERS THEN
		    V_ERRMSG := 'Error while create customer ' ||
					 SUBSTR(SQLERRM, 1, 200);
		    RAISE EXP_REJECT_RECORD;
		END;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting customer from master ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En create customer
	 ---   ************************************************************************************
	 --Sn create address
	 BEGIN
	   --Sn create communication address
	   SELECT DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG12_ADDR_LINE1,
				  I.CCI_SEG13_ADDR_LINE1),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG12_ADDR_LINE2,
				  I.CCI_SEG13_ADDR_LINE2),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG12_POSTAL_CODE,
				  I.CCI_SEG13_HOMEPHONE_NO),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG12_HOMEPHONE_NO,
				  I.CCI_SEG13_HOMEPHONE_NO),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG12_MOBILENO,
				  I.CCI_SEG13_MOBILENO),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG12_OFFICEPHONE_NO,
				  I.CCI_SEG13_OFFICEPHONE_NO),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG12_EMAILID,
				  I.CCI_SEG13_EMAILID),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG12_CITY,
				  I.CCI_SEG13_CITY),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG12_STATE,
				  I.CCI_SEG13_STATE),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG12_COUNTRY_CODE,
				  I.CCI_SEG13_COUNTRY_CODE),
			--Sn assign other gen comm adddress
			TYPE_ADDR_REC_ARRAY(DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG12_ADDR_PARAM1,
								  I.CCI_SEG13_ADDR_PARAM1),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG12_ADDR_PARAM2,
								  I.CCI_SEG13_ADDR_PARAM2),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG12_ADDR_PARAM3,
								  I.CCI_SEG13_ADDR_PARAM3),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG12_ADDR_PARAM4,
								  I.CCI_SEG13_ADDR_PARAM4),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG12_ADDR_PARAM5,
								  I.CCI_SEG13_ADDR_PARAM5),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG12_ADDR_PARAM6,
								  I.CCI_SEG13_ADDR_PARAM6),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG12_ADDR_PARAM7,
								  I.CCI_SEG13_ADDR_PARAM7),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG12_ADDR_PARAM8,
								  I.CCI_SEG13_ADDR_PARAM8),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG12_ADDR_PARAM9,
								  I.CCI_SEG13_ADDR_PARAM9),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG12_ADDR_PARAM10,
								  I.CCI_SEG13_ADDR_PARAM10)),
			--En assign other gen comm address
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG13_ADDR_LINE1,
				  I.CCI_SEG12_ADDR_LINE1),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG13_ADDR_LINE2,
				  I.CCI_SEG12_ADDR_LINE2),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG13_POSTAL_CODE,
				  I.CCI_SEG12_POSTAL_CODE),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG13_HOMEPHONE_NO,
				  I.CCI_SEG12_HOMEPHONE_NO),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG13_MOBILENO,
				  I.CCI_SEG12_MOBILENO),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG13_OFFICEPHONE_NO,
				  I.CCI_SEG12_OFFICEPHONE_NO),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG13_EMAILID,
				  I.CCI_SEG12_EMAILID),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG13_CITY,
				  I.CCI_SEG12_CITY),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG13_STATE,
				  I.CCI_SEG12_STATE),
			DECODE(I.CCI_COMM_TYPE,
				  '0',
				  I.CCI_SEG13_COUNTRY_CODE,
				  I.CCI_SEG12_COUNTRY_CODE),
			--Sn assign other gen comm adddress
			TYPE_ADDR_REC_ARRAY(DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG13_ADDR_PARAM1,
								  I.CCI_SEG12_ADDR_PARAM1),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG13_ADDR_PARAM2,
								  I.CCI_SEG12_ADDR_PARAM2),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG13_ADDR_PARAM3,
								  I.CCI_SEG12_ADDR_PARAM3),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG13_ADDR_PARAM4,
								  I.CCI_SEG12_ADDR_PARAM4),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG13_ADDR_PARAM5,
								  I.CCI_SEG12_ADDR_PARAM5),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG13_ADDR_PARAM6,
								  I.CCI_SEG12_ADDR_PARAM6),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG13_ADDR_PARAM7,
								  I.CCI_SEG12_ADDR_PARAM7),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG13_ADDR_PARAM8,
								  I.CCI_SEG12_ADDR_PARAM8),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG13_ADDR_PARAM9,
								  I.CCI_SEG12_ADDR_PARAM9),
							DECODE(I.CCI_COMM_TYPE,
								  '0',
								  I.CCI_SEG13_ADDR_PARAM10,
								  I.CCI_SEG12_ADDR_PARAM10))
	   --En assign other gen comm address
		INTO V_COMM_ADDR_LIN1,
			V_COMM_ADDR_LIN2,
			V_COMM_POSTAL_CODE,
			V_COMM_HOMEPHONE_NO,
			V_COMM_MOBILENO,
			V_COMM_OFFICENO,
			V_COMM_EMAILID,
			V_COMM_CITY,
			V_COMM_STATE,
			V_COMM_CNTRYCODE,
			V_ADDR_DATA1,
			V_OTHER_ADDR_LIN1,
			V_OTHER_ADDR_LIN2,
			V_OTHER_POSTAL_CODE,
			V_OTHER_HOMEPHONE_NO,
			V_OTHER_MOBILENO,
			V_OTHER_OFFICENO,
			V_OTHER_EMAILID,
			V_OTHER_CITY,
			V_OTHER_STATE,
			V_OTHER_CNTRYCODE,
			V_ADDR_DATA2
		FROM DUAL;

	   --Sn create communication address
	   IF V_COMM_ADDR_LIN1 IS NOT NULL THEN
		IF V_COMM_ADDR_LIN1 = I.CCI_SEG12_ADDR_LINE1 THEN
		  V_COMM_TYPE := 'R';
		ELSIF V_COMM_ADDR_LIN1 = I.CCI_SEG13_ADDR_LINE1 THEN
		  V_COMM_TYPE := 'O';
		END IF;

		BEGIN
		  SELECT GCM_CNTRY_CODE
		    INTO V_GCM_CNTRY_CODE
		    FROM GEN_CNTRY_MAST
		   WHERE GCM_CURR_CODE = V_COMM_CNTRYCODE AND
			    GCM_INST_CODE = PRM_INSTCODE;

		  SP_CREATE_ADDR(PRM_INSTCODE,
					  V_CUST_CODE,
					  V_COMM_ADDR_LIN1,
					  V_COMM_ADDR_LIN2,
					  NULL,
					  V_COMM_POSTAL_CODE,
					  V_COMM_HOMEPHONE_NO,
					  V_COMM_MOBILENO,
					  V_COMM_OFFICENO,
					  V_COMM_EMAILID,
					  V_GCM_CNTRY_CODE,
					  V_COMM_CITY,
					  V_COMM_STATE,
					  NULL,
					  'P',
					  V_COMM_TYPE,
					  PRM_LUPDUSER,
					  V_ADDR_DATA1,
					  V_COMM_ADDRCODE,
					  V_ERRMSG);

		  IF V_ERRMSG <> 'OK' THEN
		    V_ERRMSG := 'Error from create communication address ' ||
					 V_ERRMSG;
		    RAISE EXP_REJECT_RECORD;
		  END IF;
		EXCEPTION
		  WHEN EXP_REJECT_RECORD THEN
		    RAISE;
		  WHEN OTHERS THEN
		    V_ERRMSG := 'Error while create communication address ' ||
					 SUBSTR(SQLERRM, 1, 200);
		    RAISE EXP_REJECT_RECORD;
		END;
	   END IF;

	   --En create communication address
	   --Sn create other address
	   IF V_OTHER_ADDR_LIN1 IS NOT NULL THEN
		IF V_COMM_ADDR_LIN1 = I.CCI_SEG12_ADDR_LINE1 THEN
		  V_COMM_TYPE := 'R';
		ELSIF V_COMM_ADDR_LIN1 = I.CCI_SEG13_ADDR_LINE1 THEN
		  V_COMM_TYPE := 'O';
		END IF;

		BEGIN
		  SELECT GCM_CNTRY_CODE
		    INTO V_GCM_OTHERCNTRY_CODE
		    FROM GEN_CNTRY_MAST
		   WHERE GCM_CURR_CODE = V_OTHER_CNTRYCODE AND
			    GCM_INST_CODE = PRM_INSTCODE;

		  SP_CREATE_ADDR(PRM_INSTCODE,
					  V_CUST_CODE,
					  V_OTHER_ADDR_LIN1,
					  V_OTHER_ADDR_LIN2,
					  NULL,
					  V_OTHER_POSTAL_CODE,
					  V_OTHER_HOMEPHONE_NO,
					  V_OTHER_MOBILENO,
					  V_OTHER_OFFICENO,
					  V_OTHER_EMAILID,
					  V_GCM_OTHERCNTRY_CODE,
					  V_OTHER_CITY,
					  V_OTHER_STATE,
					  NULL,
					  'O',
					  V_COMM_TYPE,
					  PRM_LUPDUSER,
					  V_ADDR_DATA2,
					  V_OTHER_ADDRCODE,
					  V_ERRMSG);

		  IF V_ERRMSG <> 'OK' THEN
		    V_ERRMSG := 'Error from create communication address ' ||
					 V_ERRMSG;
		    RAISE EXP_REJECT_RECORD;
		  END IF;
		EXCEPTION
		  WHEN EXP_REJECT_RECORD THEN
		    RAISE;
		  WHEN OTHERS THEN
		    V_ERRMSG := 'Error while create communication address ' ||
					 SUBSTR(SQLERRM, 1, 200);
		    RAISE EXP_REJECT_RECORD;
		END;
	   END IF;
	   --En create other address
	 EXCEPTION
	   WHEN EXP_REJECT_RECORD THEN
		RAISE;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while creating address ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En create address
	 ---   ************************************************************************************
	 ---   ************************************************************************************
	 --Sn select acct type
	 BEGIN
	   SELECT CAT_TYPE_CODE
		INTO V_ACCT_TYPE
		FROM CMS_ACCT_TYPE
	    WHERE CAT_INST_CODE = PRM_INSTCODE AND
			CAT_SWITCH_TYPE = I.CCI_SEG31_TYP;
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		V_ERRMSG := 'Acct type not defined for  ' || I.CCI_SEG31_TYP;
		RAISE EXP_REJECT_RECORD;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting accttype ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En select acct type
	 --Sn select acct stat
	 BEGIN
	   SELECT CAS_STAT_CODE
		INTO V_ACCT_STAT
		FROM CMS_ACCT_STAT
	    WHERE CAS_INST_CODE = PRM_INSTCODE AND
			CAS_SWITCH_STATCODE = I.CCI_SEG31_STAT;
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		V_ERRMSG := 'Acct stat not defined for  ' || I.CCI_SEG31_STAT;
		RAISE EXP_REJECT_RECORD;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting accttype ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En select acct stat
	 --**********************************************************************
	 --***********************************************************************
	 --Checking for acct id for Addon, if it is null then throw error

	 IF (UPPER(I.CCI_ADDON_FLAG) = 'TRUE') THEN

	   SELECT COUNT(*)
		INTO V_CNT
		FROM CMS_APPL_PAN
	    WHERE CAP_ACCT_NO = I.CCI_SEG31_NUM AND CAP_ADDON_STAT = 'P';

	 END IF;

	 IF V_CNT = 0 THEN

	   V_ERRMSG := 'Primary card not present for this account ';
	   RAISE EXP_REJECT_RECORD;
	 END IF;

	 --End

	 IF V_CATG_CODE = 'P' THEN
	   V_ACCT_NUMB := NULL;
	 ELSIF V_CATG_CODE IN ('D', 'A') THEN
	   V_ACCT_NUMB := I.CCI_SEG31_NUM;
	 END IF;

	 --Sn create acct
	 --Sn select gen acct data
	 BEGIN
	   SELECT TYPE_ACCT_REC_ARRAY(I.CCI_SEG31_NUM_PARAM1,
							I.CCI_SEG31_NUM_PARAM2,
							I.CCI_SEG31_NUM_PARAM3,
							I.CCI_SEG31_NUM_PARAM4,
							I.CCI_SEG31_NUM_PARAM5,
							I.CCI_SEG31_NUM_PARAM6,
							I.CCI_SEG31_NUM_PARAM7,
							I.CCI_SEG31_NUM_PARAM8,
							I.CCI_SEG31_NUM_PARAM9,
							I.CCI_SEG31_NUM_PARAM10)
		INTO V_SEG31ACCTNUM_DATA
		FROM DUAL;
	 EXCEPTION
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting acct data ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;
	 IF V_ERRMSG = 'OK' THEN
	   --En select gen acct data
	   BEGIN
		SP_CREATE_ACCT(PRM_INSTCODE,
					V_ACCT_NUMB,
					0,
					I.CCI_FIID,
					V_COMM_ADDRCODE,
					V_ACCT_TYPE,
					V_ACCT_STAT,
					PRM_LUPDUSER,
					V_SEG31ACCTNUM_DATA,
					I.CCI_PAN_CODE,
					I.CCI_CUST_ID,
					V_DUP_FLAG,
					V_ACCT_ID,
					V_ERRMSG);

		IF V_ERRMSG <> 'OK' THEN
		  IF V_ERRMSG = 'Account No already in Master.' THEN
		    V_ERRMSG := 'OK';
		  ELSE
		    V_ERRMSG := 'Error from create acct ' || V_ERRMSG;
		    RAISE EXP_REJECT_RECORD;
		  END IF;
		END IF;
	   EXCEPTION
		WHEN EXP_REJECT_RECORD THEN
		  RAISE;
		WHEN OTHERS THEN
		  V_ERRMSG := 'Error while create acct ' ||
				    SUBSTR(SQLERRM, 1, 200);
		  RAISE EXP_REJECT_RECORD;
	   END;
	   --Check for Addon stat  and duplicate account added on 08-02-2011
	 END IF;
	 IF (V_DUP_FLAG = 'D' AND UPPER(I.CCI_ADDON_FLAG) = 'TRUE') THEN
	   V_DUP_FLAG := 'A';
	 END IF;

	 --En create acct
	 --Sn create a entry in cms_cust_acct
	 BEGIN
	   UPDATE CMS_ACCT_MAST
		 SET CAM_HOLD_COUNT = CAM_HOLD_COUNT + 1,
			CAM_LUPD_USER  = PRM_LUPDUSER
	    WHERE CAM_INST_CODE = PRM_INSTCODE AND CAM_ACCT_ID = V_ACCT_ID;

	   IF SQL%ROWCOUNT = 0 THEN
		V_ERRMSG := 'Error while create acct ' || SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	   END IF;
	 END;

	 SP_CREATE_HOLDER(PRM_INSTCODE,
				   V_CUST_CODE,
				   V_ACCT_ID,
				   NULL,
				   PRM_LUPDUSER,
				   V_HOLDPOSN,
				   V_ERRMSG);

	 IF V_ERRMSG <> 'OK' THEN
	   V_ERRMSG := 'Error from create entry cust_acct ' || V_ERRMSG;
	   RAISE EXP_REJECT_RECORD;
	 END IF;

	 ---En create a entry in cms_cust_acct
	 -- Sn create Application
	 -- Sn find expry param
	 BEGIN
	   SELECT CIP_PARAM_VALUE
	   --added on 11/10/2002 ...gets the card validity period in months from parameter table
		INTO V_EXPRYPARAM
		FROM CMS_INST_PARAM
	    WHERE CIP_INST_CODE = PRM_INSTCODE AND
			CIP_PARAM_KEY = 'CARD EXPRY';
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		V_ERRMSG := 'Expry parameter is not defined in master';
		RAISE EXP_REJECT_RECORD;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting data from master for expryparam';
		RAISE EXP_REJECT_RECORD;
	 END;

	 -- En find expry param
	 --Sn select gen acct data
	 BEGIN
	   SELECT TYPE_APPL_REC_ARRAY(I.CCI_CUSTAPPL_PARAM1,
							I.CCI_CUSTAPPL_PARAM2,
							I.CCI_CUSTAPPL_PARAM3,
							I.CCI_CUSTAPPL_PARAM4,
							I.CCI_CUSTAPPL_PARAM5,
							I.CCI_CUSTAPPL_PARAM6,
							I.CCI_CUSTAPPL_PARAM7,
							I.CCI_CUSTAPPL_PARAM8,
							I.CCI_CUSTAPPL_PARAM9,
							I.CCI_CUSTAPPL_PARAM10)
		INTO V_APPL_DATA
		FROM DUAL;
	 EXCEPTION
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting appl data ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En select gen acct data

	 -- Sn Appl
	 BEGIN
	   SP_CREATE_APPL(PRM_INSTCODE,
				   1,
				   1,
				   I.CCI_APPL_NO,
				   SYSDATE,
				   SYSDATE,
				   V_CUST_CODE,
				   I.CCI_FIID,
				   V_PRODCODE,
				   V_CARD_TYPE,
				   --(normal or blue depending upon hni or others cust catg)
				   V_CUSTCATG_CODE, --customer category
				   SYSDATE,
				   -- last_day(add_months(to_date(i2.cci_exp_dat,'YYMM'),--(expry_param))), -- Ashwini -25 Jan 05----  to be written as code refered frm hdfc ,
				   -- Expry date is last day of the prev month after adding expry param
				   LAST_DAY(ADD_MONTHS(SYSDATE, V_EXPRYPARAM - 1)),
				   --last_day(to_date(i2.cci_exp_dat,'YYMM')), -- Ashwini-25 Jan 05 ----  to be written as code refered frm hdfc --
				   SUBSTR(I.CCI_SEG12_NAME_LINE2, 1, 30),
				   0,
				   'N',
				   NULL,
				   1,

				   --total account count  = 1 since in upload a card is associated with only one account
				   'P', --addon status always a primary application
				   0,
				   --addon link 0 means that the appln is for promary pan
				   V_COMM_ADDRCODE, --billing address
				   NULL, --channel code
				   NULL,
				   I.CCI_PAYREF_NO,
				   PRM_LUPDUSER,
				   PRM_LUPDUSER,
				   V_DUP_FLAG,
				   TO_NUMBER(I.CCI_PROD_AMT),
				   NULL,
				   V_APPL_DATA,
				   V_APPL_CODE, --out param
				   V_ERRMSG);

	   IF V_ERRMSG <> 'OK' THEN
		V_ERRMSG := 'Error from create appl ' || V_ERRMSG;
		RAISE EXP_REJECT_RECORD;
	   END IF;
	 EXCEPTION
	   WHEN EXP_REJECT_RECORD THEN
		RAISE;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while create appl ' || SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 -- En Appl
	 -- Sn create entry in appl_det
	 BEGIN
	   SP_CREATE_APPLDET(PRM_INSTCODE,
					 V_APPL_CODE,
					 V_ACCT_ID,
					 1,
					 PRM_LUPDUSER,
					 V_ERRMSG);

	   IF V_ERRMSG <> 'OK' THEN
		V_ERRMSG := 'Error from create appl det ' || V_ERRMSG;
		RAISE EXP_REJECT_RECORD;
	   END IF;
	 EXCEPTION
	   WHEN EXP_REJECT_RECORD THEN
		RAISE;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while create appl det ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;

	 -- En create entry in appl_det
	 --Sn Create acct in corporate card
	 --                            IF i.cci_corp_id IS NOT NULL
	 --                            THEN
	 --                               BEGIN
	 --                                  INSERT INTO cms_corporate_cards
	 --                                              (pcc_inst_code, pcc_corp_code, pcc_pan_no,
	 --                                               pcc_ins_user, pcc_ins_date, pcc_lupd_user,
	 --                                               pcc_lupd_date
	 --                                              )
	 --                                       VALUES (prm_instcode, i.cci_corp_id, v_acct_id,
	 --                                               prm_lupduser, SYSDATE, prm_lupduser,
	 --                                               SYSDATE
	 --                                              );
	 --                                  IF SQL%ROWCOUNT = 0
	 --                                  THEN
	 --                                     v_errmsg :=
	 --                                           'Error while inserting in CMS_CORPORATE_CARDS '
	 --                                        || SUBSTR (SQLERRM, 1, 200);
	 --                                     RAISE exp_reject_record;
	 --                                  END IF;
	 --                               END;
	 --                            END IF;
	 --                          --En Create acct in corporate card.
	 --                   --Sn Create acct in corporate card
	 --                      IF i2.cci_merc_code IS NOT NULL
	 --                      THEN
	 --                         BEGIN
	 --                            INSERT INTO cms_merchant_cards
	 --                                        (pcc_inst_code, pcc_merc_code, pcc_pan_no,
	 --                                         pcc_ins_user, pcc_ins_date, pcc_lupd_user,
	 --                                         pcc_lupd_date,pcc_cust_code
	 --                                        )
	 --                                 VALUES (prm_instcode, i.cci_merc_code, v_acct_id,
	 --                                         prm_lupduser, SYSDATE, prm_lupduser,
	 --                                         SYSDATE,v_cust_code
	 --                                        );
	 --                            IF SQL%ROWCOUNT = 0
	 --                            THEN
	 --                               v_errmsg :=
	 --                                     'Error while inserting in PCMS_MERCHANT_CARDS '
	 --                                  || SUBSTR (SQLERRM, 1, 200);
	 --                               RAISE exp_reject_record;
	 --                            END IF;
	 --                         END;
	 --                      END IF;
	 --En Create acct in corporate card.
	 --En create Application
	 UPDATE CMS_CAF_INFO_ENTRY
	    SET CCI_APPROVED    = 'O',
		   CCI_UPLD_STAT   = 'O',
		   CCI_APPL_CODE   = V_APPL_CODE,
		   CCI_PROCESS_MSG = 'Successful'
	  WHERE ROWID = I.R;

	 BEGIN
	   INSERT INTO PCMS_UPLOAD_LOG
		(PUL_INST_CODE,
		 PUL_FILE_NAME,
		 PUL_APPL_NO,
		 PUL_UPLD_STAT,
		 PUL_APPROVE_STAT,
		 PUL_INS_DATE,
		 PUL_ROW_ID,
		 PUL_PROCESS_MESSAGE)
	   VALUES
		(PRM_INSTCODE,
		 I.CCI_FILE_NAME,
		 I.CCI_APPL_NO,
		 'O',
		 'O',
		 SYSDATE,
		 I.CCI_ROW_ID,
		 'Successful');

	   IF SQL%ROWCOUNT = 0 THEN
		PRM_ERRMSG := 'Error While inserting record in log table';
		ROLLBACK TO V_SAVEPOINT;
	   END IF;
	 EXCEPTION
	   WHEN OTHERS THEN
		PRM_ERRMSG := 'Error While inserting record in log table';
		ROLLBACK TO V_SAVEPOINT;
	 END;
    EXCEPTION
	 --<< LOOP EXCEPTION I>>
	 WHEN EXP_PROCESS_RECORD THEN
	   ROLLBACK TO V_SAVEPOINT;

	   UPDATE CMS_CAF_INFO_ENTRY
		 SET CCI_UPLD_STAT = 'P', CCI_PROCESS_MSG = V_ERRMSG
	    WHERE ROWID = I.R;

	   BEGIN
		INSERT INTO PCMS_UPLOAD_LOG
		  (PUL_INST_CODE,
		   PUL_FILE_NAME,
		   PUL_APPL_NO,
		   PUL_UPLD_STAT,
		   PUL_APPROVE_STAT,
		   PUL_INS_DATE,
		   PUL_ROW_ID,
		   PUL_PROCESS_MESSAGE)
		VALUES
		  (PRM_INSTCODE,
		   I.CCI_FILE_NAME,
		   I.CCI_APPL_NO,
		   'E',
		   'A',
		   SYSDATE,
		   I.CCI_ROW_ID,
		   V_ERRMSG);

		IF SQL%ROWCOUNT = 0 THEN
		  PRM_ERRMSG := 'Error While inserting record in log table';
		  ROLLBACK TO V_SAVEPOINT;
		END IF;
	   EXCEPTION
		WHEN OTHERS THEN
		  PRM_ERRMSG := 'Error While inserting record in log table';
		  ROLLBACK TO V_SAVEPOINT;
	   END;
	 WHEN EXP_REJECT_RECORD THEN
	   ROLLBACK TO V_SAVEPOINT;

	   UPDATE CMS_CAF_INFO_ENTRY
		 SET CCI_UPLD_STAT = 'E', CCI_PROCESS_MSG = V_ERRMSG
	    WHERE ROWID = I.R;

	   BEGIN
		INSERT INTO PCMS_UPLOAD_LOG
		  (PUL_INST_CODE,
		   PUL_FILE_NAME,
		   PUL_APPL_NO,
		   PUL_UPLD_STAT,
		   PUL_APPROVE_STAT,
		   PUL_INS_DATE,
		   PUL_ROW_ID,
		   PUL_PROCESS_MESSAGE)
		VALUES
		  (PRM_INSTCODE,
		   I.CCI_FILE_NAME,
		   I.CCI_APPL_NO,
		   'E',
		   'A',
		   SYSDATE,
		   I.CCI_ROW_ID,
		   V_ERRMSG);

		IF SQL%ROWCOUNT = 0 THEN
		  PRM_ERRMSG := 'Error While inserting record in log table';
		  ROLLBACK TO V_SAVEPOINT;
		END IF;
	   EXCEPTION
		WHEN OTHERS THEN
		  PRM_ERRMSG := 'Error While inserting record in log table';
		  ROLLBACK TO V_SAVEPOINT;
	   END;
	 WHEN OTHERS THEN
	   ROLLBACK TO V_SAVEPOINT;
	   V_ERRMSG := 'Error while processing ' || SUBSTR(SQLERRM, 1, 200);

	   UPDATE CMS_CAF_INFO_ENTRY
		 SET CCI_UPLD_STAT = 'E', CCI_PROCESS_MSG = V_ERRMSG
	    WHERE ROWID = I.R;

	   BEGIN
		INSERT INTO PCMS_UPLOAD_LOG
		  (PUL_INST_CODE,
		   PUL_FILE_NAME,
		   PUL_APPL_NO,
		   PUL_UPLD_STAT,
		   PUL_APPROVE_STAT,
		   PUL_INS_DATE,
		   PUL_ROW_ID,
		   PUL_PROCESS_MESSAGE)
		VALUES
		  (PRM_INSTCODE,
		   I.CCI_FILE_NAME,
		   I.CCI_APPL_NO,
		   'E',
		   'A',
		   SYSDATE,
		   I.CCI_ROW_ID,
		   V_ERRMSG);

		IF SQL%ROWCOUNT = 0 THEN
		  PRM_ERRMSG := 'Error While inserting record in log table';
		  ROLLBACK TO V_SAVEPOINT;
		END IF;
	   EXCEPTION
		WHEN OTHERS THEN
		  PRM_ERRMSG := 'Error While inserting record in log table';
		  ROLLBACK TO V_SAVEPOINT;
	   END;
    END; --<< LOOP END I>>
  END LOOP;
EXCEPTION
  -- USED ONLY OR COMPILATION
  WHEN OTHERS THEN
    PRM_ERRMSG := 'Error from main ' || SUBSTR(SQLERRM, 1, 200);
END; --USED ONLY FOR COMPILATION
/


