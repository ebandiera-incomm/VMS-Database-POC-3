CREATE OR REPLACE PROCEDURE VMSCMS.sp_upd_limits(instcode IN VARCHAR2,
                     rsncode IN NUMBER,
					      lupduser IN VARCHAR2,
					      errmsg  OUT  VARCHAR2) AS
v_mbrnumb VARCHAR2(3);
v_remark  CMS_PAN_SPPRT.cps_func_remark%TYPE;
v_cap_cafgen_flag CMS_APPL_PAN.cap_cafgen_flag%TYPE;

v_cap_atmOnline_lmt CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
v_cap_posOnline_lmt CMS_APPL_PAN.CAP_POS_ONLINE_LIMIT%TYPE;

dum  NUMBER;


CURSOR c1 IS SELECT CUC_PAN_CODE, CUC_NEWATM_LIMIT ,
		    CUC_NEWPOS_LIMIT, CUC_DONE_FLAG ,
		    CUC_PROCESS_DATE ,CUC_PROCESS_RESULT
	      FROM  CMS_UPDATE_CRDLIMITS
	      WHERE CUC_DONE_FLAG = 'P';

BEGIN --BEGIN 1.1

v_mbrnumb := '000';
v_remark := 'Update Limits through upload';
	errmsg := 'OK';
	FOR X IN c1
		LOOP
		   BEGIN  --begin 1.2
            errmsg := 'OK';
            BEGIN -- 1.3
               SELECT  cap_cafgen_flag
               INTO v_cap_cafgen_flag
               FROM CMS_APPL_PAN
               WHERE CAP_PAN_CODE = X.CUC_PAN_CODE AND
               CAP_MBR_NUMB = v_mbrnumb ;
               EXCEPTION	--excp of begin 1.2
               WHEN NO_DATA_FOUND THEN
                  errmsg := 'No such PAN found.';
               WHEN OTHERS THEN
                  errmsg := 'Excp 1.2 -- '||SQLERRM;
            END;

               dbms_output.put_line('errmsg '||errmsg);


				IF errmsg = 'OK' AND v_cap_cafgen_flag = 'N' THEN	--cafgen if
					errmsg := 'CAF has to be generated atleast once for this pan';
				END IF;


				IF ERRMSG = 'OK' THEN
               	BEGIN -- NUBEGIN1
			   		SELECT  CAP_ATM_ONLINE_LIMIT,CAP_POS_ONLINE_LIMIT
               		INTO v_cap_atmOnline_lmt, v_cap_posOnline_lmt
					FROM CMS_APPL_PAN
               		WHERE CAP_PAN_CODE = X.CUC_PAN_CODE AND
               		CAP_MBR_NUMB = v_mbrnumb ;
					EXCEPTION
			   WHEN NO_DATA_FOUND THEN
                  errmsg := 'No such data found.';
               WHEN OTHERS THEN
                  errmsg := 'Excp 1.2 -- '||SQLERRM;
				 END; -- END NUBEGIN1
				 END IF;


						IF ERRMSG = 'OK' THEN
						   BEGIN
							sp_update_limits ( instcode,X.CUC_PAN_CODE,
							v_mbrnumb,
							v_remark,
							rsncode	,
							X.CUC_NEWATM_LIMIT,
							X.CUC_NEWATM_LIMIT,
							X.CUC_NEWPOS_LIMIT,
							X.CUC_NEWPOS_LIMIT,
							lupduser,
							'U', -- to indicate the update has happended through the upload procedure
							errmsg);
							IF errmsg != 'OK' THEN
                  			errmsg := 'From sp_update_limits '||errmsg;
               				ELSE
                  			UPDATE CMS_UPDATE_CRDLIMITS
                     		SET CUC_DONE_FLAG = 'Y'
                     		WHERE CUC_PAN_CODE = X.CUC_PAN_CODE
							AND CUC_DONE_FLAG = 'P' ;
               				END IF;
			           	   	 END;
						END IF;


            IF ERRMSG != 'OK' THEN
                  UPDATE CMS_UPDATE_CRDLIMITS
                     SET CUC_PROCESS_RESULT = errmsg,
                         CUC_DONE_FLAG = 'E'
                     WHERE CUC_PAN_CODE = X.CUC_PAN_CODE ;
            END IF;
            END;  --end 1.2
		END LOOP;

      errmsg := 'OK';
      EXCEPTION	--excp of begin 1.2
				WHEN OTHERS THEN
            errmsg := 'Excp 1.1 '||SQLERRM;
END;--END 1.1
/


