CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Issuance_Inventory(	instcode	IN		NUMBER		,
            ROW_ID     IN    VARCHAR2,
				lupduser	IN		NUMBER		,
				errmsg		OUT		VARCHAR2	)
AS


v_cap_cust_code  CMS_APPL_PAN.cap_Cust_code%TYPE;
v_cap_bill_addr  CMS_APPL_PAN.cap_bill_addr%TYPE;
v_gcm_cntry_code		GEN_CNTRY_MAST.gcm_cntry_code%TYPE	;
v_other_addr_code NUMBER(10);


V_CCI_row_id	PCMS_CAF_ISSUANCE_ENTRY.CCI_row_id%TYPE;
V_CCI_INAME	PCMS_CAF_ISSUANCE_ENTRY.CCI_INAME%TYPE;
V_CCI_seg12_name_line1	PCMS_CAF_ISSUANCE_ENTRY.CCI_seg12_name_line1%TYPE;
V_CCI_seg12_name_line2	PCMS_CAF_ISSUANCE_ENTRY.CCI_seg12_name_line2%TYPE;
V_CCI_seg12_addr_line1	PCMS_CAF_ISSUANCE_ENTRY.CCI_seg12_addr_line1%TYPE;
V_CCI_seg12_addr_line2	PCMS_CAF_ISSUANCE_ENTRY.CCI_seg12_addr_line2%TYPE;
V_CCI_seg12_city 	PCMS_CAF_ISSUANCE_ENTRY.CCI_seg12_city %TYPE;
V_CCI_seg12_state	PCMS_CAF_ISSUANCE_ENTRY.CCI_seg12_state%TYPE;
V_CCI_seg12_postal_code	PCMS_CAF_ISSUANCE_ENTRY.CCI_seg12_postal_code%TYPE;
V_CCI_seg12_country_code	PCMS_CAF_ISSUANCE_ENTRY.CCI_seg12_country_code%TYPE;
V_CCI_seg12_open_text1	PCMS_CAF_ISSUANCE_ENTRY.CCI_seg12_open_text1%TYPE;
V_CCI_RMOBILE	PCMS_CAF_ISSUANCE_ENTRY.CCI_RMOBILE%TYPE;
V_CCI_REMAIL	PCMS_CAF_ISSUANCE_ENTRY.CCI_REMAIL%TYPE;
V_CCI_OADDR_LINE1	PCMS_CAF_ISSUANCE_ENTRY.CCI_OADDR_LINE1%TYPE;
V_CCI_OADDR_LINE2	PCMS_CAF_ISSUANCE_ENTRY.CCI_OADDR_LINE2%TYPE;
V_CCI_OCITY	PCMS_CAF_ISSUANCE_ENTRY.CCI_OCITY%TYPE;
V_CCI_OSTATE	PCMS_CAF_ISSUANCE_ENTRY.CCI_OSTATE%TYPE;
V_CCI_OPOSTAL_CODE	PCMS_CAF_ISSUANCE_ENTRY.CCI_OPOSTAL_CODE%TYPE;
V_CCI_OCOUNTRY_CODE	PCMS_CAF_ISSUANCE_ENTRY.CCI_OCOUNTRY_CODE%TYPE;
V_CCI_OPHONE	PCMS_CAF_ISSUANCE_ENTRY.CCI_OPHONE%TYPE;
V_CCI_OMOBILE	PCMS_CAF_ISSUANCE_ENTRY.CCI_OMOBILE%TYPE;
V_CCI_OEMAIL	PCMS_CAF_ISSUANCE_ENTRY.CCI_OEMAIL%TYPE;
V_CCI_SERIAL_NO 	PCMS_CAF_ISSUANCE_ENTRY.CCI_SERIAL_NO %TYPE;
V_CCI_COMM_ADDR	PCMS_CAF_ISSUANCE_ENTRY.CCI_COMM_ADDR%TYPE;
V_CCI_FIID PCMS_CAF_ISSUANCE_ENTRY.CCI_FIID%TYPE;
V_CCI_PAYREF_NO PCMS_CAF_ISSUANCE_ENTRY.CCI_PAYREF_NO%TYPE;
V_CCI_PROD_AMT PCMS_CAF_ISSUANCE_ENTRY.CCI_PROD_AMT%TYPE;
pancode CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
prodcode CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
cardtype CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
custcatg CMS_APPL_PAN.CAP_CUST_CATG%TYPE;
prodsname CMS_PROD_CCC.CPC_PROD_SNAME%TYPE;
brancode CMS_APPL_PAN.CAP_APPL_BRAN%TYPE;

