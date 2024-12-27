create or replace
PROCEDURE               VMSCMS.SP_STOCK_ISSUANCE(P_INST_CODE     IN   NUMBER,
                                       P_USER_CODE IN NUMBER,
                                       P_FIID      IN VARCHAR2,
                                       P_BIN       IN VARCHAR2,
                                       P_PROD_CODE IN VARCHAR2,
                                       P_PROD_CATG IN VARCHAR2,
                                       P_CUST_CATG IN VARCHAR2,
                                       P_STORE_ID  IN VARCHAR2,
                                       P_STOCK_CNT IN NUMBER,
                                       P_CARD_ID   IN VARCHAR2,
                                       P_ERR_MSG   OUT VARCHAR2,
                                       P_ACTIVATION_STICKERID IN VARCHAR2) IS

  /*************************************************

       * Created By       : Saravanan
       * Created Date     : 05/01/2013
       * Purpose          : Moved the code from java to data base for Performance issue.
       * Modified By      : Sagar M
       * Modified reason  : Added instcOde which was missing in queries
       * Modified On      : 14/01/2013
       * Reviewer         : Dhiraj
       * Reviewed Date    : 14/01/2013
       * Build Number     : CMS3.5.1_RI0023.1_B0001
        * Modified By      : B.Bhagya Sree
       * Modified Date    : 12-MAY-2014
       * Modified Reason  : MVHOST-866 (default country codeas 2 and state code as 17)
       * Reviewer         : Spankaj
       * Reviewed Date    : 14-May-2014
       * Release Number   : RI0027.1.5_B0001
       
       * Modified By      : Siva Kumar M
       * Modified Date    : 07-June-2016
       * Modified Reason  : Mantis_id:16413
       * Reviewer         : Saravana kuamr A
       * Reviewed Date    : 07-June-2016
       * Release Number   : VMSGPRHOST4.1_B0004
	   
       * Modified By      : Sreeja D
       * Modified Date    : 17-November-2017
       * Modified Reason  : VMS - 66
       * Reviewer         : Saravanakumar A
       * Reviewed Date    : 17-November-2017
       * Release Number   : VMSGPRHOST_17.11
	   
	
	* Modified by      :  Vini Pushkaran
      * Modified Date    :  02-Feb-2018
      * Modified For     :  VMS-162
      * Reviewer         :  Saravanankumar
      * Build Number     :  VMSGPRHOSTCSD_18.01
      
     * Modified By      : Magesh S.
     * Modified Date    : 05-Feb-2023
     * Purpose          : VMS-6652
     * Reviewer         : Venkat S.
     * Release Number   : R78

    * Modified By      : Shanmugavel
    * Modified Date    : 11/04/2024
    * Purpose          : VMS-8523-Activation Sticker for Retail at the Order Level in Stock Issuance/Card Stock Module
    * Reviewer         : Venkat/John/Pankaj
    * Release Number   : VMSGPRHOSTR96_B0001
  *************************************************/

  EXP_REJECT_EXCEPTION EXCEPTION;
  V_CARD_GEN_CNT      CMS_STOCK_MAST.CSM_CARD_GENERATED%TYPE;
  V_THRESHOLD_LMT     CMS_STOCK_MAST.CSM_CARD_THRESHOLD%TYPE;
  V_CARD_TOBE_GEN_CNT NUMBER;
  V_CARD_PENDING_CNT  NUMBER;
  V_FILE_NAME         VARCHAR2(20);
  V_CNTRY_CODE        GEN_CNTRY_MAST.GCM_CNTRY_CODE%TYPE;
  V_PROD_B24          CMS_PRODTYPE_MAP.CPM_PROD_B24%TYPE;
 -- V_DISPLAY_NAME      VARCHAR2(100);
  V_DISPLAY_NAME      CMS_PROD_CATTYPE.CPC_STARTERCARD_DISPNAME%TYPE;
  v_encrypt_enable    CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
  v_encr_firstname    CMS_CAF_INFO_ENTRY.CCI_SEG12_NAME_LINE1%TYPE;     
  v_encr_dummy        CMS_CAF_INFO_ENTRY.CCI_SEG12_NAME_LINE2%TYPE;   
   v_pan_inv_flag       Cms_Prod_Cattype.Cpc_Pan_Inventory_Flag%type;
  v_toggle_value      cms_inst_param.cip_param_value%TYPE;  --Added for VMS-6652 
  
