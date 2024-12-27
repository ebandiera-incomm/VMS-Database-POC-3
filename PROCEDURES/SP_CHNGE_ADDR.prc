CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Chnge_Addr (
   prm_instcode       IN       NUMBER,
   prm_pancode        IN       VARCHAR2,
   prm_mbrnumb        IN       VARCHAR2,
   prm_remark         IN       VARCHAR2,
   prm_rsncode        IN       NUMBER,
   prm_rrn            IN       VARCHAR2,
   prm_terminalid     IN       VARCHAR2,
   prm_stan           IN       VARCHAR2,
   prm_trandate       IN       VARCHAR2,
   prm_trantime       IN       VARCHAR2,
   prm_acctno         IN       VARCHAR2,
   prm_filename       IN       VARCHAR2,
   prm_amount         IN       NUMBER,
   prm_refno          IN       VARCHAR2,
   prm_paymentmode    IN       VARCHAR2,
   prm_instrumentno   IN       VARCHAR2,
   prm_drawndate      IN       DATE,
   prm_currcode       IN       VARCHAR2,
   prm_addrcode		  IN	   NUMBER,
   prm_CustomerCode	  IN	   NUMBER,
   prm_AddressLine1   IN		   VARCHAR2,
   prm_AddressLine2   IN		   VARCHAR2,
   prm_AddressLine3   IN		   VARCHAR2,
   prm_PinCode 		  IN	 VARCHAR2,
   prm_Phone1 		  IN	 VARCHAR2,
   prm_Phone2 		  IN	 VARCHAR2,
   prm_CountryCode 	  IN		  VARCHAR2,
   prm_CityName 	  IN	VARCHAR2,
   prm_StateName 	  IN		 VARCHAR2,
   prm_Fax1 		  IN	  VARCHAR2,
   prm_AddressFlag 	  IN	   VARCHAR2,
   prm_lupduser       IN       NUMBER,
   prm_workmode       IN       NUMBER,
   prm_auth_message   OUT      VARCHAR2,
   prm_newAddrCode	  OUT	   NUMBER,
   prm_errmsg         OUT      VARCHAR2
)
AS
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 27/APR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Change Card status for a perticular card number
     * Modified By:    :
     * Modified Date  :
  *************************************************/
   v_cap_prod_catg          VARCHAR2 (2);
   v_mbrnumb                VARCHAR2 (3);
   dum                      NUMBER;
   v_cap_card_stat          CHAR (1);
   v_cap_cafgen_flag        CHAR (1);
   v_cap_embos_flag         CHAR (1);
   v_cap_pin_flag           CHAR (1);
   v_errmsg                 VARCHAR2 (300)                   DEFAULT 'OK';
   v_rrn                    VARCHAR2 (200);
   v_del_channel            VARCHAR2 (2);
   v_term_id                VARCHAR2 (200);
   v_date_time              DATE;
   v_txn_code               VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_txn_mode               VARCHAR2 (2);
   v_tran_date              VARCHAR2 (200);
   v_tran_time              VARCHAR2 (200);
   v_txn_amt                NUMBER;
   v_card_no                CMS_APPL_PAN.cap_pan_code%TYPE;
   v_resp_code              VARCHAR2 (200);
   v_resp_msg               VARCHAR2 (200);
   v_capture_date           DATE;
   v_auth_id                VARCHAR2 (6);
   v_autherrmsg             VARCHAR2 (300)                   DEFAULT 'OK';
   v_addrcode				NUMBER;
   addrcode					NUMBER;
   v_old_addrcode			CMS_APPL_PAN.cap_bill_addr%TYPE;	
   v_comm_type				CHAR(1); 
   exp_reject_record        EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
