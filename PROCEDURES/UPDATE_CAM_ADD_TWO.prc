CREATE OR REPLACE PROCEDURE vmscms.UPDATE_CAM_ADD_TWO IS

 /*************************************************
  * Created by        :Ubaidur Rahman.H
  * Created Date     : 15-Apr-2019
  * Created reason   : VMS-877
  * Reviewer         : Saravanakumar
  * Release Number   : VMS_RSJ019
**************************************************/ 
  v_err         VARCHAR2 (500);

BEGIN
		FOR i in (select pan.CAP_CUST_CODE custcode
                from CMS_CARDISSUANCE_STATUS issuance,cms_appl_pan pan,cms_addr_mast addr
				where issuance.ccs_card_status='2' and pan.CAP_STARTERCARD_FLAG='N' 
				and pan.cap_pan_code=issuance.ccs_pan_code 
				and pan.cap_inst_code=issuance.ccs_inst_code
                and pan.cap_cust_code=addr.cam_cust_code
                and pan.cap_inst_code=addr.cam_inst_code
                and LOWER(FN_DMAPS_MAIN(addr.CAM_ADD_TWO))='null')
			
		LOOP
			BEGIN
            
			UPDATE CMS_ADDR_MAST
                SET  cam_add_two = NULL
            WHERE    cam_cust_code = i.custcode;

			EXCEPTION
				WHEN OTHERS
				THEN
				v_err := 'Error while updating CMS_ADDR_MAST '|| SUBSTR (SQLERRM, 1, 200);
                INSERT INTO vms_error_log ( vel_pan_code,vel_error_msg,vel_ins_date ) 
					VALUES ('update_cam_add_two ' || i.custcode,
                    v_err,
                    SYSDATE
                );
			END;
			
		END LOOP;
commit;

EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      v_err := 'Error in main ' || SUBSTR (SQLERRM, 1, 200);
      INSERT INTO vmscms.vms_error_log ( vel_pan_code,vel_error_msg,vel_ins_date ) VALUES ( 'update_cam_add_two ',v_err,SYSDATE );
      commit;
END;
/
show error