BEGIN
  P_ERR_MSG   := 'OK';
  V_FILE_NAME := TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') || '.txt';

  BEGIN
    SELECT CSM_CARD_THRESHOLD, CSM_CARD_GENERATED  
     INTO V_THRESHOLD_LMT, V_CARD_GEN_CNT 
     FROM CMS_STOCK_MAST
    WHERE CSM_INST_CODE = P_INST_CODE AND CSM_INST_BIN = P_BIN AND
         CSM_BRAN_FIID = P_FIID AND CSM_PROD_CODE = P_PROD_CODE AND
         CSM_CARD_TYPE = P_PROD_CATG AND CSM_CARD_ID = P_CARD_ID AND
         CSM_CUST_CATG =
         (SELECT CCC_CATG_CODE
            FROM CMS_CUST_CATG
           WHERE CCC_CATG_SNAME = P_CUST_CATG AND ROWNUM = 1);
  EXCEPTION
   WHEN NO_DATA_FOUND THEN
    P_ERR_MSG := 'Threshold is not set for '||P_PROD_CODE ||' '||P_PROD_CATG||' '||P_CARD_ID ||' '||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_EXCEPTION;
    WHEN OTHERS THEN
     P_ERR_MSG := 'Error while selecting cms_stock_mast ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_EXCEPTION;
  END;

  V_CARD_TOBE_GEN_CNT := V_THRESHOLD_LMT - V_CARD_GEN_CNT;

  IF P_STOCK_CNT > V_CARD_TOBE_GEN_CNT THEN
    P_ERR_MSG := 'Threshold limit reached. Please increase the limit / Provide less no of cards.';
    RAISE EXP_REJECT_EXCEPTION;
  END IF;

  BEGIN
    SELECT COUNT(*)
     INTO V_CARD_PENDING_CNT
     FROM CMS_CAF_INFO_TEMP, CMS_STOCK_MAST, CMS_CUST_CATG
    WHERE CCI_UPLD_STAT = 'B'
    AND  CCI_PROD_CODE = P_PROD_CODE
    AND  CCI_CARD_TYPE = P_PROD_CATG
    AND  CCI_CUST_CATG = P_CUST_CATG
    AND  CCI_FIID      = P_FIID --Included this condition since getting more than one record
    AND  CCI_INST_CODE = P_INST_CODE  -- ADDED ON 14JAN2013 Missing in queries
    AND  CCI_INST_CODE = CSM_INST_CODE -- ADDED ON 14JAN2013 Missing in queries
    AND  CCC_INST_CODE = CSM_INST_CODE -- ADDED ON 14JAN2013 Missing in queries
    AND  CCI_PROD_CODE = CSM_PROD_CODE
    AND  CCI_CARD_TYPE = CSM_CARD_TYPE
    AND  CCI_CUST_CATG = CCC_CATG_SNAME
    AND  CCC_CATG_CODE = CSM_CUST_CATG
	AND  CSM_CARD_ID   = P_CARD_ID
    GROUP BY CCI_PAN_CODE,
            CCI_FIID,
            CCI_PROD_CODE,
            CCI_CARD_TYPE,
            CCI_CUST_CATG;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     -- Added by Raja Gopal G
     V_CARD_PENDING_CNT := 0;
    WHEN OTHERS THEN
     P_ERR_MSG := 'Error while selecting V_CARD_PENDING_CNT ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_EXCEPTION;
  END;

  IF P_STOCK_CNT > V_CARD_TOBE_GEN_CNT - V_CARD_PENDING_CNT AND
    V_CARD_PENDING_CNT > 0 THEN
    P_ERR_MSG := 'Threshold limit reached. Please increase the limit / Provide less no of cards.Already ' ||
              V_CARD_PENDING_CNT || ' Cards are Pending For Approval';
    RAISE EXP_REJECT_EXCEPTION;
  END IF;

  BEGIN
    INSERT INTO CMS_STOCK_REPORT
     (CSR_INST_CODE,
      CSR_BRAN_FIID,
      CSR_INST_BIN,
      CSR_LUPD_USER,
      CSR_LUPD_DATE,
      CSR_FILE_NAME,
      CSR_PROD_CODE,
      CSR_CARD_TYPE,
      CSR_CUST_CATG,
      CSR_CARD_GENERATED,
	  CSR_CARD_ID,
      CSR_ACTIVATION_STICKERID)
    VALUES
     (P_INST_CODE,
      P_FIID,
      P_BIN,
      P_USER_CODE,
      SYSDATE,
      V_FILE_NAME,
      P_PROD_CODE,
      P_PROD_CATG,
      (SELECT CCC_CATG_CODE
        FROM CMS_CUST_CATG
        WHERE CCC_INST_CODE = P_INST_CODE -- ADDED ON 14JAN2013 Missing in queries
        AND   CCC_CATG_SNAME = P_CUST_CATG AND ROWNUM = 1),
      P_STOCK_CNT,
	  P_CARD_ID,
      P_ACTIVATION_STICKERID);
  EXCEPTION
    WHEN OTHERS THEN
     P_ERR_MSG := 'Error while inserting cms_stock_report ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_EXCEPTION;
  END;

  BEGIN
    INSERT INTO CMS_BULK_ACTIVITY_REPORT
     (CBA_USER_PIN, CBA_INS_DATE, CBA_USER_ACTIVITY, CBA_FILE_UPLOADED)
    VALUES
     (P_USER_CODE, SYSDATE, 'Bulk Issuance', V_FILE_NAME);
  EXCEPTION
    WHEN OTHERS THEN
     P_ERR_MSG := 'Error while inserting cms_bulk_activity_report ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_EXCEPTION;
  END;

  BEGIN
    SELECT GCM_CNTRY_CODE
     INTO V_CNTRY_CODE
     FROM GEN_CNTRY_MAST
    WHERE GCM_CURR_CODE =
         (SELECT CIP_PARAM_VALUE
            FROM CMS_INST_PARAM
           WHERE CIP_INST_CODE = P_INST_CODE AND
                CIP_PARAM_KEY = 'CURRENCY') AND
         GCM_INST_CODE = P_INST_CODE;
  EXCEPTION
    WHEN OTHERS THEN
     P_ERR_MSG := 'Error while selecting gen_cntry_mast ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_EXCEPTION;
  END;
  BEGIN
    SELECT CPM_PROD_B24
     INTO V_PROD_B24
     FROM CMS_PRODTYPE_MAP
    WHERE CPM_INST_CODE = P_INST_CODE -- ADDED ON 14JAN2013 Missing in queries
    AND   CPM_INTERCHANGE_CODE =
         (SELECT DISTINCT CPB_INTERCHANGE_CODE
            FROM CMS_PROD_BIN
           WHERE CPB_PROD_CODE = P_PROD_CODE AND
                CPB_INST_CODE = P_INST_CODE AND CPB_INST_BIN = P_BIN) AND
         CPM_PROD_CATG =
         (SELECT CPM_CATG_CODE
            FROM CMS_PROD_MAST
           WHERE CPM_INST_CODE = P_INST_CODE -- ADDED ON 14JAN2013 Missing in queries
           AND   CPM_PROD_CODE = P_PROD_CODE);
  EXCEPTION
    WHEN OTHERS THEN
     P_ERR_MSG := 'Error while selecting cms_prodtype_map ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_EXCEPTION;
  END;
  BEGIN
  
    SELECT   CPC_STARTERCARD_DISPNAME, cpc_encrypt_enable,Cpc_Pan_Inventory_Flag
    INTO V_DISPLAY_NAME,v_encrypt_enable,V_Pan_Inv_Flag  
    FROM CMS_PROD_CATTYPE 
    WHERE cpc_prod_code=p_prod_code 
    AND cpc_card_type=p_prod_catg
    AND cpc_inst_code=p_inst_code;
  
   if  V_DISPLAY_NAME is null then 
   
          SELECT CBM_INTERCHANGE_CODE
           INTO V_DISPLAY_NAME
           FROM CMS_BIN_MAST
          WHERE CBM_INST_BIN = P_BIN AND CBM_INST_CODE = P_INST_CODE;
          --T.Narayanan added this block for setting the display name based on the interchange code beg
          IF V_DISPLAY_NAME IS NOT NULL THEN
           IF V_DISPLAY_NAME = 'M' THEN
             V_DISPLAY_NAME := 'INSTANT MASTERCARD';
           ELSIF V_DISPLAY_NAME = 'V' THEN
             V_DISPLAY_NAME := 'INSTANT VISA CARD';
           ELSE
             V_DISPLAY_NAME := 'Stock card for branch ' || P_FIID;
           END IF;
          ELSE
           V_DISPLAY_NAME := 'No Record for the selected Bin';
          END IF; 
  end if;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_DISPLAY_NAME := 'No Record for the selected Bin';
     --T.Narayanan added this block for setting the display name based on the interchange code end
    WHEN OTHERS THEN
     P_ERR_MSG := 'Error while selecting cms_bin_mast ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_EXCEPTION;
  END;
  
  
  
  
  
  
   IF v_encrypt_enable = 'Y' THEN
	 v_encr_firstname := fn_emaps_main(V_DISPLAY_NAME);             
	 v_encr_dummy := fn_emaps_main('*');
   ELSE
     v_encr_firstname := V_DISPLAY_NAME;
	 v_encr_dummy := '*';
  END IF;

   --SN: Modified/Added for VMS-6652
   BEGIN
     SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
  	   INTO v_toggle_value
	   FROM cms_inst_param
      WHERE cip_inst_code = 1
	    AND cip_param_key = 'RETL_GPR_MULTIBIN_TOGGLE';
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       v_toggle_value := 'Y';
   END;  
   --EN: Modified/Added for VMS-6652
   