BEGIN                                                      --<< MAIN BEGIN  >>
   prm_errmsg := 'OK';
   prm_auth_message := 'OK';
   v_rrn := prm_rrn;
   v_term_id := prm_terminalid;
   v_tran_date := TO_CHAR (SYSDATE, 'yyyymmdd');               -- '20080723';
   v_tran_time := TO_CHAR (SYSDATE, 'HH24:MI:SS');              --'16:21:10';
   v_card_no   := prm_pancode;
   v_txn_amt   := prm_amount;
     

   IF prm_mbrnumb IS NULL
   THEN
      v_mbrnumb := '000';
   ELSE
      v_mbrnumb := prm_mbrnumb;
   END IF;
   
    ------------------------------------------------Sn check card number------------------------------------
   BEGIN
      SELECT cap_bill_addr,cap_prod_catg, cap_card_stat, cap_cafgen_flag,
             cap_embos_flag, cap_pin_flag
        INTO v_old_addrcode,v_cap_prod_catg, v_cap_card_stat, v_cap_cafgen_flag,
             v_cap_embos_flag, v_cap_pin_flag
        FROM CMS_APPL_PAN
       WHERE cap_pan_code = prm_pancode
         AND cap_mbr_numb = v_mbrnumb
         AND cap_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'No such PAN found.';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
                'Error while selecting pan code ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

------------------------------------------------EN check card number--------------------------------------

------------------------------------------------Sn Pick comm type from addr mast ------------------------------------
   BEGIN
      SELECT cam_comm_type
        INTO v_comm_type
        FROM CMS_ADDR_MAST
       WHERE cam_addr_code = v_old_addrcode
         AND cam_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Addr Communication Type is not found';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
                'Error while selecting Addr Communication Type ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

------------------------------------------------EN Pick comm type from addr mast --------------------------------------


   
   IF prm_AddressFlag = 'E' THEN
	   BEGIN
   	  			Sp_Create_Addr(prm_instcode,
							 prm_CustomerCode,
							 prm_AddressLine1,
							 prm_AddressLine2,
							 prm_AddressLine3,
				 			 prm_PinCode,
							 prm_Phone1,
							 prm_Phone2,
							 NULL,
							 prm_CountryCode,
							 prm_CityName,
							 prm_StateName,--state as coming from switch
							 prm_Fax1, 
							 'P',
							 v_comm_type,
							 prm_lupduser,
							 v_addrcode,
							 v_errmsg);
							 IF v_errmsg != 'OK' THEN
							 	v_errmsg := 'error while creating new address'||v_errmsg;
							  	RAISE exp_reject_record;
							 END IF; 
							 IF v_addrcode IS NULL OR  v_addrcode = 0 THEN
							 	 v_errmsg := 'error while creating new address'||v_errmsg;
							  	RAISE exp_reject_record;
							 END IF;
		EXCEPTION 
		WHEN exp_reject_record THEN
		v_errmsg := 'error while creating new address'||v_errmsg;
			RAISE;
		WHEN OTHERS THEN
		v_errmsg := 'error while creating new address'||v_errmsg||SQLERRM;
			RAISE exp_reject_record;
		END;
   							  		  
   END IF;
   
----------------------------------------------Sn check remark-------------------------------------------
   IF prm_remark IS NULL
   THEN
      v_errmsg := 'Please enter appropriate remark';
      RAISE exp_reject_record;
   END IF;

----------------------------------------------EN check remark-------------------------------------------

  
   -----------------------------------Sn select transaction code,mode and del channel-------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'ADDR';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
                  'Support function card status change not defined in master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting support function detail '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

