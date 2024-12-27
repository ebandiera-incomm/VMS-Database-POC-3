CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Upd_Linkacct(instcode IN VARCHAR2,
                     rsncode IN NUMBER,
					      lupduser IN VARCHAR2,
					      errmsg  OUT  VARCHAR2) AS
v_mbrnumb VARCHAR2(3);
v_remark          CMS_PAN_SPPRT.cps_func_remark%TYPE;
v_cap_cafgen_flag CMS_APPL_PAN.cap_cafgen_flag%TYPE;
v_cam_acct_id     CMS_ACCT_MAST.cam_acct_id%TYPE;
v_cap_cust_code   CMS_APPL_PAN.CAP_CUST_CODE%TYPE;
v_cca_rel_stat    CMS_CUST_ACCT.CCA_REL_STAT%TYPE ;
v_cap_acct_no     CMS_APPL_PAN.CAP_ACCT_NO%TYPE; -- Ashwini 15 Feb 05 - For reports
v_cap_disp_name   CMS_APPL_PAN.CAP_DISP_NAME%TYPE; -- Ashwini 15 Feb 05 - For reports
dum  NUMBER;
holdposn NUMBER;
 workmode NUMBER; -- For FHM
 v_acct_posn varchar2(5);

CURSOR c1 IS SELECT CLA_PAN_CODE, CLA_NEW_ACCT_NO ,
                    CLA_DONE_FLAG, CLA_PROCESS_DATE ,CLA_PROCESS_RESULT
	      FROM  CMS_LINK_ACCT
	      WHERE CLA_DONE_FLAG = 'P';

BEGIN --BEGIN 1.1