If V_Pan_Inv_Flag='Y' AND v_toggle_value= 'N'  
Then
 INSERT INTO VMS_STOCK_CAF_INFO_TEMP
       (VSC_FILE_NAME,
        VSC_ROW_ID,
        VSC_INST_CODE,
        VSC_PAN_CODE,
        VSC_CRD_TYP,
        VSC_FIID,
        VSC_SEG12_CARDHOLDER_TITLE,
        VSC_SEG12_OPEN_TEXT1,
        VSC_SEG12_NAME_LINE1,
        VSC_SEG12_NAME_LINE2,
        VSC_SEG12_ADDR_LINE1,
        VSC_SEG12_ADDR_LINE2,
        VSC_SEG12_CITY,
        VSC_SEG12_STATE,
        VSC_SEG12_POSTAL_CODE,
        VSC_SEG12_COUNTRY_CODE,
        VSC_SEG31_TYP,
        VSC_SEG31_STAT,
        VSC_INS_USER,
        VSC_INS_DATE,
        VSC_LUPD_USER,
        VSC_LUPD_DATE,
        VSC_UPLD_STAT,
        VSC_CUST_CATG,
        VSC_PROD_CODE,
        Vsc_Card_Type,
        Vsc_Store_Id,
        VSC_COUNT)
     VALUES
       (V_FILE_NAME,
        SEQ_UPLOAD_ROWID.NEXTVAL,
        P_INST_CODE,
        P_BIN,
        V_PROD_B24,
        P_FIID,
        '*',
        '*',
        V_DISPLAY_NAME,
        '*',
        '*',
        '*',
        '*',
        'GA',
        '*',
        V_CNTRY_CODE,
        '11',
        3,
        P_USER_CODE,
        SYSDATE,
        P_USER_CODE,
        Sysdate,
        'O',
        (SELECT CCC_CATG_CODE
        FROM CMS_CUST_CATG
        Where Ccc_Inst_Code = P_Inst_Code -- ADDED ON 14JAN2013 Missing in queries
        AND   CCC_CATG_SNAME = P_CUST_CATG AND ROWNUM = 1),
        P_PROD_CODE,
        P_Prod_Catg,
        P_Store_Id,
        P_STOCK_CNT);
     COMMIT;
  ELSE
  
  FOR I IN 1 .. P_STOCK_CNT LOOP
    BEGIN
    /* INSERT INTO CMS_CAF_INFO_TEMP
       (CCI_FILE_NAME,
        CCI_ROW_ID,
        CCI_INST_CODE,
        CCI_PAN_CODE,
        CCI_CRD_TYP,
        CCI_FIID,
        CCI_SEG12_CARDHOLDER_TITLE,
        CCI_SEG12_OPEN_TEXT1,
        CCI_SEG12_NAME_LINE1,
        CCI_SEG12_NAME_LINE2,
        CCI_SEG12_ADDR_LINE1,
        CCI_SEG12_ADDR_LINE2,
        CCI_SEG12_CITY,
        CCI_SEG12_STATE,
        CCI_SEG12_POSTAL_CODE,
        CCI_SEG12_COUNTRY_CODE,
        CCI_SEG31_TYP,
        CCI_SEG31_STAT,
        CCI_INS_USER,
        CCI_INS_DATE,
        CCI_LUPD_USER,
        CCI_LUPD_DATE,
        CCI_UPLD_STAT,
        CCI_CUST_CATG,
        CCI_PROD_CODE,
        CCI_CARD_TYPE,
        CCI_STORE_ID)
     VALUES
       (V_FILE_NAME,
        SEQ_UPLOAD_ROWID.NEXTVAL,
        P_INST_CODE,
        P_BIN,
        V_PROD_B24,
        P_FIID,
        '*',
        '*',
       v_encr_firstname,
        v_encr_dummy,
        v_encr_dummy,
        v_encr_dummy,
        v_encr_dummy,
        '',
        v_encr_dummy,
        V_CNTRY_CODE,
        '11',
        3,
        P_USER_CODE,
        SYSDATE,
        P_USER_CODE,
        SYSDATE,
        'B',
        P_CUST_CATG,
        P_PROD_CODE,
        P_PROD_CATG,
        P_STORE_ID);*/
     INSERT INTO CMS_CAF_INFO_TEMP
       (CCI_FILE_NAME,
        CCI_ROW_ID,
        CCI_INST_CODE,
        CCI_PAN_CODE,
        CCI_CRD_TYP,
        CCI_FIID,
        CCI_SEG12_CARDHOLDER_TITLE,
        CCI_SEG12_OPEN_TEXT1,
        CCI_SEG12_NAME_LINE1,
        CCI_SEG12_NAME_LINE2,
        CCI_SEG12_ADDR_LINE1,
        CCI_SEG12_ADDR_LINE2,
        CCI_SEG12_CITY,
        CCI_SEG12_STATE,
        CCI_SEG12_POSTAL_CODE,
        CCI_SEG12_COUNTRY_CODE,
        CCI_SEG31_TYP,
        CCI_SEG31_STAT,
        CCI_INS_USER,
        CCI_INS_DATE,
        CCI_LUPD_USER,
        CCI_LUPD_DATE,
        CCI_UPLD_STAT,
        CCI_CUST_CATG,
        CCI_PROD_CODE,
        CCI_CARD_TYPE,
        CCI_STORE_ID)
     VALUES
       (V_FILE_NAME,
        SEQ_UPLOAD_ROWID.NEXTVAL,
        P_INST_CODE,
        P_BIN,
        V_PROD_B24,
        P_FIID,
        '*',
        '*',
        v_encr_firstname,
        v_encr_dummy,
        v_encr_dummy,
        v_encr_dummy,
        v_encr_dummy,
        'GA',
        v_encr_dummy,
        V_CNTRY_CODE,
        '11',
        3,
        P_USER_CODE,
        SYSDATE,
        P_USER_CODE,
        SYSDATE,
        'B',
        P_CUST_CATG,
        P_PROD_CODE,
        P_PROD_CATG,
        P_STORE_ID);
     COMMIT;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERR_MSG := 'Error while inserting cms_caf_info_temp ' ||
                 SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_EXCEPTION;
    END;
  END LOOP;
  end if;
EXCEPTION
  WHEN EXP_REJECT_EXCEPTION THEN
    ROLLBACK;
  WHEN OTHERS THEN
    P_ERR_MSG := 'Error in main ' || SUBSTR(SQLERRM, 1, 200);
END;
/
show error