-----------------------------------EN select transaction code,mode and del channel---------------------------
     ----------------------------Debit and prepaid_condition check-----------------------------------
   IF v_cap_prod_catg = 'P'
   THEN
      --------------------------------------------------Sn call to authorize procedure--------------------------
      Sp_Authorize_Txn (prm_instcode,                         -- prm_inst_code
                        '210',                                      -- prm_msg
                        v_rrn,                                      -- prm_rrn
                        v_del_channel,                  --prm_delivery_channel
                        v_term_id,                               --prm_term_id
                        v_txn_code,                             --prm_txn_code
                        v_txn_mode,                            -- prm_txn_mode
                        v_tran_date,                           --prm_tran_date
                        v_tran_time,                          -- prm_tran_time
                        v_card_no,                              -- prm_card_no
                        NULL,                                  --prm_bank_code
                        v_txn_amt,                              -- prm_txn_amt
                        NULL,                             --prm_rule_indicator
                        NULL,                                 --prm_rulegrp_id
                        NULL,                                   --prm_mcc_code
                        prm_currcode,                          --prm_curr_code
                        NULL,                                   -- prm_prod_id
                        NULL,                                   -- prm_catg_id
                        NULL,                                    --prm_tip_amt
                        NULL,                            -- prm_decline_ruleid
                        NULL,                               -- prm_atmname_loc
                        NULL,                           -- prm_mcccode_groupid
                        NULL,                          -- prm_currcode_groupid
                        NULL,                         -- prm_transcode_groupid
                        NULL,                                      --prm_rules
                        NULL,                              -- prm_preauth_date
                        NULL,                            -- prm_consodium_code
                        NULL,                               --prm_partner_code
                        NULL,                                -- prm_expry_date
                        prm_stan,                                  -- prm_stan
                        prm_lupduser,                               --Ins User
                        SYSDATE,                                    --INS Date
                        v_auth_id,                              -- prm_auth_id
                        v_resp_code,                           --prm_resp_code
                        v_resp_msg,                             --prm_resp_msg
                        v_capture_date                      --prm_capture_date
                       );

      IF v_resp_code <> '00'
      THEN
         v_autherrmsg := v_resp_msg;
         RAISE exp_auth_reject_record;
      END IF;
   END IF;

--------------------------------------------------EN call to authorize procedure--------------------------------

   --------------------------------------------------Sn update card stat----------------------------------------
   BEGIN
	   IF prm_addrcode IS NULL THEN
	      addrcode := v_addrcode;
		  prm_newAddrCode := v_addrcode;
	   ELSE
		  addrcode := prm_addrcode;
	   END IF;
      UPDATE CMS_APPL_PAN
               SET cap_bill_addr =  addrcode
             WHERE cap_inst_code = prm_instcode
               AND cap_pan_code = prm_pancode
               AND cap_mbr_numb = v_mbrnumb;

      IF SQL%ROWCOUNT != 1
      THEN
         v_errmsg :=
               'Problem in updation of status for pan ' || prm_pancode || '.';
         RAISE exp_reject_record;
      END IF;
	  
	    
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Problem in updation of status for pan '
            || prm_pancode
            || ' . '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

--------------------------------------------------EN update card stat-------------------------------------------


---Sn change the old address flag
IF prm_AddressFlag = 'E' THEN

	 BEGIN
	 	  UPDATE CMS_ADDR_MAST
	  	  SET	 cam_addr_flag = 'E'
	  	  WHERE  cam_inst_code = prm_instcode
	  	  AND	 cam_addr_code = v_old_addrcode;
	  
	  IF SQL%ROWCOUNT != 1
      THEN
         v_errmsg :=
               'Problem in updation of address flag of old address ' || '.';
         RAISE exp_reject_record;
      END IF;
	 
	 
	 
	 EXCEPTION
	 WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Problem in updation of status for pan '
            || prm_pancode
            || ' . '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
 
	 END;
	 
END IF;  




--En   Change the old address flag

   ------------------------------------------------SN insert a record in pan spprt------------------------------
   BEGIN
      INSERT INTO CMS_PAN_SPPRT
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode
                  )
           VALUES (prm_instcode, prm_pancode, v_mbrnumb, v_cap_prod_catg,
                   'ADDR', prm_rsncode, prm_remark,
                   prm_lupduser, prm_lupduser, prm_workmode
                  );
   EXCEPTION                                                 --excp of begin 3
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'error while inserting records into pan_spprt'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;
----------------------------------------------En insert a record in pan spprt------------------------------------
EXCEPTION                                                --<<MAIN EXCEPTION >>
   WHEN exp_auth_reject_record
   THEN
      prm_auth_message := v_autherrmsg;
      prm_errmsg := v_autherrmsg;
   WHEN exp_reject_record
   THEN
      prm_errmsg := v_errmsg;
      prm_auth_message := v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;                                                           --<< MAIN END>>
/


