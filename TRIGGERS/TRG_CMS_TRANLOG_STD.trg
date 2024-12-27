create or replace
TRIGGER VMSCMS.TRG_CMS_TRANLOG_STD
   BEFORE INSERT OR UPDATE
   ON vmscms.transactionlog_ebr
   FOR EACH ROW
/*************************************************
     * Created Date       :
     * Created By         :
     * PURPOSE            :
     * Modified By:       : Ganesh
     * Modified Date      : 12/09/2012
     * Modified reason    : Inserting and Updating the sysdate.
     * VERSION            : CMS3.5.1_RI0016_B0002
     * Reviewed by        : Saravanakumar
     * Reviewed Date      : 12/09/2012
	 
	 * Modified by       : Siva kumar M
     * Modified Date     : 18-Aug-17
     * Modified For      : FSS-5157 B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.08
	 
   	 * Modified by       : Akhil
     * Modified Date     : 15-Nov-17
     * Modified For      : VMS-63
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.10.1
	 
	 * Modified by       : Ubaid
     * Modified Date     : 05-Jul-2018
     * Modified For      :  VMS-375
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSR03_B0003
     
     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 14-NOV-2019
     * Purpose          : Fix for dead lock issue
     * Reviewer         : Saravanakumar A 
     * Build Number     : VMS_RSI0226
	 
	 * Modified By      : Ubaidur Rahman H
     * Modified Date    : 18-DEC-2020
     * Purpose          : VMS- 3100 - BlockingSession Identified in B2BCCF 
										APPL_PAN lock while update of cap_last_txndate
     * Reviewer         : Saravanakumar A 
     * Build Number     : VMS_RSI0226
     
     * Modified By      : Pankaj S.
     * Modified Date    : 11/07/2022
     * Purpose          : VMS-5657 (VMS-6071 -Restrict the update of last transaction date for insta fin prods)
     * Reviewer         : Venkat S.
     * Build Number     : VMS_R66
   ***********************************************/
DECLARE   
   --SN: Added for VMS-6071
	v_toggle_value  cms_inst_param.cip_param_value%TYPE;
	v_prod_code		cms_appl_pan.cap_prod_code%TYPE;
	v_card_typ		cms_appl_pan.cap_card_type%TYPE;
	v_prd_chk       NUMBER :=0;
   --EN: Added for VMS-6071
BEGIN                                                    --Trigger body begins
   
   IF INSERTING THEN
      :NEW.add_ins_date := SYSDATE;
      :NEW.add_lupd_date := SYSDATE;
     --Sn Added for DFCTNM-44-Partner Id changes
     BEGIN
        IF :NEW.productid IS NULL THEN
           SELECT cpp_partner_id,
				  cap_prod_code, cap_card_type --Added for VMS-6071
             INTO :NEW.partner_id,
				  v_prod_code, v_card_typ --Added for VMS-6071
             FROM cms_appl_pan, cms_product_param
            WHERE cap_pan_code = :NEW.customer_card_no
              AND cpp_prod_code = cap_prod_code
              AND cpp_inst_code = cap_inst_code;
        ELSE
           --SN: Added for VMS-6071
           v_prod_code := :NEW.productid;
           v_card_typ := :NEW.categoryid;
           --EN: Added for VMS-6071
           
           SELECT cpp_partner_id
             INTO :NEW.partner_id
             FROM cms_product_param
            WHERE cpp_prod_code = :NEW.productid
              AND cpp_inst_code = :NEW.instcode;
        END IF;
     EXCEPTION
      WHEN OTHERS THEN
         NULL;
     END;
     --En Added for DFCTNM-44-Partner Id changes

      BEGIN
        IF :NEW.date_time IS NULL THEN
           :NEW.date_time := to_date(:NEW.business_date||:NEW.business_time,'YYYYMMDDhh24miss');
        END IF;
     EXCEPTION
      WHEN OTHERS THEN
         NULL;
     END;
	 
	  --SN: Added for VMS-6071
     BEGIN
	  SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
		INTO v_toggle_value
		FROM vmscms.cms_inst_param
	   WHERE cip_inst_code = 1
		 AND cip_param_key = 'VMS_5657_TOGGLE';
	 EXCEPTION
	   WHEN NO_DATA_FOUND
	   THEN
		  v_toggle_value := 'Y';
	 END;
	 
	 IF v_toggle_value = 'Y' THEN
	   BEGIN
	    SELECT COUNT(1)
          INTO v_prd_chk
		  FROM vmscms.vms_dormantfee_txns_config
		 WHERE vdt_prod_code = v_prod_code
		   AND vdt_card_type = v_card_typ
		   AND vdt_is_active = 1;
	   EXCEPTION
	    WHEN OTHERS THEN
          NULL;
	   END;
	 END IF;
     --EN: Added for VMS-6071

      IF NOT (:NEW.delivery_channel = '05' AND :NEW.txn_code IN ('04','06','07','13', '16', '17', '18', '97')
				OR (:NEW.delivery_channel = '17' AND :NEW.txn_code ='04')) 
                AND v_prd_chk = 0 --Added for VMS-6071
				--- Modified for dead lock issue.
      THEN
         UPDATE cms_appl_pan
            SET cap_last_txndate = SYSDATE
          WHERE cap_pan_code = :NEW.customer_card_no
                 AND trunc(NVL(cap_last_txndate,sysdate-1))<trunc(sysdate)
				 AND cap_proxy_number is NOT NULL;					
																	
																	---Modified for VMS-3100-BlockingSession Identified in B2BCCF  
	   END IF;
      
       IF :NEW.delivery_channel <> '05' AND :NEW.CR_DR_FLAG ='DR' and :NEW.customer_acct_no is not null THEN
        UPDATE  CMS_ACCT_MAST 
          SET CAM_FIRST_PURCHASEDATE=SYSDATE 
          WHERE cam_acct_no=:NEW.customer_acct_no
          and CAM_FIRST_PURCHASEDATE IS NULL;
       END IF;
     
   ELSIF UPDATING THEN
      :NEW.add_lupd_date := SYSDATE;
   END IF;
END;
/
show error