BEGIN		--main begin
errmsg := 'OK';	--initial errmsg status

         SELECT cci_row_id , CCI_INAME,
               cci_seg12_name_line1, cci_seg12_name_line2 , cci_seg12_addr_line1,cci_seg12_addr_line2,cci_seg12_city ,cci_seg12_state,
               cci_seg12_postal_code,cci_seg12_country_code,cci_seg12_open_text1,CCI_RMOBILE, CCI_REMAIL,
               CCI_OADDR_LINE1, CCI_OADDR_LINE2,  CCI_OCITY, CCI_OSTATE, CCI_OPOSTAL_CODE, CCI_OCOUNTRY_CODE,
               CCI_OPHONE, CCI_OMOBILE, CCI_OEMAIL,
               CCI_SERIAL_NO , CCI_COMM_ADDR, CCI_FIID, CCI_PAYREF_NO, CCI_PROD_AMT
         INTO  V_CCI_row_id	,V_CCI_INAME, V_CCI_seg12_name_line1, V_CCI_seg12_name_line2,
               V_CCI_seg12_addr_line1, V_CCI_seg12_addr_line2	, V_CCI_seg12_city ,V_CCI_seg12_state,
               V_CCI_seg12_postal_code	, V_CCI_seg12_country_code, V_CCI_seg12_open_text1, V_CCI_RMOBILE,
               V_CCI_REMAIL, V_CCI_OADDR_LINE1	, V_CCI_OADDR_LINE2	,V_CCI_OCITY	,V_CCI_OSTATE	,
               V_CCI_OPOSTAL_CODE	,V_CCI_OCOUNTRY_CODE	,V_CCI_OPHONE	,V_CCI_OMOBILE	,V_CCI_OEMAIL	,
               V_CCI_SERIAL_NO ,V_CCI_COMM_ADDR, V_CCI_FIID, V_CCI_PAYREF_NO, V_CCI_PROD_AMT
         FROM		PCMS_CAF_ISSUANCE_ENTRY
         WHERE		CCI_ROW_ID		= ROW_ID;


         BEGIN  --cntry
               SELECT gcm_cntry_code
               INTO	v_gcm_cntry_code
               FROM	GEN_CNTRY_MAST
               WHERE	gcm_curr_code	=	v_cci_seg12_country_code;
         EXCEPTION WHEN OTHERS THEN
            errmsg := ' Excp cntry -- '||SQLERRM;
         END;

         IF errmsg = 'OK' THEN

            BEGIN
                  SELECT cap_bill_addr, cap_cust_code  ,cap_pan_code,cap_prod_code,cap_card_type,cap_cust_catg,cap_appl_bran
                  INTO v_cap_bill_addr, v_cap_cust_code,pancode,prodcode,cardtype,custcatg,brancode
                  FROM CMS_APPL_PAN
                  WHERE cap_appl_code = v_cci_serial_no;
            EXCEPTION WHEN OTHERS THEN
               errmsg := ' Excp appl -- '||SQLERRM;
            END;
         END IF;

         IF errmsg = 'OK' THEN
            BEGIN
                  SELECT cam_addr_code INTO v_other_addr_code
                  FROM CMS_ADDR_MAST
                  WHERE cam_inst_code = instcode
                  AND cam_cust_code = v_cap_cust_code
                  AND cam_addr_code != v_cap_bill_addr;

            EXCEPTION WHEN OTHERS THEN
               errmsg := ' Excp other addr  -- '||SQLERRM;
            END;
         END IF;

         IF errmsg = 'OK' THEN
         BEGIN
               IF v_cci_COMM_ADDR = '0' THEN
                  -- Residence address is communication address

                     UPDATE CMS_ADDR_MAST
                     SET
                     CAM_ADD_ONE = v_cci_seg12_addr_line1,
                     CAM_ADD_TWO = v_cci_seg12_addr_line2,
                     --CAM_ADD_THREE = v_cci_seg12_name_line2,
                     CAM_PIN_CODE = v_cci_seg12_postal_code,
                     CAM_PHONE_ONE = v_cci_seg12_open_text1,
                     CAM_PHONE_TWO = v_cci_rmobile ,
                     CAM_EMAIL = v_cci_remail,
                     CAM_CNTRY_CODE = v_gcm_cntry_code,
                     CAM_CITY_NAME=		v_cci_seg12_city,
                     CAM_STATE_SWITCH=		v_cci_seg12_state
                     WHERE cam_inst_code = instcode
                     AND  cam_addr_code = v_cap_bill_addr;

                        dbms_output.put_line('v_other_addr_code-'||v_other_addr_code);
                     --Office Address

                     IF v_cci_OADDR_LINE1 != NULL THEN
                        UPDATE CMS_ADDR_MAST
                        SET
                        CAM_ADD_ONE = v_cci_OADDR_LINE1,
                        CAM_ADD_TWO = v_cci_OADDR_LINE2,
                        --CAM_ADD_THREE = v_cci_seg12_name_line2,
                        CAM_PIN_CODE = v_cci_opostal_code,
                        CAM_PHONE_ONE = v_cci_ophone,
                        CAM_PHONE_TWO = v_cci_omobile ,
                        CAM_EMAIL = v_cci_oemail,
                        CAM_CNTRY_CODE = v_gcm_cntry_code,
                        CAM_CITY_NAME=		v_cci_ocity,
                        CAM_STATE_SWITCH=		v_cci_ostate
                        WHERE cam_inst_code = instcode
                        AND  cam_addr_code = v_other_addr_code;
                     END IF;

               ELSE
                  -- Office address is communication address
                   --  IF v_cci_OADDR_LINE1 != NULL THEN
                        UPDATE CMS_ADDR_MAST
                        SET
                        CAM_ADD_ONE = v_cci_OADDR_LINE1,
                        CAM_ADD_TWO = v_cci_OADDR_LINE2,
                        --CAM_ADD_THREE = v_cci_seg12_name_line2,
                        CAM_PIN_CODE = v_cci_opostal_code,
                        CAM_PHONE_ONE = v_cci_ophone,
                        CAM_PHONE_TWO = v_cci_omobile ,
                        CAM_EMAIL = v_cci_oemail,
                        CAM_CNTRY_CODE = v_gcm_cntry_code,
                        CAM_CITY_NAME=		v_cci_ocity,
                        CAM_STATE_SWITCH=		v_cci_ostate
                        WHERE cam_inst_code = instcode
                        AND cam_addr_code = v_cap_bill_addr;
                    -- END IF;

                     dbms_output.put_line('errmsg - ');

                  IF v_cci_seg12_addr_line1 != NULL THEN
                     --Residence Address
                     UPDATE CMS_ADDR_MAST
                     SET
                     CAM_ADD_ONE = v_cci_seg12_addr_line1,
                     CAM_ADD_TWO = v_cci_seg12_addr_line2,
                     --CAM_ADD_THREE = v_cci_seg12_name_line2,
                     CAM_PIN_CODE = v_cci_seg12_postal_code,
                     CAM_PHONE_ONE = v_cci_seg12_open_text1,
                     CAM_PHONE_TWO = v_cci_rmobile ,
                     CAM_EMAIL = v_cci_remail,
                     CAM_CNTRY_CODE = v_gcm_cntry_code,
                     CAM_CITY_NAME=		v_cci_seg12_city,
                     CAM_STATE_SWITCH=		v_cci_seg12_state
                     WHERE cam_inst_code = instcode
                     AND cam_addr_code = v_other_addr_code;
                  END IF;

               END IF;
         EXCEPTION WHEN OTHERS THEN
            errmsg := 'Excp Addr-- '||SQLERRM;
         END;
         END IF;

         IF errmsg = 'OK' THEN
            BEGIN
               UPDATE CMS_CUST_MAST
               SET CCM_FIRST_NAME = v_cci_INAME
               WHERE ccm_inst_code = instcode
               AND ccm_cust_Code = v_cap_cust_code;
            EXCEPTION WHEN OTHERS THEN
               errmsg := 'Excp Cust-- '||SQLERRM;
            END;
         END IF;

		 IF errmsg = 'OK' THEN
		 		   Sp_Ins_Pcmsreqhost(
               NULL,
               NULL,
               V_CCI_FIID,
               V_CCI_PAYREF_NO,
               NULL,
               NULL,
               V_CCI_PROD_AMT,
               NULL,
               NULL,
               NULL,
               'N',
               NULL,
               NULL,
               'IW',
               V_CCI_SERIAL_NO,
               NULL,
               'P',
               lupduser,
               ERRMSG);
		 END IF;

         IF errmsg = 'OK' THEN
            UPDATE PCMS_CAF_ISSUANCE_ENTRY
            SET cci_upld_stat = 'O'
            WHERE cci_row_id = v_cci_row_id;

            UPDATE CMS_APPL_PAN SET
            cap_disp_name = V_CCI_seg12_name_line1,
            cap_issue_flag = 'Y'
            WHERE cap_appl_code = v_cci_SERIAL_NO
            AND cap_issue_flag = 'L';

			UPDATE CMS_ACCT_MAST
               SET
                   cam_acct_bal = cam_acct_bal + V_CCI_PROD_AMT
             WHERE cam_inst_code = 1 AND cam_acct_no = pancode;

			 SELECT cpc_prod_sname INTO prodsname
			 FROM CMS_PROD_CCC
			 WHERE cpc_prod_code = prodcode
			 AND cpc_card_type = cardtype
			 AND cpc_cust_catg = custcatg;

			 UPDATE CMS_BRANPROD_STOCK
			 SET cbs_stock = cbs_stock -1
			 WHERE cbs_prod_sname = prodsname
			 AND cbs_bran_code =brancode;

         ELSE
            INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
										CEL_FILE_NAME  ,
										CEL_ROW_ID     ,
										CEL_ERROR_MESG ,
										CEL_LUPD_USER  ,
										CEL_LUPD_DATE  ,
										CEL_PROB_ACTION	)
								VALUES	(	instcode	,
										' '	,
										SUBSTR(v_cci_row_id,1,5)	,
										errmsg		,
										lupduser	,
										SYSDATE		,
										'Contact Site Administrator');

            UPDATE PCMS_CAF_ISSUANCE_ENTRY
            SET cci_upld_stat = 'E'
            WHERE cci_row_id = v_cci_row_id;
         END IF;


EXCEPTION	--excp main
WHEN OTHERS THEN
NULL;
errmsg := 'Main Excp -- '||SQLERRM;
END;		--end mai
/


