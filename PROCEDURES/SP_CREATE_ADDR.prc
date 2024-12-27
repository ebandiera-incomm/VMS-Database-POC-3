CREATE OR REPLACE PROCEDURE VMSCMS.SP_CREATE_ADDR(PRM_INSTCODE     IN NUMBER,
								   PRM_CUSTCODE     IN NUMBER,
								   PRM_ADD1         IN VARCHAR2,
								   PRM_ADD2         IN VARCHAR2,
								   PRM_ADD3         IN VARCHAR2,
								   PRM_PINCODE      IN VARCHAR2,
								   PRM_PHON1        IN VARCHAR2,
								   PRM_PHON2        IN VARCHAR2,
								   PRM_OFFICNO      IN VARCHAR2,
								   PRM_EMAIL        IN VARCHAR2,
								   PRM_CNTRYCODE    IN NUMBER,
								   PRM_CITYNAME     IN VARCHAR2,
								   PRM_SWITCHSTAT   IN VARCHAR2, --state as coming from switch
								   PRM_FAX1         IN VARCHAR2,
								   PRM_ADDRFLAG     IN CHAR,
								   PRM_COMM_TYPE    IN CHAR,
								   PRM_LUPDUSER     IN NUMBER,
								   PRM_GENADDR_DATA IN TYPE_ADDR_REC_ARRAY,
								   PRM_ADDRCODE     OUT NUMBER,
								   PRM_ERRMSG       OUT VARCHAR2) AS

