CREATE OR REPLACE PROCEDURE VMSCMS.UPDATE_VMS_ORDER_LINEITEM (
   p_prodcode_in    IN   VARCHAR2,
   p_card_type_in	IN   NUMBER)
IS
   v_err         VARCHAR2 (500);   
   
BEGIN

		
	FOR i in (SELECT vol_order_id ,vol_line_item_id , vol_parent_oid  ,
	(SELECT vol_embossedline  FROM VMSCMS.VMS_LINE_ITEM_DTL,VMSCMS.vms_order_lineitem,VMSCMS.CMS_APPL_PAN B
	WHERE  VLI_PAN_CODE = B.CAP_PAN_CODE AND A.CAP_SERIAL_NUMBER = B.CAP_SERIAL_NUMBER AND B.CAP_INST_CODE=1 AND 
	VLI_SERIAL_NUMBER = A.CAP_SERIAL_NUMBER AND VLI_ORDER_ID =VOL_ORDER_ID AND VLI_PARENT_OID = VOL_PARENT_OID AND 
	 vli_partner_id<>'Replace_Partner_ID' ) original_emboss_name
	FROM VMSCMS.VMS_ORDER_DETAILS,VMSCMS.VMS_ORDER_LINEITEM ,VMSCMS.VMS_LINE_ITEM_DTL,VMSCMS.CMS_APPL_PAN A
	WHERE 
	VOD_ORDER_ID=VOL_ORDER_ID 
	AND VOL_PARENT_OID=VOD_PARENT_OID
	AND VOL_ORDER_ID=VLI_ORDER_ID
	AND VLI_LINEITEM_ID=VOL_LINE_ITEM_ID
	AND VLI_PAN_CODE=CAP_PAN_CODE
	AND CAP_INST_CODE=1
	AND VOD_ORDER_ID like 'R%'
	AND VOD_ORDER_STATUS = 'Processed' AND VOD_PARTNER_ID = 'Replace_Partner_ID'
	AND (VOL_CCF_FLAG = '1' OR vol_embossedline is NULL)
	and CAP_PROD_CODE= p_prodcode_in and  CAP_CARD_TYPE= p_card_type_in
	)
			
		LOOP
			BEGIN
				UPDATE vmscms.vms_order_lineitem
				SET vol_embossedline       = i.original_emboss_name
				WHERE vol_order_id = i.vol_order_id
				AND vol_line_item_id   = i.vol_line_item_id
				AND vol_parent_oid     = i.vol_parent_oid;
			EXCEPTION
				WHEN OTHERS
				THEN
				v_err :=
				'Error while updating vms_order_lineitem ' 
				|| SUBSTR (SQLERRM, 1, 200);
				
			INSERT INTO vmscms.VMS_ERROR_LOG (VEL_PAN_CODE,
											  VEL_ERROR_MSG,    		                                 
											  VEL_INS_DATE)
									  values (
											  SUBSTR('UPDATE_VMS_ORDER_LINEITEM '|| i.vol_order_id||'|'||i.vol_line_item_id,1,100),
									  		  v_err,
											  SYSDATE);
					        
			END;                                  
		                                       
		END LOOP;
commit;


EXCEPTION
   WHEN OTHERS
   THEN
      
      v_err := 'Error in main ' || SUBSTR (SQLERRM, 1,200);
      INSERT INTO vmscms.VMS_ERROR_LOG (VEL_PAN_CODE,
											  VEL_ERROR_MSG,    		                                 
											  VEL_INS_DATE)
									  values ('UPDATE_VMS_ORDER_LINEITEM',
									  		  v_err,
											  SYSDATE);
commit;											  
											  
END;
/

show error;