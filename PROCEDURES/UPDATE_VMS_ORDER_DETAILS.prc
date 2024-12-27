CREATE OR REPLACE PROCEDURE vmscms.UPDATE_VMS_ORDER_DETAILS IS

 /*************************************************
  * Created by       : Narayanan
  * Created Date     : 15-Apr-2019
  * Created reason   : VMS-877
  * Reviewer         : Saravanakumar
  * Release Number   : VMS_RSJ018
**************************************************/ 
  v_err         VARCHAR2 (500);

BEGIN
		FOR i in (SELECT orderdetail.VOD_ORDER_ID,orderdetail.VOD_PARTNER_ID
					FROM VMS_ORDER_DETAILS orderdetail ,VMS_ORDER_LINEITEM lineitem
					WHERE orderdetail.VOD_PARTNER_ID IN (SELECT VPI_PARTNER_ID FROM VMS_PARTNER_ID_MAST)
					AND orderdetail.VOD_ORDER_ID=lineitem.VOL_ORDER_ID 
                    and orderdetail.VOD_PARTNER_ID=lineitem.VOL_PARTNER_ID
					AND orderdetail.VOD_ORDER_STATUS = 'Processed' 
					AND lineitem.VOL_CCF_FLAG = '1'
					AND (LOWER(FN_DMAPS_MAIN(lineitem.VOL_EMBOSSEDLINE))='null' OR LOWER(FN_DMAPS_MAIN(lineitem.VOL_EMBOSSED_LINE1))='null'
					OR LOWER(FN_DMAPS_MAIN(orderdetail.VOD_ADDRESS_LINE1))='null' OR LOWER(FN_DMAPS_MAIN(orderdetail.VOD_ADDRESS_LINE2))='null'
					OR LOWER(FN_DMAPS_MAIN(orderdetail.VOD_SHIP_TO_COMPANYNAME))='null'))
			
		LOOP
			BEGIN
            
			UPDATE VMS_ORDER_DETAILS
			SET VOD_ADDRESS_LINE1=DECODE(LOWER(FN_DMAPS_MAIN(VOD_ADDRESS_LINE1)),'null' ,null,VOD_ADDRESS_LINE1),
			VOD_ADDRESS_LINE2=DECODE(LOWER(FN_DMAPS_MAIN(VOD_ADDRESS_LINE2)),'null' ,null,VOD_ADDRESS_LINE2),
			VOD_SHIP_TO_COMPANYNAME=DECODE(LOWER(FN_DMAPS_MAIN(VOD_SHIP_TO_COMPANYNAME)),'null' ,null,VOD_SHIP_TO_COMPANYNAME)
			WHERE VOD_ORDER_ID=I.VOD_ORDER_ID AND VOD_PARTNER_ID=I.VOD_PARTNER_ID;
			EXCEPTION
				WHEN OTHERS
				THEN
				v_err := 'Error while updating VMS_ORDER_DETAILS '|| SUBSTR (SQLERRM, 1, 200);
                    INSERT INTO vms_error_log ( vel_pan_code,vel_error_msg,vel_ins_date ) 
					VALUES (substr( 'UPDATE_VMS_ORDER_DETAILS ' || i.VOD_ORDER_ID || '|' || i.VOD_PARTNER_ID,1,100),
                    v_err,
                    SYSDATE
                );
			END;
			
			BEGIN
                UPDATE VMS_ORDER_LINEITEM
                SET VOL_EMBOSSEDLINE=DECODE(LOWER(FN_DMAPS_MAIN(VOL_EMBOSSEDLINE)),'null' ,null,VOL_EMBOSSEDLINE),
                VOL_EMBOSSED_LINE1=DECODE(LOWER(FN_DMAPS_MAIN(VOL_EMBOSSED_LINE1)),'null' ,null,VOL_EMBOSSED_LINE1)
                WHERE VOL_ORDER_ID=I.VOD_ORDER_ID AND VOL_PARTNER_ID=I.VOD_PARTNER_ID;
			EXCEPTION
				WHEN OTHERS
				THEN
				v_err :='Error while updating VMS_ORDER_LINEITEM '|| SUBSTR (SQLERRM, 1, 200);
                    INSERT INTO vms_error_log ( vel_pan_code,vel_error_msg,vel_ins_date ) 
					VALUES (substr( 'UPDATE_VMS_ORDER_DETAILS ' || i.VOD_ORDER_ID || '|' || i.VOD_PARTNER_ID,1,100),
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
      INSERT INTO vmscms.vms_error_log ( vel_pan_code,vel_error_msg,vel_ins_date ) 
	  VALUES ( 'UPDATE_VMS_ORDER_DETAILS',v_err,SYSDATE );
      commit;
END;
/
show error