/*************************************************

     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01
     
     
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


  V_ADDRREC_OUTDATA    TYPE_ADDR_REC_ARRAY;
  V_SETADDRDATA_ERRMSG CMS_CAF_INFO_ENTRY.CCI_PROCESS_MSG%TYPE;
  V_STATE_SWITCH_CODE  GEN_STATE_MAST.GSM_SWITCH_STATE_CODE%TYPE;
  V_STATE_CODE         GEN_STATE_MAST.GSM_STATE_CODE%TYPE;
  v_encrypt_enable     cms_prod_cattype.cpc_encrypt_enable%type;

    V_ENCR_ADD_ONE   	CMS_ADDR_MAST.CAM_ADD_ONE%TYPE;
	V_ENCR_ADD_TWO      CMS_ADDR_MAST.CAM_ADD_TWO%TYPE;
	V_ENCR_ADD_THREE    CMS_ADDR_MAST.CAM_ADD_THREE%TYPE;
	V_ENCR_PIN_CODE     CMS_ADDR_MAST.CAM_PIN_CODE%TYPE;
	V_ENCR_PHONE_ONE    CMS_ADDR_MAST.CAM_PHONE_ONE%TYPE;
	V_ENCR_MOBL_ONE     CMS_ADDR_MAST.CAM_MOBL_ONE%TYPE;
	V_ENCR_EMAIL		CMS_ADDR_MAST.CAM_EMAIL%TYPE;
	V_ENCR_CITY_NAME	CMS_ADDR_MAST.CAM_CITY_NAME%TYPE;


BEGIN
  --Main Begin Block Starts Here
  --this if condition commented on 20-06-02 to take in the incoming data in caf format for finacle
  --IF prm_instcode IS NOT NULL AND prm_custcode IS NOT NULL AND prm_add1 IS NOT NULL AND prm_pincode IS NOT NULL AND prm_cntrycode IS NOT NULL AND prm_cityname IS NOT NULL AND prm_lupduser IS NOT NULL THEN
  --IF 1
  PRM_ERRMSG := 'OK';

  SELECT SEQ_ADDR_CODE.NEXTVAL INTO PRM_ADDRCODE FROM DUAL;

  -- Sn to get the encrypt enable flag status
  BEGIN

        select prod_catt.cpc_encrypt_enable
        into v_encrypt_enable
        from cms_prod_cattype prod_catt,(select ccm_prod_code,ccm_card_type from cms_cust_mast
                                  where ccm_cust_code = PRM_CUSTCODE and ccm_inst_code = PRM_INSTCODE)cust_mast
        where prod_catt.cpc_prod_code = cust_mast.ccm_prod_code
        and prod_catt.cpc_card_type = cust_mast.ccm_card_type
        and prod_catt.cpc_inst_code = PRM_INSTCODE;

  EXCEPTION
   WHEN OTHERS THEN
	 PRM_ERRMSG := 'Error while creating address ' ||
				SUBSTR(SQLERRM, 1, 200);


  END;
  --Sn set the generic variable
  SP_SET_GEN_ADDRDATA(PRM_INSTCODE,
				  PRM_GENADDR_DATA,
				  V_ADDRREC_OUTDATA,
				  V_SETADDRDATA_ERRMSG);

          dbms_output.put_line('SP_CREATE_ADDR : V_ADDRREC_OUTDATA:---->'||V_SETADDRDATA_ERRMSG);

  IF V_SETADDRDATA_ERRMSG <> 'OK' THEN
    PRM_ERRMSG := 'Error in set gen parameters   ' || V_SETADDRDATA_ERRMSG;
    RETURN;
  END IF;
  --En set the generic variable
  --Sn ger state and switch code
  SN_GET_STATE_CODE(PRM_INSTCODE,
				PRM_SWITCHSTAT,
				PRM_CNTRYCODE,
				V_STATE_CODE,
				V_STATE_SWITCH_CODE,
				PRM_ERRMSG);
  IF PRM_ERRMSG <> 'OK' THEN
    DBMS_OUTPUT.PUT_LINE('sn_get_state_code :::: prm_errmsg :----->(' ||
					PRM_ERRMSG || ')');
    RETURN;
  END IF;

  --En get state and switch code


  IF V_ENCRYPT_ENABLE = 'Y' THEN
      V_ENCR_ADD_ONE:=fn_emaps_main(PRM_ADD1);
	  V_ENCR_ADD_TWO:=fn_emaps_main(PRM_ADD2);
	  V_ENCR_ADD_THREE:=fn_emaps_main(PRM_ADD3);
	  V_ENCR_PIN_CODE:=fn_emaps_main(PRM_PINCODE);
	  V_ENCR_PHONE_ONE:=fn_emaps_main(PRM_PHON1);
	  V_ENCR_MOBL_ONE:=fn_emaps_main(PRM_PHON2);
	  V_ENCR_EMAIL:=fn_emaps_main(PRM_EMAIL);
	  V_ENCR_CITY_NAME:=fn_emaps_main(PRM_CITYNAME);

     ELSE
	  V_ENCR_ADD_ONE:=PRM_ADD1;
	  V_ENCR_ADD_TWO:=PRM_ADD2;
	  V_ENCR_ADD_THREE:=PRM_ADD3;
	  V_ENCR_PIN_CODE:=PRM_PINCODE;
	  V_ENCR_PHONE_ONE:=PRM_PHON1;
	  V_ENCR_MOBL_ONE:=PRM_PHON2;
	  V_ENCR_EMAIL:=PRM_EMAIL;
	  V_ENCR_CITY_NAME:=PRM_CITYNAME;

   END IF;


  BEGIN

  

    INSERT INTO CMS_ADDR_MAST
	 (CAM_INST_CODE,
	  CAM_CUST_CODE,
	  CAM_ADDR_CODE,
	  CAM_ADD_ONE,
	  CAM_ADD_TWO,
	  CAM_ADD_THREE,
	  CAM_PIN_CODE,
	  CAM_PHONE_ONE,
	  CAM_PHONE_TWO,
	  CAM_MOBL_ONE,
	  CAM_EMAIL,
	  CAM_CNTRY_CODE,
	  CAM_CITY_NAME,
	  CAM_FAX_ONE,
	  CAM_ADDR_FLAG,
	  CAM_STATE_CODE,
	  CAM_INS_USER,
	  CAM_LUPD_USER,
	  CAM_COMM_TYPE,
	  CAM_STATE_SWITCH,
	  CAM_ADDRMAST_PARAM1,
	  CAM_ADDRMAST_PARAM2,
	  CAM_ADDRMAST_PARAM3,
	  CAM_ADDRMAST_PARAM4,
	  CAM_ADDRMAST_PARAM5,
	  CAM_ADDRMAST_PARAM6,
	  CAM_ADDRMAST_PARAM7,
	  CAM_ADDRMAST_PARAM8,
	  CAM_ADDRMAST_PARAM9,
	  CAM_ADDRMAST_PARAM10,
      CAM_ADD_ONE_ENCR,
      CAM_ADD_TWO_ENCR,
      CAM_CITY_NAME_ENCR,
      CAM_PIN_CODE_ENCR,
      CAM_EMAIL_ENCR)
    VALUES
	 (PRM_INSTCODE,
	  PRM_CUSTCODE,
	  PRM_ADDRCODE,
	  V_ENCR_ADD_ONE,
	  V_ENCR_ADD_TWO,
	  V_ENCR_ADD_THREE,
	  V_ENCR_PIN_CODE,
	  V_ENCR_PHONE_ONE,
	  PRM_OFFICNO,
	  V_ENCR_MOBL_ONE,
	  V_ENCR_EMAIL,
	  PRM_CNTRYCODE,
	  V_ENCR_CITY_NAME,
	  PRM_FAX1,
	  PRM_ADDRFLAG,
	  V_STATE_CODE,
	  PRM_LUPDUSER,
	  PRM_LUPDUSER,
	  PRM_COMM_TYPE,
	  V_STATE_SWITCH_CODE,
	  V_ADDRREC_OUTDATA(1),
	  V_ADDRREC_OUTDATA(2),
	  V_ADDRREC_OUTDATA(3),
	  V_ADDRREC_OUTDATA(4),
	  V_ADDRREC_OUTDATA(5),
	  V_ADDRREC_OUTDATA(6),
	  V_ADDRREC_OUTDATA(7),
	  V_ADDRREC_OUTDATA(8),
	  V_ADDRREC_OUTDATA(9),
	  V_ADDRREC_OUTDATA(10),
      fn_emaps_main(PRM_ADD1),
      fn_emaps_main(PRM_ADD2),
      fn_emaps_main(PRM_CITYNAME),
      fn_emaps_main(PRM_PINCODE),
      fn_emaps_main(PRM_EMAIL)
      );
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
	 PRM_ERRMSG := 'Error while creating address duplicate record found';
	 RETURN;
    WHEN OTHERS THEN
	 PRM_ERRMSG := 'Error while creating address ' ||
				SUBSTR(SQLERRM, 1, 200);
	 RETURN;

  END;
  
  IF PRM_ADDRFLAG = 'P' AND (PRM_ADD1 IS NOT NULL AND PRM_ADD1 <> '*') THEN
	  UPDATE CMS_CUST_MAST
						SET CCM_SYSTEM_GENERATED_PROFILE = 'N' 
						WHERE CCM_INST_CODE = PRM_INSTCODE                      
						AND CCM_CUST_CODE = PRM_CUSTCODE ;
  ELSE
		UPDATE CMS_CUST_MAST
						SET CCM_SYSTEM_GENERATED_PROFILE = 'Y' 
						WHERE CCM_INST_CODE = PRM_INSTCODE                      
						AND CCM_CUST_CODE = PRM_CUSTCODE ;
  END IF;

EXCEPTION
  --Main block Exception
  WHEN OTHERS THEN
    PRM_ERRMSG := 'Main exexption ' || SQLCODE || '---' ||
			   SUBSTR(SQLERRM, 1, 200);

END; --Main Begin Block Ends Here
/
show error



