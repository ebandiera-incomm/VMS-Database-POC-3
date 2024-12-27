CREATE OR REPLACE PROCEDURE VMSCMS.sp_upd_delinkacct(instcode IN VARCHAR2,
                     rsncode IN NUMBER,
					      lupduser IN VARCHAR2,
					      errmsg  OUT  VARCHAR2) AS
v_mbrnumb VARCHAR2(3);
v_remark  CMS_PAN_SPPRT.cps_func_remark%TYPE;
v_cap_cafgen_flag CMS_APPL_PAN.cap_cafgen_flag%TYPE;
v_cam_acct_id CMS_ACCT_MAST.cam_acct_id%TYPE;
v_cap_cust_code CMS_APPL_PAN.CAP_CUST_CODE%TYPE;
v_cca_rel_stat CMS_CUST_ACCT.CCA_REL_STAT%TYPE ;
v_cap_acct_no     CMS_APPL_PAN.CAP_ACCT_NO%TYPE; -- Ashwini 16 Feb 05 - For reports
v_cap_disp_name   CMS_APPL_PAN.CAP_DISP_NAME%TYPE; -- Ashwini 16 Feb 05 - For reports
dum  NUMBER;
holdposn NUMBER;
 workmode NUMBER; -- For FHM


CURSOR c1 IS SELECT CDA_PAN_CODE, CDA_ACCT_NO ,
                    CDA_DONE_FLAG, CDA_PROCESS_DATE ,CDA_PROCESS_RESULT
	      FROM  CMS_DELINK_ACCT
	      WHERE CDA_DONE_FLAG = 'P';

BEGIN --BEGIN 1.1

v_mbrnumb := '000';
v_remark := 'DeLink Acct through upload';
workmode := 0;  -- OffLine  For FHM
	errmsg := 'OK';
	FOR X IN c1
		LOOP
		   BEGIN  --begin 1.2
            errmsg := 'OK';
            BEGIN -- 1.3
               SELECT  cap_cafgen_flag, CAP_CUST_CODE, CAP_ACCT_NO, CAP_DISP_NAME
               INTO v_cap_cafgen_flag, v_cap_cust_code, v_cap_acct_no, v_cap_disp_name
               FROM CMS_APPL_PAN
               WHERE CAP_PAN_CODE = X.CDA_PAN_CODE AND
               CAP_MBR_NUMB = v_mbrnumb ;
               EXCEPTION	--excp of begin 1.3
               WHEN NO_DATA_FOUND THEN
                  errmsg := 'No such PAN found.';
               WHEN OTHERS THEN
                  errmsg := 'Excp 1.3 -- '||SQLERRM;
            END; --1.3

            IF errmsg = 'OK' THEN
               UPDATE CMS_DELINK_ACCT
               SET CDA_OLD_PRIMARY_ACCT = v_cap_acct_no,  --Ashwini 16 Feb 05 For Reports
                   CDA_CARD_NAME = v_cap_disp_name --Ashwini 16 Feb 05 For Reports
               WHERE CDA_PAN_CODE = X.CDA_PAN_CODE
               AND CDA_DONE_FLAG = 'P';
            END IF;

            IF errmsg = 'OK' AND v_cap_cafgen_flag = 'N' THEN	--cafgen if
					errmsg := 'CAF has to be generated atleast once for this pan';
			END IF;

            IF ERRMSG = 'OK' THEN

               BEGIN -- 1.4
                  SELECT  cam_acct_id
                  INTO v_cam_acct_id
                  FROM CMS_ACCT_MAST
                  WHERE
				  CAM_INST_CODE = 1 AND
				  CAM_ACCT_NO = X.CDA_ACCT_NO;

                  EXCEPTION	--excp of begin 1.4
                  WHEN NO_DATA_FOUND THEN
                     errmsg := 'No such Account found.';
                  WHEN OTHERS THEN
                     errmsg := 'Excp 1.4 -- '||SQLERRM;
               END; -- 1.4
            END IF;

            IF ERRMSG = 'OK' THEN
               BEGIN --1.2.1
                  SP_DELINK_ACCT (	instcode	,
                                    v_cam_acct_id,
                                    X.CDA_PAN_CODE,
                                    NULL,
                                    rsncode,
                                    v_remark,
                                    lupduser,
                                    workmode, --For FHM
                                    errmsg		);

               -- For updating the new primary acct linked to the pan
               SELECT  CAP_ACCT_NO
               INTO  v_cap_acct_no
               FROM CMS_APPL_PAN
               WHERE CAP_PAN_CODE = X.CDA_PAN_CODE AND
                     CAP_MBR_NUMB = v_mbrnumb ;

               UPDATE CMS_DELINK_ACCT
               SET CDA_PRIMARY_ACCT_NO = v_cap_acct_no
               WHERE CDA_PAN_CODE = X.CDA_PAN_CODE
               AND CDA_DONE_FLAG = 'P';

               IF errmsg != 'OK' THEN
                  errmsg := 'From SP_DELINK_ACCT '||errmsg;
               ELSE
                  UPDATE CMS_DELINK_ACCT
                     SET CDA_DONE_FLAG = 'Y',
                     CDA_PROCESS_RESULT = 'Acct DeLinked Successfully'
                     WHERE CDA_PAN_CODE = X.CDA_PAN_CODE
                     AND CDA_DONE_FLAG = 'P';
               END IF;
               END; --1.2.1
				END IF;


            IF ERRMSG != 'OK' THEN
                  UPDATE CMS_DELINK_ACCT
                     SET CDA_PROCESS_RESULT = errmsg,
                         CDA_DONE_FLAG = 'E'
                     WHERE CDA_PAN_CODE = X.CDA_PAN_CODE
                     AND CDA_DONE_FLAG = 'P';
            END IF;



            END;  --end 1.2
		END LOOP;

      errmsg := 'OK';
      EXCEPTION	--excp of begin 1.2
				WHEN OTHERS THEN
            errmsg := 'Excp 1.1 '||SQLERRM;
END;--END 1.1
/