v_mbrnumb := '000';
v_remark := 'Link Acct through upload';
--workmode := 0;  -- OffLine  For FHM
	errmsg := 'OK';
	FOR X IN c1
		LOOP
		   BEGIN  --begin 1.2
            errmsg := 'OK';
            BEGIN -- 1.3
               SELECT  cap_cafgen_flag, CAP_CUST_CODE , CAP_ACCT_NO, CAP_DISP_NAME -- Ashwini 15 feb 05 - taking acct no & disp name for reports
               INTO v_cap_cafgen_flag, v_cap_cust_code, v_cap_acct_no, v_cap_disp_name
               FROM CMS_APPL_PAN
               WHERE CAP_PAN_CODE = X.CLA_PAN_CODE AND
               CAP_MBR_NUMB = v_mbrnumb
			   AND cap_card_stat = '1'; -- added by shyamjith 04jul05
               EXCEPTION	--excp of begin 1.3
               WHEN NO_DATA_FOUND THEN
                  errmsg := 'No such active PAN found.';
               WHEN OTHERS THEN
                  errmsg := 'Excp 1.3 -- '||SQLERRM;
            END; --1.3

            IF errmsg = 'OK' THEN
               UPDATE CMS_LINK_ACCT
               SET CLA_PRIMARY_ACCT_NO = v_cap_acct_no,  --Ashwini 15 Feb 05 For Reports
                   CLA_CARD_NAME = v_cap_disp_name --Ashwini 15 Feb 05 For Reports
               WHERE CLA_PAN_CODE = X.CLA_PAN_CODE
               AND CLA_DONE_FLAG = 'P';
            END IF;

            IF errmsg = 'OK' AND v_cap_cafgen_flag = 'N' THEN	--cafgen if
					errmsg := 'CAF has to be generated atleast once for this pan';
			END IF;

         --dbms_output.put_line(' '||X.CLA_PAN_CODE||'  ->'||v_cap_acct_no||'   '||v_cap_disp_name);

            IF ERRMSG = 'OK' THEN

               BEGIN -- 1.4
                  SELECT  cam_acct_id
                  INTO v_cam_acct_id
                  FROM CMS_ACCT_MAST
                  WHERE
				  CAM_INST_CODE = 1 AND
				  CAM_ACCT_NO = X.CLA_NEW_ACCT_NO;

                  EXCEPTION	--excp of begin 1.4
                  WHEN NO_DATA_FOUND THEN
                     errmsg := 'No such Account found.';
                  WHEN OTHERS THEN
                     errmsg := 'Excp 1.4 -- '||SQLERRM;
               END; -- 1.4
            END IF;

            IF ERRMSG = 'OK' THEN
               BEGIN -- 1.5
                  SELECT CCA_REL_STAT
                  INTO v_cca_rel_stat
                  FROM CMS_CUST_ACCT
                  WHERE cca_cust_code = v_cap_cust_code
                  AND cca_acct_id = v_cam_acct_id ;
                  --and cca_rel_stat = 'Y';

				  IF v_cca_rel_stat = 'N' THEN
				  	 ERRMSG := 'CUST_ACCT RELATION SHIP IS CLOSED' ;
				  END IF  ;
                  /*IF dum = 0 THEN
                     sp_create_holder(1,v_cap_cust_code,v_cam_acct_id,null,1,holdposn,errmsg);
                     if errmsg != 'OK' then
                        errmsg := 'From sp_create_holder - '||errmsg;
                     end if;
                  END IF;*/
                  EXCEPTION	--excp of begin 1.5
				  WHEN NO_DATA_FOUND THEN
				      UPDATE CMS_ACCT_MAST
					  SET CAM_HOLD_COUNT = CAM_HOLD_COUNT + 1
					  WHERE CAM_INST_CODE = 1 AND
					  CAM_ACCT_ID = v_cam_acct_id ;

    				  Sp_Create_Holder(1,v_cap_cust_code,v_cam_acct_id,NULL,1,holdposn,errmsg);

                     IF errmsg != 'OK' THEN
                        errmsg := 'From sp_create_holder - '||errmsg;
                     END IF;
                  WHEN OTHERS THEN
                     errmsg := 'Excp 1.5 -- '||SQLERRM;
                  END; -- 1.5
            END IF;

				IF ERRMSG = 'OK' THEN
               BEGIN --1.2.1

                --dbms_output.put_line(' b4 sp_link_acct '||X.CLA_PAN_CODE);


                --dbms_output.put_line ('pan-'||X.CLA_PAN_CODE||'  acct id-'||v_cam_acct_id||'  rsncode-'||rsncode);
                  Sp_Link_Acct  (	instcode,
												X.CLA_PAN_CODE ,
												NULL,
												v_cam_acct_id,
												rsncode,
												v_remark,
												lupduser,
                                    workmode, --For FHM,
                                                v_acct_posn,--acct position
												errmsg);

               dbms_output.put_line('pan-'||X.CLA_PAN_CODE|| '  after sp_link errmsg ->'||errmsg);

               IF errmsg != 'OK' THEN
                  errmsg := 'From SP_LINK_ACCT '||errmsg;
               ELSE
                  UPDATE CMS_LINK_ACCT
                     SET CLA_DONE_FLAG = 'Y',
                     CLA_PROCESS_RESULT = 'Acct Linked Successfully'
                     WHERE CLA_PAN_CODE = X.CLA_PAN_CODE
                     AND CLA_DONE_FLAG = 'P';
               END IF;
               END; --1.2.1
				END IF;


            IF ERRMSG != 'OK' THEN
                  UPDATE CMS_LINK_ACCT
                     SET CLA_PROCESS_RESULT = errmsg,
                         CLA_DONE_FLAG = 'E'
                     WHERE CLA_PAN_CODE = X.CLA_PAN_CODE
                     AND CLA_DONE_FLAG = 'P';
            END IF;
            END;  --end 1.2
		END LOOP;

      errmsg := 'OK';
      EXCEPTION	--excp of begin 1.2
				WHEN OTHERS THEN
            errmsg := 'Excp 1.1 '||SQLERRM;
END;--END 1.1
/


