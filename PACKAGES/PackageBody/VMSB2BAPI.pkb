create or replace PACKAGE BODY                VMSCMS.VMSB2BAPI
IS
   -- Private type declarations

   -- Private constant declarations

   -- Private variable declarations

   -- Function and procedure implementations



/************************************************************************************************************

    * Modified by      : UBAIDUR RAHMAN.H
    * Modified Date    : 02-April-2019
    * Modified For     : VMS-823
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR14_B0002

     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 29-AUG-2019
     * Purpose          : VMS-1084 (Pan genaration process from sequential to shuffled - B2B & Retail)
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOSTR20_B1

      * Modified By      : Ubaidur Rahman H
     * Modified Date    : 03-Oct-2019
     * Purpose          : VMS-1052 B2B Order processing validation Enhancement
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOSTR21_B2

     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 30-OCT-2019
     * Purpose          : VMS-1248 (Improve Query performance for BOL SQL for card creation)
     * Reviewer         : Saravanakumar A

     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 14-NOV-2019
     * Purpose          : Fix for dead lock issue
     * Reviewer         : Saravanakumar A
     * Build Number     : VMS_RSI0226

     * Modified By      : DHINAKARAN B
     * Modified Date    : 09-JUL-2020
     * Purpose          : VMS-2810 - Order postback message has to
     				correct when the inventory is not available.
     * Reviewer         : Saravanakumar A.
     * Build Number     : R33 - BUILD 1

	  * Modified By      : Puvanesh. N
     * Modified Date    : 07-June-2021
     * Purpose          : VMS-4403 Order V2 "isrecipientaddress" flag-CCF-B2B Spec Consolidation
     * Reviewer         : Saravanakumar A.
     * Build Number     : R47 - BUILD 3

     * Modified By      : Mageshkumar.S
     * Modified Date    : 31-August-2021
     * Purpose          : VMS-4895:Initial amount is getting doubled for rejected cards after processing the response file.
     * Reviewer         : Saravanakumar A.
     * Build Number     : R51 - BUILD 1

	 * Modified By      : Ubaidur Rahman.H
     * Modified Date    : 29-09-2021
     * Purpose          : VMS-5015:Virtual Card replacement without address is updating system passed default name & address for Customer Profile.
     * Reviewer         : Saravanakumar A.
     * Build Number     : R52 - BUILD 2

	 * Modified By      : Mageshkumar.S
     * Modified Date    : 25-01-2022
     * Purpose          : VMS-5432:C - Order V1/V2 with Initial Load Amount--Access to Funds-- --B2B Spec Consolidation
     * Reviewer         : Saravanakumar A.
     * Build Number     : R57.1 - BUILD 1

     * Modified By      : Mageshkumar.S
     * Modified Date    : 22-03-2022
     * Purpose          : VMS-5673:Delay access to funds
     * Reviewer         : Saravanakumar A.
     * Build Number     : R60 - BUILD 2

     * Modified By      : Mageshkumar.S
     * Modified Date    : 04-04-2022
     * Purpose          : VMS-5814:System not updating the CVK Key ID(Key used to generate the CVV) in CMS_APPL_PAN table for Virtual Card CVV generation
     * Reviewer         : Saravanakumar A.
     * Build Number     : R60.1 - BUILD 1

*****************************************************************************************************************/
PROCEDURE get_inventory_control_number(p_prod_code_in in varchar2,
                                      p_card_type_in in number,
                                      p_quantity_in  in number,
                                      p_start_control_number_out out number,
                                      p_end_control_number_out out number,
                                      p_error_out out varchar2)
AS

l_exp exception;
PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
  p_error_out:='OK';

 BEGIN
    SELECT VIC_CONTROL_NUMBER
    INTO p_start_control_number_out
    FROM VMS_INVENTORY_CONTROL
    WHERE VIC_PROD_CODE=p_prod_code_in
    AND VIC_CARD_TYPE=p_card_type_in
    FOR UPDATE;
 EXCEPTION
    WHEN OTHERS THEN
        p_error_out:= 'Error while selecting VMS_INVENTORY_CONTROL '||substr(sqlerrm,1,200);
        raise l_exp;
 END;

  p_end_control_number_out:=p_start_control_number_out+p_quantity_in-1;

  BEGIN
    UPDATE VMS_INVENTORY_CONTROL
    SET VIC_CONTROL_NUMBER =p_end_control_number_out+1
    WHERE VIC_PROD_CODE=p_prod_code_in
    AND VIC_CARD_TYPE=p_card_type_in;
 EXCEPTION
    WHEN OTHERS THEN
        p_error_out:= 'Error while updating VMS_INVENTORY_CONTROL '||substr(sqlerrm,1,200);
        raise l_exp;
 END;

 COMMIT;
 EXCEPTION
     WHEN l_exp THEN
        ROLLBACK;
    WHEN OTHERS THEN
        p_error_out:= 'Error in main '||substr(sqlerrm,1,200);
        ROLLBACK;
END get_inventory_control_number;

PROCEDURE UPDATE_PANGEN_SUMMARY	(p_prod_code_in in varchar2,
                                      p_card_type_in in number,
                                      p_start_control_number in number,
                                      p_end_control_number in number,
                                      p_error_out out varchar2)
AS

/********************************************************************************

     * Modified By      : PANDU GANDHAM
     * Modified Date    : 29-SEP-2020
     * Purpose          : VMS-3066 - Product Setup re-Vamp - BIN.
     * Reviewer         : Puvanesh / Ubaidur
     * Build Number     : R36 - BUILD 3

*********************************************************************************/


BEGIN
  p_error_out:='OK';

	FOR I IN (SELECT CAP_CARDRANGE_ID,COUNT(1) V_QUANTITY
					FROM CMS_APPL_PAN_INV
					WHERE CAP_PROD_CODE = p_prod_code_in
					AND   CAP_CARD_TYPE = p_card_type_in
					AND   cap_card_seq BETWEEN p_start_control_number AND p_end_control_number
					GROUP BY CAP_CARDRANGE_ID)
	LOOP

    UPDATE VMS_PANGEN_SUMMARY
    SET vps_avail_cards =  vps_avail_cards - I.V_QUANTITY
    WHERE VPS_PROD_CODE = p_prod_code_in
    AND VPS_CARD_TYPE = p_card_type_in
	AND VPS_CARDRANGE_ID = I.CAP_CARDRANGE_ID;

    END LOOP;

 EXCEPTION
    WHEN OTHERS THEN
        p_error_out:= 'Error While Updating Pangen Summary Table '||substr(sqlerrm,1,200);


END UPDATE_PANGEN_SUMMARY;


PROCEDURE process_order_request (p_inst_code_in    IN     NUMBER,
                                    p_order_id_in     IN     VARCHAR2,
                                    p_partner_id_in   IN     VARCHAR2,
                                    p_user_code_in    IN     NUMBER,
                                    p_resp_msg_out       OUT VARCHAR2)
   AS

/********************************************************************************

     * Modified By      : UBAIDUR RAHMAN H
     * Modified Date    : 28-AUG-2020
     * Purpose          : VMS-2888 - VPS_AVAIL_CARDS Column on VMS_PANGEN_SUMMARY
					Table has incorrect value.
     * Reviewer         : Saravanakumar A.
     * Build Number     : R35 - BUILD 3

     * Modified By      : PANDU GANDHAM
     * Modified Date    : 29-SEP-2020
     * Purpose          : VMS-3066 - Product Setup re-Vamp - BIN.
     * Reviewer         : Puvanesh / Ubaidur
     * Build Number     : R36 - BUILD 3

     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 06-MAY-2021
     * Purpose          : VMS-4192 -  Order V2 is failing for Virtual Product
     * Reviewer         : SARAVANA KUMAR A
     * Build Number     : R46 - BUILD 2

     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 14-Sep-2021
     * Purpose          : VMS-5088 - Virtual Order Process via V2 should log the
     					cardpack id in APPL PAN table.
     * Reviewer         : SARAVANA KUMAR A
     * Build Number     : R51 - BUILD 1

     * Modified By      : Ubaidur Rahman.H
     * Modified Date    : 51-NOV-2021
     * Purpose          : VMS-5328 - Dormancy Fee Helath Care on Load date VIA V2
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : R55 - BUILD 3

     * Modified By      :  Ubaidur Rahman.H
     * Modified Date    :  03-Dec-2021
     * Modified Reason  :  VMS-5253 / 5372 - Do not pass sytem generated value from VMS to CCA.
     * Reviewer         :  Saravanakumar
     * Build Number     :  VMSGPRHOST_R55_RELEASE

     * Modified By      : Mageshkumar.S
     * Modified Date    : 25-01-2022
     * Purpose          : VMS-5432:C - Order V1/V2 with Initial Load Amount--Access to Funds-- --B2B Spec Consolidation
     * Reviewer         : Saravanakumar A.
     * Build Number     : R57.1 - BUILD 1

     * Modified By      : Mageshkumar.S
     * Modified Date    : 22-03-2022
     * Purpose          : VMS-5673:Delay access to funds
     * Reviewer         : Saravanakumar A.
     * Build Number     : R60 - BUILD 2

     * Modified By      : Mageshkumar.S
     * Modified Date    : 04-04-2022
     * Purpose          : VMS-5814:System not updating the CVK Key ID(Key used to generate the CVV) in CMS_APPL_PAN table for Virtual Card CVV generation
     * Reviewer         : Saravanakumar A.
     * Build Number     : R60.1 - BUILD 1

	* Modified By      : Bhavani E.
    * Modified Date    : 04-05-2023
    * Purpose          : VMS-7274 :  Expiry Date Randomization - Exclude sweep products
    * Reviewer         : Venkat S.

*********************************************************************************/


      l_const              NUMBER := 1;
      l_mbr_numb           VARCHAR2 (5) := '000';
      l_parent_id     vms_order_details.vod_parent_oid%TYPE;
      l_card_stat          vms_order_details.vod_order_default_card_status%TYPE;
      l_prod_code          cms_prod_cattype.cpc_prod_code%TYPE;
      l_card_type          cms_prod_cattype.cpc_card_type%TYPE;
      l_profile_code       cms_prod_cattype.cpc_profile_code%TYPE;
      l_prxy_length        cms_prod_cattype.cpc_proxy_length%TYPE;
      l_serl_flag          cms_prod_cattype.cpc_ccf_serial_flag%TYPE;
      l_progm_id           cms_prod_cattype.cpc_program_id%TYPE;
      l_prod_type          cms_bin_param.cbp_param_value%TYPE;
      l_expry_date         cms_appl_pan.cap_expry_date%TYPE;
      l_succ_count         NUMBER (5) := 0;
      l_proc_stat          VARCHAR2 (5) := 'P';
      l_pins               shuffle_array_typ;
      l_encr_key           cms_bin_param.cbp_param_value%TYPE;
      l_auth_id            transactionlog.auth_id%TYPE;
      l_rrn                transactionlog.rrn%TYPE;
      l_timestamp          TIMESTAMP;
      l_business_time      transactionlog.business_time%TYPE;
      l_delivery_channel   cms_transaction_mast.ctm_delivery_channel%TYPE;
      l_txn_code           cms_transaction_mast.ctm_tran_code%TYPE;
      l_tran_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
      l_drcr_flag          cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_hashkey_id         cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_narration          cms_statements_log.csl_trans_narrration%TYPE;
      l_channel_code       vms_order_details.vod_channel_id%TYPE;
      l_activation_code    vms_order_details.vod_activation_code%TYPE;
      v_resp_msg_out       VARCHAR2 (1000);
      l_display_name       cms_prod_cattype.cpc_startercard_dispname%TYPE;
      l_disp_name          cms_appl_pan.cap_disp_name%TYPE;
      excp_error           EXCEPTION;
      l_check_digit_req    cms_prod_cattype.CPC_CHECK_DIGIT_REQ%TYPE;
      l_programid_req      cms_prod_cattype.CPC_PROGRAMID_REQ%TYPE;
      l_encryption_flag    cms_prod_cattype.CPC_ENCRYPT_ENABLE%TYPE;
      l_product_funding    vms_order_lineitem.VOL_PRODUCT_FUNDING%TYPE;
      l_print_order        vms_order_details.vod_print_order%TYPE;
      l_count              pls_integer;
      l_accept_partial     vms_order_details.vod_accept_partial%TYPE;
      l_reject_flag         VARCHAR2(10) := 'N';
      l_start_control_number VMS_INVENTORY_CONTROL.VIC_CONTROL_NUMBER%TYPE;
      l_end_control_number VMS_INVENTORY_CONTROL.VIC_CONTROL_NUMBER%TYPE;
	  l_api_version			VMS_ORDER_DETAILS.vod_api_version%TYPE;
	  l_isrecipient_addrflag VMS_ORDER_DETAILS.vod_isrecipient_addrflag%TYPE;
	  l_address_line1 		VMS_ORDER_DETAILS.vod_address_line1%TYPE;
	  l_address_line2		VMS_ORDER_DETAILS.vod_address_line2%TYPE;
	  l_address_line3 		VMS_ORDER_DETAILS.vod_address_line3%TYPE;
	  l_city			    VMS_ORDER_DETAILS.vod_city%TYPE;
	  l_state			    VMS_ORDER_DETAILS.vod_state%TYPE;
	  l_postalcode			VMS_ORDER_DETAILS.vod_postalcode%TYPE;
	  l_country			    VMS_ORDER_DETAILS.vod_country%TYPE;
      l_state_code          gen_state_mast.gsm_state_code%TYPE;
      l_cntry_code          gen_cntry_mast.gcm_cntry_code%TYPE;
      l_card_id             cms_prod_cardpack.cpc_card_id%TYPE;
      L_DORMANCY_ONCORPORATELOAD   CMS_PROD_CATTYPE.CPC_DORMANCY_ONCORPORATELOAD%TYPE;
      l_delayed_accessto_firstload_flag CMS_PROD_CATTYPE.CPC_DELAYED_FIRSTLOAD_ACCESS%TYPE;
      l_delayed_access_date CMS_CUST_MAST.CCM_DELAYEDACCESS_DATE%TYPE;
      l_multikey_flag CMS_PROD_CATTYPE.CPC_MULTIKEY_FLAG%TYPE;
	   l_date_of_birth VMS_ORDER_DETAILS.vod_date_of_birth%type;
         l_id_type    VMS_ORDER_DETAILS.vod_id_type%type;
         l_id_number_chck varchar2(40);
         l_id_number  VMS_ORDER_DETAILS.vod_id_number%type;
         l_occupation	VMS_ORDER_DETAILS.vod_occupation%type;
         L_ssn_crddtls             transactionlog.ssn_fail_dtls%TYPE;
         L_resp_code               transactionlog.response_code%TYPE;
      L_STARTER_CARD cms_prod_cattype.CPC_STARTER_CARD%TYPE;
            l_first_name 		        vms_order_details.VOD_FIRSTNAME%type;
    l_last_name			        vms_order_details.VOD_LASTNAME%type;
    l_prod_portfolio    cms_prod_cattype.CPC_PRODUCT_PORTFOLIO%TYPE;
	--sn vms-7274
    l_expry_arry vmscms.EXPRY_ARRAY_TYP := vmscms.EXPRY_ARRAY_TYP ();
    l_sweep_flag vmscms.cms_prod_cattype.cpc_sweep_flag%type;
    l_isexpry_randm vmscms.cms_prod_cattype.cpc_expdate_randomization%type;
    l_qntity  NUMBER(10);
    --en vms-7274

      CURSOR cur_cards (prodcode   IN VARCHAR2,
                        prodcatg   IN NUMBER,
                        fromseq    IN NUMBER,
                        toseq      IN NUMBER)
      IS
        SELECT cap_appl_code,
               cap_prod_code,
               cap_prod_catg,
               cap_card_type,
               cap_cust_catg,
               cap_pan_code,
               cap_cust_code,
               cap_acct_id,
               cap_acct_no,
               cap_bill_addr,
               cap_pan_code_encr,
               cap_mask_pan,
               cap_appl_bran
           FROM cms_appl_pan_inv
           WHERE cap_prod_code = prodcode
                 AND cap_card_type = prodcatg
                 AND cap_issue_stat = 'N'
                 AND cap_card_seq  BETWEEN fromseq AND toseq;
			  /*(SELECT cap_card_seq
			  FROM
			    (SELECT a.cap_card_seq
			    FROM cms_appl_pan_inv a
			    WHERE a.cap_prod_code= prodcode
			    AND a.cap_card_type  = prodcatg
			    AND a.cap_issue_stat ='N'
				AND ROWNUM <= quantity + 1000000 /*Performance Issue Fix - Dead lock issue
			    ORDER BY dbms_random.value
			    )
			  WHERE ROWNUM <= quantity
			  ) FOR UPDATE;*/
	---Modified for VMS-1084 (Pan genaration process from sequential to shuffled - B2B & Retail)

      TYPE t_cards IS TABLE OF cur_cards%ROWTYPE;

      cards                t_cards;

      PROCEDURE lp_update_orderstat (p_orderid_in     IN     VARCHAR2,
                                     p_partnerid_in   IN     VARCHAR2,
                                     p_status_in      IN     VARCHAR2,
                                     p_errmsg_out     IN OUT VARCHAR2)
      AS
      BEGIN
         BEGIN
            UPDATE vms_order_details
               SET vod_order_status =
                      DECODE (p_status_in,
                              'P', 'Processing',
                              'R', 'Rejected',
                              'C', 'Completed',
                              'Y', 'Processed'),
                   vod_parent_oid = l_parent_id,
                   vod_error_msg = p_errmsg_out
             WHERE vod_order_id = p_orderid_in
                   AND vod_partner_id = p_partnerid_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                  'Error while selecting Order dtls:'
                  || SUBSTR (SQLERRM, 1, 200);
               ROLLBACK;
               RETURN;
         END;

         IF p_status_in = 'P'
         THEN
            BEGIN
               UPDATE vms_order_lineitem
                  SET vol_order_status = 'Processing',
                           vol_parent_oid = l_parent_id
                WHERE     vol_order_id = p_orderid_in
                      AND vol_partner_id = p_partnerid_in
                      AND vol_order_status = 'Received';
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                     'Error while selecting Order dtls:'
                     || SUBSTR (SQLERRM, 1, 200);
                  ROLLBACK;
                  RETURN;
            END;
         END IF;

         --p_errmsg_out := 'OK';
         COMMIT;
      END lp_update_orderstat;

      PROCEDURE lp_get_proxy (p_programid_in                 VARCHAR2,
                              p_proxylen_in                  VARCHAR2,
                              p_check_digit_request_in       VARCHAR2,
                              p_programid_req_in             VARCHAR2,
                              p_proxy_out                OUT VARCHAR2,
                              p_errmsg_out               OUT VARCHAR2)
      AS
         l_seq_no   cms_program_id_cnt.cpi_sequence_no%TYPE;
         l_row_id   ROWID;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         p_errmsg_out := 'OK';

         IF  p_programid_req_in = 'Y'
         THEN
            BEGIN
               SELECT cpi_sequence_no
                 INTO l_seq_no
                 FROM cms_program_id_cnt
                WHERE cpi_program_id = p_programid_in
               FOR UPDATE;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                     'Error while selecting cms_program_id_cnt:'
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;

            BEGIN
               p_proxy_out :=
                  fn_proxy_no (
                     NULL,
                     NULL,
                     p_programid_in,
                     l_seq_no,
                     p_inst_code_in,
                     p_user_code_in,
                     p_check_digit_request_in,
                     p_proxylen_in);


               IF p_proxy_out = '0'
               THEN
                  p_errmsg_out := 'proxy number should not be zero';
                  RETURN;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                     'Error while generating Proxy number:'
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;
         ELSIF  p_programid_req_in = 'N'
         THEN
            BEGIN

             SELECT ROWID,LPAD (cpc_prxy_cntrlno, p_proxylen_in, 0)
                 INTO l_row_id,p_proxy_out
                 FROM cms_prxy_cntrl
                WHERE  cpc_inst_code = p_inst_code_in
                      AND cpc_prxy_key = DECODE(p_proxylen_in,7,'PRXYCTRL7',
                                                              8,'PRXYCTRL8',
                                                              9,'PRXYCTRL',
                                                              10,'PRXYCTRL10',
                                                              11,'PRXYCTRL11',
                                                              12,'PRXYCTRL12')
             FOR UPDATE;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  p_errmsg_out :=
                     'Proxy number not defined for institution: '
                     || p_inst_code_in;
                  RETURN;
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                     'Error while selecting cms_prxy_cntrl:'
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;

            BEGIN
               UPDATE cms_prxy_cntrl
                  SET cpc_prxy_cntrlno = cpc_prxy_cntrlno + 1,
                      cpc_lupd_user = p_user_code_in,
                      cpc_lupd_date = SYSDATE
                WHERE ROWID =  l_row_id;


               IF SQL%ROWCOUNT = 0
               THEN
                  p_errmsg_out := 'Proxy number is not updated successfully';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                     'Error while updating cms_prxy_cntrl:'
                     || SUBSTR (SQLERRM, 1, 200);
            END;
         ELSE
            p_errmsg_out := 'Invalid length for proxy number generation';
         END IF;

         IF p_errmsg_out = 'OK'
         THEN
            COMMIT;
         ELSE
            ROLLBACK;
         END IF;
      END lp_get_proxy;

      PROCEDURE lp_virtual_process (
         p_lineitem_in    IN     VARCHAR2,
         p_productid_in   IN     VARCHAR2,
         l_encr_key_in    IN     VARCHAR2,
         p_cards_in       IN     t_cards,
         p_pins_in        IN     shuffle_array_typ,
         p_errmsg_out     OUT VARCHAR2,
         p_multikey_flag  IN VARCHAR2,
         p_profile_code   IN VARCHAR2,
         p_api_version    IN VARCHAR2,
         p_starter_card   IN VARCHAR2,
         p_prod_portfolio IN VARCHAR2,
         p_prod_type      IN VARCHAR2)
      AS
         l_proxy_no         cms_appl_pan.cap_proxy_number%TYPE;
         --l_ctrl_num         vms_product_serial_cntrl.vps_serl_numb%TYPE;
         --l_end_serl         vms_product_serial_cntrl.vps_end_serl%TYPE;
         l_respcode         VARCHAR2 (10);
         l_serials          shuffle_array_typ;
         l_proxy_pin_encr   vms_line_item_dtl.vli_proxy_pin_encr%TYPE;
         l_serial           cms_appl_pan.cap_serial_number%TYPE;
         l_audit_flag		    cms_transaction_mast.ctm_txn_log_flag%TYPE;
         l_exec_query                VARCHAR2 (20000);
         l_key_id    cms_appl_pan.cap_cvk_keyid%type;

/************************************************************************************************************

    * Modified by      : UBAIDUR RAHMAN.H
    * Modified Date    : 28-April-2021
    * Modified For     : VMS-4192 - Order V2 is failing for Virtual Product.
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR45_B0003

    * Modified by      : UBAIDUR RAHMAN.H
    * Modified Date    : 28-April-2021
    * Modified For     : VMS-5231 - Card Staus Update to Shipped Enrties Logging For Virtual Cards.
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR53_B0003

    * Modified By      : Mageshkumar.S
    * Modified Date    : 04-04-2022
    * Purpose          : VMS-5814:System not updating the CVK Key ID(Key used to generate the CVV) in CMS_APPL_PAN table for Virtual Card CVV generation
    * Reviewer         : Saravanakumar A.
    * Build Number     : R60.1 - BUILD 1
************************************************************************************************************/

      BEGIN
         p_errmsg_out := 'OK';

	--- Modified for VMS-4192 - Order V2 is failing for Virtual Product.

       /*  IF l_serl_flag = 'Y'
         THEN
            get_serials (p_productid_in,
                         p_cards_in.COUNT,
                         l_serials,
                         p_errmsg_out);

            IF p_errmsg_out <> 'OK'
            THEN
               p_errmsg_out := 'Error from get_serials:' || p_errmsg_out;
               RETURN;
            END IF;
         END IF;*/

         FOR i IN 1 .. p_cards_in.COUNT
         LOOP
            lp_get_proxy (l_progm_id,
                          l_prxy_length,
                          l_check_digit_req,
                          l_programid_req,
                          l_proxy_no,
                          p_errmsg_out);

            IF p_errmsg_out <> 'OK'
            THEN
               p_errmsg_out := 'Error from lp_get_proxy-' || p_errmsg_out;
               EXIT;
            END IF;

            --            IF l_serl_flag = 'Y'
            --            THEN
            --               BEGIN
            --                  SELECT vps_serl_numb, vps_end_serl
            --                    INTO l_ctrl_num, l_end_serl
            --                    FROM vms_product_serial_cntrl
            --                   WHERE vps_product_id = p_productid_in
            --                  FOR UPDATE;
            --               EXCEPTION
            --                  WHEN OTHERS
            --                  THEN
            --                     p_errmsg_out :=
            --                        'Error While fetching product_serial_cntrl :'
            --                        || SUBSTR (SQLERRM, 1, 200);
            --                     EXIT;
            --               END;
            --
            --               BEGIN
            --                  UPDATE vms_product_serial_cntrl
            --                     SET vps_serl_numb = vps_serl_numb + 1
            --                   WHERE vps_product_id = p_productid_in;
            --               EXCEPTION
            --                  WHEN OTHERS
            --                  THEN
            --                     p_errmsg_out :=
            --                        'Error While fetching product_serial_cntrl :'
            --                        || SUBSTR (SQLERRM, 1, 200);
            --                     EXIT;
            --               END;
            --            END IF;

            BEGIN

                           l_exec_query := 'SELECT  cbp_key_id from(SELECT  cbp_key_id from vmscms.cms_bin_param
                                           WHERE   cbp_param_type = ''Emboss Parameter''
                                           AND CBP_PROFILE_CODE = :p_profile_code
                                           ORDER BY CBP_INS_DATE '|| case when p_multikey_flag= 'Y' then 'DESC ' else 'ASC ' end||') where rownum=1' ;

                           EXECUTE IMMEDIATE l_exec_query
                           INTO l_key_id using p_profile_code;

                       EXCEPTION
                          WHEN OTHERS
                          THEN
                             p_errmsg_out :=
                                   'Error while executing l_exec_query '
                                || SUBSTR (SQLERRM, 1, 200);
                             EXIT;
    END;

            BEGIN

	    	--- Modified for VMS-4192 - Order V2 is failing for Virtual Product.
            SELECT seq_serial_no.nextval
                    INTO l_serial from dual;

             --IF l_serl_flag = 'Y' THEN
               UPDATE cms_appl_pan
                  SET cap_proxy_number = l_proxy_no,
                      cap_serial_number = l_serial, ----- seq_serial_no.nextval --l_serials (i)           --l_ctrl_num
		      cap_form_factor = 'V',
              cap_cvk_keyid = l_key_id
                WHERE     cap_pan_code = p_cards_in (i).cap_pan_code
                      AND cap_inst_code = p_inst_code_in
                      AND cap_mbr_numb = l_mbr_numb;

               /* ELSE
                  UPDATE cms_appl_pan
                  SET cap_proxy_number = l_proxy_no
                WHERE     cap_pan_code = p_cards_in (i).cap_pan_code
                      AND cap_inst_code = p_inst_code_in
                      AND cap_mbr_numb = l_mbr_numb;
             END IF;*/
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                     'Error While updating proxy dtls :'
                     || SUBSTR (SQLERRM, 1, 200);
                  EXIT;
            END;

 IF p_api_version = 'V2' and p_prod_portfolio not like '%GPR%'  THEN
            BEGIN
               UPDATE cms_cust_mast
                  SET ccm_kyc_flag = 'A'
                WHERE ccm_cust_code = p_cards_in (i).cap_cust_code
                      AND ccm_inst_code = p_inst_code_in;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                     'Error While updating kyc flag :'
                     || SUBSTR (SQLERRM, 1, 200);
                  EXIT;
            END;
  END IF;

            BEGIN
               INSERT INTO cms_smsandemail_alert (csa_inst_code,
                                                  csa_pan_code,
                                                  csa_pan_code_encr,
                                                  csa_loadorcredit_flag,
                                                  csa_lowbal_flag,
                                                  csa_negbal_flag,
                                                  csa_highauthamt_flag,
                                                  csa_dailybal_flag,
                                                  csa_insuff_flag,
                                                  csa_incorrpin_flag,
                                                  csa_fast50_flag,
                                                  csa_fedtax_refund_flag,
                                                  csa_deppending_flag,
                                                  csa_depaccepted_flag,
                                                  csa_deprejected_flag,
                                                  csa_ins_user,
                                                  csa_ins_date)
                    VALUES (p_inst_code_in,
                            p_cards_in (i).cap_pan_code,
                            p_cards_in (i).cap_pan_code_encr,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            p_user_code_in,
                            SYSDATE);
            EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN NULL;
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                     'Error While Inserting smsandemail_alert :'
                     || SUBSTR (SQLERRM, 1, 200);
                  EXIT;
            END;

            BEGIN
               INSERT INTO cms_pan_acct (cpa_inst_code,
                                         cpa_cust_code,
                                         cpa_acct_id,
                                         cpa_acct_posn,
                                         cpa_pan_code,
                                         cpa_mbr_numb,
                                         cpa_ins_user,
                                         cpa_lupd_user,
                                         cpa_pan_code_encr)
                    VALUES (p_inst_code_in,
                            p_cards_in (i).cap_cust_code,
                            p_cards_in (i).cap_acct_id,
                            l_const,
                            p_cards_in (i).cap_pan_code,
                            l_mbr_numb,
                            p_user_code_in,
                            p_user_code_in,
                            p_cards_in (i).cap_pan_code_encr);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                     'Error While Inserting pan_acct :'
                     || SUBSTR (SQLERRM, 1, 200);
                  EXIT;
            END;

            --- Added for VMS-5231 - Card Staus Update to Shipped Enrties Logging For Virtual Cards.
            BEGIN
                  SELECT nvl(CTM_TXN_LOG_FLAG,'T')
                    INTO L_AUDIT_FLAG
                    FROM CMS_TRANSACTION_MAST
                   WHERE CTM_INST_CODE = 1
                     AND CTM_DELIVERY_CHANNEL = '05'
                     AND CTM_TRAN_CODE = '06';
            EXCEPTION
                WHEN OTHERS
               THEN
                  p_errmsg_out :=
                     'Error While checkin login txn flag:'
                     || SUBSTR (SQLERRM, 1, 200);
                  EXIT;
            END;

            IF L_AUDIT_FLAG = 'T'         --- Modified for VMS-5231 - Card Staus Update to Shipped Enrties Logging For Virtual Cards.
            THEN

            BEGIN
               sp_log_cardstat_chnge (p_inst_code_in,
                                      p_cards_in (i).cap_pan_code,
                                      p_cards_in (i).cap_pan_code_encr,
                                      LPAD (seq_auth_id.NEXTVAL, 6, '0'),
                                      '06',
                                      NULL,
                                      NULL,
                                      NULL,
                                      l_respcode,
                                      p_errmsg_out);

               IF p_errmsg_out <> 'OK'
               THEN
                  p_errmsg_out :=
                     'Error while logging appl shipped txn:' || p_errmsg_out;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                     'Error While login shipped txn :'
                     || SUBSTR (SQLERRM, 1, 200);
                  EXIT;
            END;

            END IF;

            BEGIN

	    	--- Modified for VMS-4192 - Order V2 is failing for Virtual Product.
--               l_proxy_pin_encr :=
--                  fn_emaps_main_b2b (l_proxy_no || '|' || p_pins_in (i),
--                                     l_encr_key_in);
               l_proxy_pin_encr :=
                  fn_emaps_main_b2b ('serialNumber='||l_serial|| '&' ||'PIN='||l_proxy_no,
                                     l_encr_key_in);

               INSERT INTO vms_line_item_dtl (vli_pan_code,
                                              vli_order_id,
                                              vli_partner_id,
                                              vli_lineitem_id,
                                              vli_pin,
                                              vli_proxy_pin_encr,
                                              vli_proxy_pin_hash,
                                              vli_parent_oid)
                    VALUES (p_cards_in (i).cap_pan_code,
                            p_order_id_in,
                            p_partner_id_in,
                            p_lineitem_in,
                            p_pins_in (i),
                            l_proxy_pin_encr,
                            gethash (l_proxy_pin_encr),
                            l_parent_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                     'Error While line item dtls :'
                     || SUBSTR (SQLERRM, 1, 200);
                  EXIT;
            END;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg_out := 'Main Excp :' || SUBSTR (SQLERRM, 1, 200);
      END LP_VIRTUAL_PROCESS;
   BEGIN
      p_resp_msg_out := 'OK';
      l_parent_id:=seq_parent_id.nextval;

      BEGIN
         BEGIN
            SELECT vod_order_default_card_status,
                   vod_channel_id,
                   vod_activation_code,DECODE(UPPER(VOD_PRINT_ORDER),'TRUE','P','F'),DECODE(UPPER(vod_accept_partial),'TRUE','Y','N'),
				   vod_api_version,vod_isrecipient_addrflag,vod_address_line1,vod_address_line2,vod_address_line3,
				   vod_city,fn_dmaps_main(vod_state),vod_postalcode,fn_dmaps_main(vod_country),VOD_DATE_OF_BIRTH, VOD_ID_TYPE, VOD_ID_NUMBER
                   , VOD_OCCUPATION	, VOD_FIRSTNAME , VOD_LASTNAME
              INTO l_card_stat, l_channel_code,l_activation_code, l_print_order,l_accept_partial,l_api_version,l_isrecipient_addrflag,		  l_address_line1,l_address_line2,
	      		l_address_line3,l_city,l_state,l_postalcode,l_country,l_date_of_birth, l_id_type, l_id_number
                , l_occupation, l_first_name , l_last_name
              FROM vms_order_details
             WHERE     vod_order_id = p_order_id_in
                   AND vod_partner_id = p_partner_id_in
                   AND vod_order_status = 'Received';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_resp_msg_out := 'Invalid Order';
               RETURN;
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                  'Error While selecting order details:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_error;
         END;

         lp_update_orderstat (p_order_id_in,
                              p_partner_id_in,
                              l_proc_stat,
                              p_resp_msg_out);

         IF p_resp_msg_out <> 'OK'
         THEN
            RAISE excp_error;
         END IF;

         BEGIN
            SELECT ccs_stat_code
              INTO l_card_stat
              FROM cms_card_stat
             WHERE ccs_stat_desc = UPPER (l_card_stat);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_card_stat := NULL;
         END;

         BEGIN
            SELECT ctm_delivery_channel,
                   ctm_tran_code,
                   ctm_tran_desc,
                   ctm_credit_debit_flag
              INTO l_delivery_channel,
                   l_txn_code,
                   l_tran_desc,
                   l_drcr_flag
              FROM cms_transaction_mast
             WHERE ctm_inst_code = p_inst_code_in
                   AND (ctm_delivery_channel, ctm_tran_code) IN
                          (SELECT vft_channel_code, vft_tran_code
                             FROM vms_fsapi_trans_mast
                            WHERE vft_channel_desc = l_channel_code
                                  AND vft_request_type = 'INITIAL LOAD');
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                  'Error While selecting channel code:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_error;
         END;

         FOR l_idx
            IN (SELECT vol_product_id,vol_embossedline,vol_package_id,
						vol_quantity,vol_product_funding,vol_fund_amount,vol_line_item_id,
						vol_denomination,vol_order_id,vol_partner_id,vol_recipient_firstname,
						vol_recipient_lastname,VOL_RECIPIENT_MIDDLEINITIAL,VOL_RECIPIENT_EMAIL,VOL_RECIPIENT_PHONE,VOL_DELAYEDACCESS_DATE
                  FROM vms_order_lineitem
                 WHERE     vol_order_id = p_order_id_in
                       AND vol_partner_id = p_partner_id_in
                       AND vol_order_status = 'Processing')
         LOOP
            BEGIN
               v_resp_msg_out := 'OK';
               l_count := 0;
               l_card_id := NULL;

               BEGIN
                  SELECT cattype.cpc_prod_code,
                         cattype.cpc_card_type,
                         cattype.cpc_profile_code,
                         cattype.cpc_proxy_length,
                         cattype.cpc_program_id,
                         cattype.cpc_check_digit_req,
                         cattype.cpc_programid_req,
                         NVL(cattype.cpc_ccf_serial_flag, 'N'),
                         NVL(cattype.cpc_startercard_dispname, 'INSTANT CARD'),
                         NVL(cattype.CPC_ENCRYPT_ENABLE,'N'),
                         NVL(cattype.CPC_DORMANCY_ONCORPORATELOAD,'N'),
                         NVL(cattype.CPC_DELAYED_FIRSTLOAD_ACCESS,'N'),
                         NVL(cattype.CPC_MULTIKEY_FLAG,'N'),
                         cattype.CPC_STARTER_CARD,
                         NVL(cattype.CPC_PRODUCT_PORTFOLIO,'N'),
                         NVL(cattype.cpc_expdate_randomization,'N'), --Added for VMS-7274
                         NVL(cattype.cpc_sweep_flag,'N')             --Added for VMS-7274
                    INTO l_prod_code,
                         l_card_type,
                         l_profile_code,
                         l_prxy_length,
                         l_progm_id,
                         l_check_digit_req,
                         l_programid_req,
                         l_serl_flag,
                         l_display_name,
                         l_encryption_flag,
                         L_DORMANCY_ONCORPORATELOAD,
                         l_delayed_accessto_firstload_flag,
                         l_multikey_flag,
                         L_STARTER_CARD,
                         l_prod_portfolio,
                         l_isexpry_randm,   --Added for VMS-7274
                         l_sweep_flag       --Added for VMS-7274
                    FROM cms_prod_cattype cattype , cms_prod_mast prod
                   WHERE     cattype.cpc_product_id = l_idx.vol_product_id
                         AND prod.cpm_inst_code = cattype.cpc_inst_code
                         AND prod.cpm_prod_code = cattype.cpc_prod_code;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resp_msg_out :=
                        'Error while selecting product dtls:'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_error;
               END;

               BEGIN
                  SELECT cbp_param_value
                    INTO l_prod_type
                    FROM cms_bin_param
                   WHERE cbp_profile_code = l_profile_code
                         AND cbp_param_name = 'Card Type';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resp_msg_out :=
                        'Error while selecting product type:'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_error;
               END;

             IF l_api_version = 'V2' and (l_prod_portfolio like '%GPR%') and (L_ID_TYPE = 'SSN' or (l_first_name is not null and l_last_name is not null and l_date_of_birth is not null))
		THEN
           BEGIN
           select decode( L_ID_TYPE ,'SSN',vmscms.fn_dmaps_main(L_ID_NUMBER), null ) into l_id_number_chck from dual;
          sp_check_ssn_threshold (p_inst_code_in,
                                  l_id_number_chck,
                                  l_prod_code,
                                  l_card_type,
                                  'EN',
                                  L_ssn_crddtls,
                                  L_resp_code,
                                  v_resp_msg_out,
                                 gethash(UPPER(l_first_name)||UPPER(l_last_name)||to_date(l_date_of_birth,'mmddyyyy')),
                                 l_idx.vol_quantity
                                 );
          IF v_resp_msg_out <> 'OK'
          THEN
             L_resp_code := '158';
             RAISE excp_error;
          END IF;
       EXCEPTION
          WHEN excp_error
          THEN
            RAISE;
          WHEN OTHERS
          THEN
             L_resp_code := '21';
             v_resp_msg_out := 'Error from SSN check- ' || SUBSTR (SQLERRM, 1, 200);
             RAISE excp_error;
       END;
		END IF;
				IF l_prod_type = 'V'
               THEN
                  BEGIN
--                     SELECT cbp_param_value
--                       INTO l_encr_key
--                       FROM cms_bin_param
--                      WHERE cbp_profile_code = l_profile_code
--                            AND cbp_param_name = 'Virtual Card EncrKey';

		      SELECT cip_param_value
		        INTO l_encr_key
			FROM cms_inst_param
		       WHERE cip_inst_code = p_inst_code_in
		       	 AND cip_param_key = 'FSAPIKEY';



                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error while selecting FSAPI EncrKey:'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_error;
                  END;

		  --- Added for  VMS-5088 - Virtual Order Process via V2 should log the
     			---		cardpack id in APPL PAN table.

                  IF l_api_version = 'V2'
                  THEN

                      BEGIN
                              SELECT cpc_card_id
                                INTO l_card_id
                                FROM cms_prod_cardpack
                               WHERE cpc_inst_code = p_inst_code_in
                                 AND cpc_prod_code = l_prod_code
                                 AND cpc_card_details = l_idx.vol_package_id ;
                        EXCEPTION
                            WHEN NO_DATA_FOUND
                            THEN
                            v_resp_msg_out   := 'No card id configured for package id ' || l_idx.vol_package_id;
                            RAISE excp_error;

                            WHEN OTHERS THEN
                            v_resp_msg_out   := 'Error while selecting card id for Line Item' ||
                                                   SUBSTR (SQLERRM, 1, 200);
                            RAISE excp_error;
                        END;

                 END IF;

               END IF;

               IF l_idx.vol_embossedline IS NULL
               THEN
                  BEGIN
                     SELECT DECODE(l_encryption_flag,'N',NVL (vpd_field_value, l_display_name),FN_EMAPS_MAIN(NVL (vpd_field_value, l_display_name)))
                       INTO l_disp_name
                       FROM vms_packageid_detl
                      WHERE vpd_package_id = l_idx.vol_package_id
                            AND vpd_field_key = 'embossLine3';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_disp_name := l_display_name;
                  END;
               ELSE
                  l_disp_name := l_idx.vol_embossedline;
               END IF;

               BEGIN
                  vmsfunutilities.get_expiry_date (p_inst_code_in,
                                                   l_prod_code,
                                                   l_card_type,
                                                   l_profile_code,
                                                   l_expry_date,
                                                   v_resp_msg_out);

                  IF v_resp_msg_out <> 'OK'
                  THEN
                     RAISE excp_error;
                  END IF;
               EXCEPTION
                  WHEN excp_error
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_resp_msg_out :=
                        'Error while calling vmsfunutilities.get_expiry_date'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_error;
               END;

                   SELECT TRUNC (DBMS_RANDOM.VALUE (1000000000, 9999999999)) num
                     BULK COLLECT INTO l_pins
                     FROM DUAL
               CONNECT BY LEVEL <= l_idx.vol_quantity;

              BEGIN
                get_inventory_control_number(l_prod_code,
                                      l_card_type,
                                      l_idx.vol_quantity,
                                      l_start_control_number ,
                                      l_end_control_number ,
                                      v_resp_msg_out );
                 IF v_resp_msg_out <> 'OK' THEN
                    RAISE excp_error;
                 END IF;

              EXCEPTION
                WHEN excp_error THEN
                    RAISE;
                WHEN OTHERS THEN
                 v_resp_msg_out :=
                        'Error while calling get_inventory_control_number '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_error;
              END;

               OPEN cur_cards (l_prod_code, l_card_type, l_start_control_number,l_end_control_number);

               LOOP
                  FETCH cur_cards
                  BULK COLLECT INTO cards
                  LIMIT 1000;

                  EXIT WHEN cards.COUNT = 0;

                  l_count := l_count + cards.count;

				  --SN: Added for VMS-7274
                  l_qntity:=cards.count;

                  IF l_isexpry_randm = 'Y' AND l_sweep_flag='N' THEN
                    BEGIN
                        vmscms.vmsfunutilities.get_expiry_date (p_inst_code_in,
                                                                l_prod_code,
                                                                l_card_type,
                                                                l_profile_code,
                                                                l_qntity,
                                                                l_expry_arry,
                                                                v_resp_msg_out);

                        IF v_resp_msg_out <> 'OK'
                        THEN
                            EXIT;
                        END IF;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_resp_msg_out :=
                                'Error while calling get_expiry_date_1' || SUBSTR (SQLERRM, 1, 200);
                        EXIT;
                    END;
                  ELSE
                    SELECT l_expry_date
                      BULK COLLECT INTO l_expry_arry
                      FROM DUAL
                    CONNECT BY LEVEL <= l_qntity;
                  END IF;
                  --EN: Added for VMS-7274

                  BEGIN
                     FORALL i IN 1 .. cards.COUNT
                        INSERT ALL
                          INTO cms_appl_pan (cap_appl_code,
                                             cap_prod_code,
                                             cap_prod_catg,
                                             cap_card_type,
                                             cap_cust_catg,
                                             cap_pan_code,
                                             cap_cust_code,
                                             cap_expry_date,
                                             cap_acct_id,
                                             cap_acct_no,
                                             cap_bill_addr,
                                             cap_pan_code_encr,
                                             cap_mask_pan,
                                             cap_appl_bran,
                                             cap_inst_code,
                                             cap_asso_code,
                                             cap_inst_type,
                                             cap_mbr_numb,
                                             cap_disp_name,
                                             cap_addon_stat,
                                             cap_addon_link,
                                             cap_mbr_link,
                                             cap_tot_acct,
                                             cap_pangen_date,
                                             cap_pangen_user,
                                             cap_ins_user,
                                             cap_lupd_user,
                                             cap_issue_flag,
                                             cap_card_stat,
                                             cap_active_date,
                                             cap_startercard_flag,
                                             cap_activation_code,
                                             CAP_FIRSTTIME_TOPUP,
                                             CAP_ORDER_TYPE,
                                             cap_cardpack_id,
                                             cap_last_corporate_loaddate)     --- Added for VMS-5327
                        VALUES (cards (i).cap_appl_code,
                                cards (i).cap_prod_code,
                                cards (i).cap_prod_catg,
                                cards (i).cap_card_type,
                                cards (i).cap_cust_catg,
                                cards (i).cap_pan_code,
                                cards (i).cap_cust_code,
								l_expry_arry(i), --l_expry_date, --Modified for VMS-7274
                                cards (i).cap_acct_id,
                                cards (i).cap_acct_no,
                                cards (i).cap_bill_addr,
                                cards (i).cap_pan_code_encr,
                                cards (i).cap_mask_pan,
                                cards (i).cap_appl_bran,
                                p_inst_code_in,
                                l_const,
                                l_const,
                                l_mbr_numb,
                                l_disp_name,
                                'P',
                                cards (i).cap_pan_code,
                                l_mbr_numb,
                                l_const,
                                SYSDATE,
                                p_user_code_in,
                                p_user_code_in,
                                p_user_code_in,
                                'Y',
                                l_card_stat,
                                DECODE (l_card_stat, '1', SYSDATE),
                                CASE WHEN l_api_version = 'V2' and l_prod_portfolio like '%GPR%' and l_prod_type = 'V'
                                THEN L_STARTER_CARD ELSE
                                'Y' END,
                                l_activation_code,
                                decode(l_idx.VOL_PRODUCT_FUNDING,'1','Y','N'),
                                l_print_order,l_card_id,
                                CASE
                                WHEN (l_delivery_channel = '17' and l_txn_code = '04' and L_DORMANCY_ONCORPORATELOAD = 'Y')
                                AND  (l_idx.VOL_PRODUCT_FUNDING = '1' OR (l_idx.VOL_PRODUCT_FUNDING ='2' AND l_idx.vol_fund_amount = '1' and l_prod_type = 'V' and l_card_stat = '1'))
                                THEN SYSDATE
                                ELSE NULL
                                END )
                          INTO cms_cardissuance_status (ccs_inst_code,
                                                        ccs_pan_code,
                                                        ccs_card_status,
                                                        ccs_ins_user,
                                                        ccs_lupd_user,
                                                        ccs_pan_code_encr,
                                                        ccs_lupd_date,
                                                        ccs_appl_code)
                        VALUES (p_inst_code_in,
                                cards (i).cap_pan_code,
                                DECODE (l_prod_type, 'V', '15', '2'),
                                p_user_code_in,
                                p_user_code_in,
                                cards (i).cap_pan_code_encr,
                                SYSDATE,
                                cards (i).cap_appl_code)
                           SELECT * FROM DUAL;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error While Inserting Cards :'
                           || SUBSTR (SQLERRM, 1, 200);
                        EXIT;
                  END;

                  BEGIN
                     FORALL i IN 1 .. cards.COUNT
                        UPDATE cms_appl_mast
                           SET cam_appl_stat = 'O',
                               cam_lupd_user = p_user_code_in,
                               cam_process_msg = 'SUCCESSFUL'
                         WHERE cam_inst_code = p_inst_code_in
                               AND cam_appl_code = cards (i).cap_appl_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error While Updating Appl Stat:'
                           || SUBSTR (SQLERRM, 1, 200);
                        EXIT;
                  END;

                  BEGIN
                     FORALL i IN 1 .. cards.COUNT
                        UPDATE cms_appl_pan_inv
                           SET cap_issue_stat = 'I'
                         WHERE cap_pan_code = cards (i).cap_pan_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error While Updating Cards Issue Stat:'
                           || SUBSTR (SQLERRM, 1, 200);
                        END;

       IF l_delayed_accessto_firstload_flag = 'Y'
       AND l_idx.VOL_PRODUCT_FUNDING = '1' AND NVL(UPPER(l_api_version),'V1') = 'V1'
       THEN

       BEGIN

    SELECT LAST_DAY(SYSDATE)
      INTO l_delayed_access_date
      FROM dual;

	EXCEPTION
        WHEN OTHERS THEN
          v_resp_msg_out := 'Error while selecting last day in a month' || SUBSTR(SQLERRM,1,200);
          EXIT;
    END;

    IF NVL(UPPER(l_api_version),'V1') = 'V1'
       THEN
       BEGIN
                  FORALL i IN 1 .. cards.COUNT
                        UPDATE cms_cust_mast
                           SET ccm_delayedaccess_date = l_delayed_access_date
                         WHERE ccm_inst_code = p_inst_code_in
						   AND ccm_cust_code = cards (i).cap_cust_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error While Updating System Generated Profile Flag in CMS_CUST_MAST:'
                           || SUBSTR (SQLERRM, 1, 200);
                        EXIT;
                  END;
       END IF;


       END IF;


		IF l_api_version = 'V2'
		THEN

		IF NVL(UPPER(l_isrecipient_addrflag),'FALSE') = 'TRUE'
        THEN
            BEGIN
                SELECT gsm_state_code
                  INTO l_state_code
                  FROM gen_state_mast
                  WHERE gsm_inst_code = 1
                  AND gsm_switch_state_code = upper(l_state);

                  SELECT gcm_cntry_code
                  INTO l_cntry_code
                  FROM gen_cntry_mast
                  WHERE gcm_inst_code = 1
                  AND gcm_switch_cntry_code = upper(l_country);
             EXCEPTION
                WHEN OTHERS THEN
                    v_resp_msg_out :=
                           'Error While Selecting CountryCode/StateCode:'
                           || SUBSTR (SQLERRM, 1, 200);
                    EXIT;
             END;

			BEGIN
				FORALL i IN 1 .. cards.COUNT
               INSERT INTO cms_addr_mast (cam_inst_code,
                                          cam_cust_code,
                                          cam_addr_code,
                                          cam_add_one,
                                          cam_add_two,
                                          cam_add_three,
                                          cam_pin_code,
                                          CAM_EMAIL,
                                          CAM_PHONE_ONE,
                                          CAM_MOBL_ONE,
                                          cam_cntry_code,
                                          cam_city_name,
                                          cam_addr_flag,
                                          cam_state_code,
                                          cam_ins_user,
                                          cam_lupd_user,
                                          cam_comm_type,
                                          cam_state_switch,
										  CAM_ADD_ONE_ENCR,
                                          CAM_ADD_TWO_ENCR,
                                          CAM_CITY_NAME_ENCR,
                                          CAM_PIN_CODE_ENCR,
                                          CAM_EMAIL_ENCR)
                                    SELECT cam_inst_code,
                                          cam_cust_code,
                                          seq_addr_code.NEXTVAL,
                                          l_address_line1,
                                          l_address_line2,
                                          l_address_line3,
                                          l_postalcode,
                                          l_idx.VOL_RECIPIENT_EMAIL,
                                          l_idx.VOL_RECIPIENT_PHONE,
                                          l_idx.VOL_RECIPIENT_PHONE,
                                          l_cntry_code,
                                          l_city,
                                          'O',
                                          l_state_code,
                                          cam_ins_user,
                                          cam_lupd_user,
                                          cam_comm_type,
                                          l_state,
										  DECODE(l_encryption_flag,'N',fn_emaps_main(l_address_line1),l_address_line1),
                                          DECODE(l_address_line2,NULL,NULL,DECODE(l_encryption_flag,'N',fn_emaps_main(l_address_line2),l_address_line2)),
                                          DECODE(l_city,NULL,NULL,DECODE(l_encryption_flag,'N',fn_emaps_main(l_city),l_city)),
                                          DECODE(l_postalcode,NULL,NULL,DECODE(l_encryption_flag,'N',fn_emaps_main(l_postalcode),l_postalcode)),
                                          DECODE(l_encryption_flag,'N',fn_emaps_main(l_idx.VOL_RECIPIENT_EMAIL),l_idx.VOL_RECIPIENT_EMAIL)
							FROM CMS_ADDR_MAST
							WHERE cam_inst_code = p_inst_code_in
						   AND cam_cust_code = cards(i).cap_cust_code
						   AND cam_addr_flag = 'P';

            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_msg_out :=
                     'Error while inserting address dtls:'
                     || SUBSTR (SQLERRM, 1, 200);
                  EXIT;
            END;


				  BEGIN
                     FORALL i IN 1 .. cards.COUNT
                        UPDATE cms_addr_mast
                           SET cam_add_one = l_address_line1,
							   cam_add_two = l_address_line2,
							   cam_add_three = l_address_line3,
							   cam_city_name = l_city,
							   cam_state_switch = l_state,
							   cam_pin_code = l_postalcode,
                               CAM_EMAIL = l_idx.VOL_RECIPIENT_EMAIL,
                               CAM_PHONE_ONE = l_idx.VOL_RECIPIENT_PHONE,
                               CAM_MOBL_ONE = l_idx.VOL_RECIPIENT_PHONE,
							   cam_cntry_code =  l_cntry_code,
                               cam_state_code = l_state_code,
							   cam_add_one_encr = DECODE(l_encryption_flag,'N',fn_emaps_main(l_address_line1),l_address_line1),
							   cam_add_two_encr = DECODE(l_address_line2,NULL,NULL,DECODE(l_encryption_flag,'N',fn_emaps_main(l_address_line2),l_address_line2)),
							   cam_city_name_encr = DECODE(l_city,NULL,NULL,DECODE(l_encryption_flag,'N',fn_emaps_main(l_city),l_city)),
                               cam_pin_code_encr = DECODE(l_postalcode,NULL,NULL,DECODE(l_encryption_flag,'N',fn_emaps_main(l_postalcode),l_postalcode)),
                               CAM_EMAIL_ENCR =   DECODE(l_encryption_flag,'N',fn_emaps_main(l_idx.VOL_RECIPIENT_EMAIL),l_idx.VOL_RECIPIENT_EMAIL)
                         WHERE cam_inst_code = p_inst_code_in
						   AND cam_cust_code = cards (i).cap_cust_code
						   AND cam_addr_flag = 'P';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error While Updating CMS_ADDR_MAST:'
                           || SUBSTR (SQLERRM, 1, 200);
                        EXIT;
                  END;

                  			--- Added for VMS-5253 / VMS-5372
                  BEGIN
                  FORALL i IN 1 .. cards.COUNT
                        UPDATE cms_cust_mast
                           SET ccm_system_generated_profile = 'N',
                           ccm_delayedaccess_date=l_idx.VOL_DELAYEDACCESS_DATE,
                           CCM_SSN_ENCR = L_ID_NUMBER,
                           ccm_ssn = DECODE(L_ID_NUMBER,null,null,(FN_MASKACCT_SSN(p_inst_code_in,fn_dmaps_main(L_ID_NUMBER),0))),
                           ccm_occupation = l_occupation,
                           ccm_id_type = l_id_type,
                           ccm_birth_date = to_date(l_date_of_birth,'mmddyyyy'),
                           ccm_kyc_flag  = CASE WHEN l_prod_portfolio like '%GPR%' and l_prod_type = 'V' THEN 'Y' ELSE CCM_KYC_FLAG END,
                           ccm_kyc_source = '05',
                           CCM_FLNAMEDOB_HASHKEY = gethash(UPPER(l_first_name)||UPPER(l_last_name)||to_date(l_date_of_birth,'mmddyyyy'))
                         WHERE ccm_inst_code = p_inst_code_in
						   AND ccm_cust_code = cards (i).cap_cust_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error While Updating System Generated Profile Flag in CMS_CUST_MAST:'
                           || SUBSTR (SQLERRM, 1, 200);
                        EXIT;
                  END;
				  IF l_prod_portfolio like '%GPR%' and l_prod_type = 'V' THEN          --Added for VMS-6815
                  BEGIN
                  FORALL i IN 1 .. cards.COUNT
                  UPDATE cms_caf_info_entry
                  SET cci_kyc_flag = 'Y',
                            cci_process_msg = 'Successful',
                            cci_kyc_reg_date = sysdate
                            WHERE
                            CCI_APPL_CODE = to_char(cards(i).cap_appl_code) AND cci_inst_code = p_inst_code_in;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error While Updating cms_caf_info_entry:'
                           || SUBSTR (SQLERRM, 1, 200);
                        EXIT;
                  END;
                  END IF;

		  END IF;

          IF NVL(UPPER(l_isrecipient_addrflag),'FALSE') = 'FALSE'
            THEN
            BEGIN
                     FORALL i IN 1 .. cards.COUNT
                        UPDATE cms_addr_mast
                           SET
                               CAM_EMAIL = NVL(l_idx.VOL_RECIPIENT_EMAIL,CAM_EMAIL),
                               CAM_PHONE_ONE = NVL(l_idx.VOL_RECIPIENT_PHONE,CAM_PHONE_ONE),
                               CAM_MOBL_ONE = NVL(l_idx.VOL_RECIPIENT_PHONE,CAM_MOBL_ONE),
                               CAM_EMAIL_ENCR =   DECODE(l_idx.VOL_RECIPIENT_EMAIL,NULL,NULL,DECODE(l_encryption_flag,'N',fn_emaps_main(l_idx.VOL_RECIPIENT_EMAIL),
                                                    l_idx.VOL_RECIPIENT_EMAIL))
                         WHERE cam_inst_code = p_inst_code_in
						   AND cam_cust_code = cards (i).cap_cust_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error While Updating CMS_ADDR_MAST:'
                           || SUBSTR (SQLERRM, 1, 200);
                        EXIT;
                  END;
            END IF;

		  IF  l_idx.vol_recipient_firstname IS NOT NULL
		  THEN

		  BEGIN
                     FORALL i IN 1 .. cards.COUNT
                        UPDATE cms_cust_mast
                           SET ccm_first_name = l_idx.vol_recipient_firstname,
							   ccm_mid_name = nvl(l_idx.VOL_RECIPIENT_MIDDLEINITIAL,ccm_mid_name),
							   ccm_last_name = nvl(l_idx.vol_recipient_lastname,ccm_last_name),
							   ccm_first_name_encr = DECODE(l_encryption_flag,'N',fn_emaps_main(l_idx.vol_recipient_firstname),l_idx.vol_recipient_firstname),
							   ccm_last_name_encr = DECODE(l_idx.vol_recipient_lastname,NULL,ccm_last_name_encr,
                               DECODE(l_encryption_flag,'N',fn_emaps_main(l_idx.vol_recipient_lastname),l_idx.vol_recipient_lastname)),
                               ccm_delayedaccess_date=l_idx.VOL_DELAYEDACCESS_DATE
                         WHERE ccm_inst_code = p_inst_code_in
						   AND ccm_cust_code = cards (i).cap_cust_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error While Updating CMS_ADDR_MAST:'
                           || SUBSTR (SQLERRM, 1, 200);
                        EXIT;
                  END;

                  ELSE

                  BEGIN
                  FORALL i IN 1 .. cards.COUNT
                        UPDATE cms_cust_mast
                           SET ccm_delayedaccess_date=l_idx.VOL_DELAYEDACCESS_DATE
                         WHERE ccm_inst_code = p_inst_code_in
						   AND ccm_cust_code = cards (i).cap_cust_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error While Updating System Generated Profile Flag in CMS_CUST_MAST:'
                           || SUBSTR (SQLERRM, 1, 200);
                        EXIT;
                  END;
		 END IF;
	END IF;

                  IF l_prod_type = 'V'
                  THEN
                     lp_virtual_process (l_idx.vol_line_item_id,
                                         l_idx.vol_product_id,
                                         l_encr_key,
                                         cards,
                                         l_pins,
                                         v_resp_msg_out,
                                         l_multikey_flag,
                                         l_profile_code,
                                         l_api_version,
                                         L_STARTER_CARD,
                                         l_prod_portfolio,
                                         l_prod_type
										 );

                     IF v_resp_msg_out <> 'OK'
                     THEN
                        v_resp_msg_out :=
                           'Error from lp_virtual_process: '
                           || v_resp_msg_out;
                        EXIT;
                     END IF;
                  ELSE
                     BEGIN
                        FORALL i IN 1 .. cards.COUNT
                           INSERT INTO vms_line_item_dtl (vli_pan_code,
                                                          vli_order_id,
                                                          vli_partner_id,
                                                          vli_lineitem_id,
                                                          vli_pin,
                                                          vli_proxy_pin_encr,
                                                          vli_parent_oid)
                                VALUES (cards (i).cap_pan_code,
                                        p_order_id_in,
                                        p_partner_id_in,
                                        l_idx.vol_line_item_id,
                                        NULL,--l_pins (i),
                                        NULL,
                                        l_parent_id);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_resp_msg_out :=
                              'Error While line item dtls :'
                              || SUBSTR (SQLERRM, 1, 200);
                           EXIT;
                     END;
                  END IF;

                 IF l_idx.VOL_PRODUCT_FUNDING ='1' OR (l_idx.VOL_PRODUCT_FUNDING ='2' AND l_idx.vol_fund_amount = '1' and l_prod_type = 'V' and l_card_stat = '1')   -- Modified for VMS-4192
                 THEN

                  BEGIN
                     FORALL i IN 1 .. cards.COUNT
                        UPDATE cms_acct_mast
                           SET cam_acct_bal = l_idx.vol_denomination,
                               cam_ledger_bal = l_idx.vol_denomination,
			                          CAM_INITIALLOAD_AMT = l_idx.vol_denomination,
                                cam_first_load_date = sysdate
                         WHERE cam_inst_code = p_inst_code_in
                               AND cam_acct_no = cards (i).cap_acct_no;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error While updating acct mast:'
                           || SUBSTR (SQLERRM, 1, 200);
                        EXIT;
                  END;

                  FOR i IN 1 .. cards.COUNT
                  LOOP
                     BEGIN
                        l_auth_id := LPAD (seq_auth_id.NEXTVAL, 6, '0');
                        l_rrn :=
                           TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS')
                           || seq_passivestatupd_rrn.NEXTVAL;
                        l_business_time := TO_CHAR (SYSDATE, 'hh24miss');
                        l_timestamp := SYSTIMESTAMP;
                        l_hashkey_id :=
                           gethash (
                                 l_delivery_channel
                              || l_txn_code
                              || fn_dmaps_main (cards (i).cap_pan_code_encr)
                              || l_rrn
                              || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5'));
                        l_narration :=
                              l_tran_desc
                           || '/'
                           || TO_CHAR (SYSDATE, 'yyyymmdd')
                           || '/'
                           || l_auth_id;

                        INSERT INTO cms_statements_log (csl_pan_no,
                                                        csl_opening_bal,
                                                        csl_trans_amount,
                                                        csl_trans_type,
                                                        csl_trans_date,
                                                        csl_closing_balance,
                                                        csl_trans_narrration,
                                                        csl_pan_no_encr,
                                                        csl_rrn,
                                                        csl_auth_id,
                                                        csl_business_date,
                                                        csl_business_time,
                                                        txn_fee_flag,
                                                        csl_delivery_channel,
                                                        csl_inst_code,
                                                        csl_txn_code,
                                                        csl_ins_date,
                                                        csl_ins_user,
                                                        csl_acct_no,
                                                        csl_panno_last4digit,
                                                        csl_time_stamp,
                                                        csl_prod_code,
                                                        csl_card_type)
                             VALUES (
                                       cards (i).cap_pan_code,
                                       0,
                                       l_idx.vol_denomination,
                                       l_drcr_flag,
                                       SYSDATE,
                                       l_idx.vol_denomination,
                                       l_narration,
                                       cards (i).cap_pan_code_encr,
                                       l_rrn,
                                       l_auth_id,
                                       TO_CHAR (SYSDATE, 'yyyymmdd'),
                                       l_business_time,
                                       'N',
                                       l_delivery_channel,
                                       p_inst_code_in,
                                       l_txn_code,
                                       SYSDATE,
                                       1,
                                       cards (i).cap_acct_no,
                                       SUBSTR (
                                          fn_dmaps_main (
                                             cards (i).cap_pan_code_encr),
                                          -4),
                                       l_timestamp,
                                       cards (i).cap_prod_code,
                                       cards (i).cap_card_type);

                        INSERT INTO transactionlog (msgtype,
                                                    rrn,
                                                    delivery_channel,
                                                    date_time,
                                                    txn_code,
                                                    txn_type,
                                                    txn_mode,
                                                    txn_status,
                                                    response_code,
                                                    business_date,
                                                    business_time,
                                                    customer_card_no,
                                                    total_amount,
                                                    productid,
                                                    categoryid,
                                                    auth_id,
                                                    trans_desc,
                                                    amount,
                                                    instcode,
                                                    tranfee_amt,
                                                    cr_dr_flag,
                                                    customer_card_no_encr,
                                                    reversal_code,
                                                    customer_acct_no,
                                                    acct_balance,
                                                    ledger_balance,
                                                    response_id,
                                                    add_ins_date,
                                                    add_ins_user,
                                                    cardstatus,
                                                    error_msg,
                                                    time_stamp)
                             VALUES ('0200',
                                     l_rrn,
                                     l_delivery_channel,
                                     SYSDATE,
                                     l_txn_code,
                                     1,
                                     '0',
                                     'C',
                                     '00',
                                     TO_CHAR (SYSDATE, 'yyyymmdd'),
                                     l_business_time,
                                     cards (i).cap_pan_code,
                                     l_idx.vol_denomination,
                                     cards (i).cap_prod_code,
                                     cards (i).cap_card_type,
                                     l_auth_id,
                                     l_tran_desc,
                                     l_idx.vol_denomination,
                                     p_inst_code_in,
                                     '0.00',
                                     l_drcr_flag,
                                     cards (i).cap_pan_code_encr,
                                     0,
                                     cards (i).cap_acct_no,
                                     l_idx.vol_denomination,
                                     l_idx.vol_denomination,
                                     1,
                                     SYSDATE,
                                     1,
                                     l_card_stat,
                                     'OK',
                                     l_timestamp);

                        INSERT
                          INTO cms_transaction_log_dtl (
                                  ctd_delivery_channel,
                                  ctd_txn_code,
                                  ctd_txn_type,
                                  ctd_txn_mode,
                                  ctd_business_date,
                                  ctd_business_time,
                                  ctd_customer_card_no,
                                  ctd_txn_amount,
                                  ctd_actual_amount,
                                  ctd_bill_amount,
                                  ctd_process_flag,
                                  ctd_process_msg,
                                  ctd_rrn,
                                  ctd_customer_card_no_encr,
                                  ctd_msg_type,
                                  ctd_cust_acct_number,
                                  ctd_inst_code,
                                  ctd_hashkey_id)
                        VALUES (l_delivery_channel,
                                l_txn_code,
                                1,
                                '0',
                                TO_CHAR (SYSDATE, 'yyyymmdd'),
                                l_business_time,
                                cards (i).cap_pan_code,
                                l_idx.vol_denomination,
                                l_idx.vol_denomination,
                                l_idx.vol_denomination,
                                'Y',
                                'Successful',
                                l_rrn,
                                cards (i).cap_pan_code_encr,
                                '0200',
                                cards (i).cap_acct_no,
                                p_inst_code_in,
                                l_hashkey_id);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_resp_msg_out :=
                              'Error While logging initial_load txn :'
                              || SUBSTR (SQLERRM, 1, 200);
                           EXIT;
                     END;
                  END LOOP;

                  END IF;

                  IF v_resp_msg_out <> 'OK'
                  THEN
                     EXIT;
                  END IF;

                  IF l_card_stat = 1
                  THEN
                     FOR i IN 1 .. cards.COUNT
                     LOOP
                        l_auth_id := LPAD (seq_auth_id.NEXTVAL, 6, '0');
                        l_rrn :=
                           TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS')
                           || seq_passivestatupd_rrn.NEXTVAL;
                        l_business_time := TO_CHAR (SYSDATE, 'hh24miss');

                        BEGIN
                           INSERT INTO transactionlog (msgtype,
                                                       rrn,
                                                       delivery_channel,
                                                       txn_code,
                                                       trans_desc,
                                                       customer_card_no,
                                                       customer_card_no_encr,
                                                       business_date,
                                                       business_time,
                                                       txn_status,
                                                       response_code,
                                                       auth_id,
                                                       instcode,
                                                       add_ins_date,
                                                       response_id,
                                                       date_time,
                                                       customer_acct_no,
                                                       acct_balance,
                                                       ledger_balance,
                                                       cardstatus)
                                VALUES ('0200',
                                        l_rrn,
                                        '05',
                                        '01',
                                        'Card Status update to Active',
                                        cards (i).cap_pan_code,
                                        cards (i).cap_pan_code_encr,
                                        TO_CHAR (SYSDATE, 'yyyymmdd'),
                                        l_business_time,
                                        'C',
                                        '00',
                                        l_auth_id,
                                        p_inst_code_in,
                                        SYSDATE,
                                        '1',
                                        SYSDATE,
                                        cards (i).cap_acct_no,
                                        l_idx.vol_denomination,
                                        l_idx.vol_denomination,
                                        l_card_stat);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_resp_msg_out :=
                                 'Error While inserting into transactionlog :'
                                 || SUBSTR (SQLERRM, 1, 200);
                              EXIT;
                        END;

                        BEGIN
                           INSERT
                             INTO cms_transaction_log_dtl (
                                     ctd_delivery_channel,
                                     ctd_txn_code,
                                     ctd_txn_type,
                                     ctd_msg_type,
                                     ctd_txn_mode,
                                     ctd_business_date,
                                     ctd_business_time,
                                     ctd_customer_card_no,
                                     ctd_process_flag,
                                     ctd_process_msg,
                                     ctd_rrn,
                                     ctd_inst_code,
                                     ctd_customer_card_no_encr,
                                     ctd_cust_acct_number)
                           VALUES ('05',
                                   '01',
                                   '0',
                                   '0200',
                                   0,
                                   TO_CHAR (SYSDATE, 'YYYYMMDD'),
                                   l_business_time,
                                   cards (i).cap_pan_code,
                                   'Y',
                                   'Successful',
                                   l_rrn,
                                   p_inst_code_in,
                                   cards (i).cap_pan_code_encr,
                                   cards (i).cap_acct_no);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_resp_msg_out :=
                                 'Error While inserting into cms_transaction_log_dtl :'
                                 || SUBSTR (SQLERRM, 1, 200);
                              EXIT;
                        END;
                     END LOOP;
                  END IF;

                  IF v_resp_msg_out <> 'OK'
                  THEN
                     EXIT;
                  END IF;
               END LOOP;

               CLOSE cur_cards;

               IF v_resp_msg_out <> 'OK'
               THEN
                  RAISE excp_error;
               ELSIF l_count = l_idx.vol_quantity THEN
                  l_succ_count := l_succ_count + 1;
               ELSIF l_count <> l_idx.vol_quantity THEN
                  v_resp_msg_out := 'Required card numbers are not available in inventory';   -- Modified for VMS-2810
                  l_reject_flag := 'Y';

		--- Added for VMS-2888 - VPS_AVAIL_CARDS Column on VMS_PANGEN_SUMMARY

                  UPDATE vms_pangen_summary
                  SET vps_avail_cards = vps_avail_cards + nvl(l_idx.vol_quantity- l_count,0)
                WHERE vps_prod_code = l_prod_code
                      AND vps_card_type = l_card_type
					  AND vps_avail_cards < 0;

		--- Modified for VMS-3066 - Product Setup re-Vamp - BIN.

               END IF;
            EXCEPTION
               WHEN excp_error
               THEN
                  ROLLBACK;
               WHEN OTHERS
               THEN
                  ROLLBACK;
                  v_resp_msg_out :=
                     'Error while processing lineitem:'
                     || SUBSTR (SQLERRM, 1, 200);
            END;

            UPDATE vms_order_lineitem
               SET vol_order_status =
                      DECODE (
                         v_resp_msg_out,
                         'OK', DECODE (l_prod_type,
                                       'V', 'Completed',
                                       'Processed'),
                         'Rejected'),
                   vol_ccf_flag =
                      DECODE (v_resp_msg_out, 'OK', DECODE (l_prod_type, 'V',2,1), vol_ccf_flag),
                   vol_error_msg = v_resp_msg_out
             WHERE     vol_line_item_id = l_idx.vol_line_item_id
                   AND vol_order_id = l_idx.vol_order_id
                   AND vol_partner_id = l_idx.vol_partner_id;

		--- Added for VMS-2888 - VPS_AVAIL_CARDS Column on VMS_PANGEN_SUMMARY


            IF v_resp_msg_out <> 'OK' and l_reject_flag = 'N'
            THEN
               BEGIN

                        UPDATE cms_appl_pan_inv
                           SET cap_issue_stat = 'E'
                         WHERE cap_prod_code = l_prod_code
                         AND cap_card_type = l_card_type
                         AND cap_issue_stat = 'N'
                         AND CAP_CARD_SEQ between l_start_control_number and l_end_control_number ;

                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_msg_out :=
                           'Error While Updating Cards Issue Stat:'
                           || SUBSTR (SQLERRM, 1, 200);
                  END;


            END IF;

            COMMIT;
         END LOOP;

         IF l_succ_count = 0 OR (l_reject_flag = 'Y' and l_accept_partial = 'N')
         THEN
            IF l_reject_flag = 'Y' THEN
                v_resp_msg_out:= 'Required card numbers are not available in inventory';  -- Modified for VMS-2810.

            BEGIN
                UPDATE  vms_order_lineitem
                SET
                        vol_order_status = 'Rejected',
                        vol_error_msg = v_resp_msg_out
                WHERE
                        vol_order_id = p_order_id_in
                AND     vol_partner_id = p_partner_id_in;

                COMMIT;
            EXCEPTION
                WHEN OTHERS THEN
                ROLLBACK;
                v_resp_msg_out := 'Error while Updating lineitems:'
                          || substr(sqlerrm, 1, 200);
             END;

            END IF;
            p_resp_msg_out := v_resp_msg_out;
            l_proc_stat := 'R';
         ELSIF l_prod_type = 'V'
         THEN
            l_proc_stat := 'C';
         ELSE
            l_proc_stat := 'Y';
         END IF;
      EXCEPTION
         WHEN excp_error
         THEN
            NULL;
      END;

      lp_update_orderstat (p_order_id_in,
                           p_partner_id_in,
                           l_proc_stat,
                           p_resp_msg_out);
   END process_order_request;

   PROCEDURE get_serials (p_productid_in   IN     VARCHAR2,
                          p_quantity_in    IN     NUMBER,
                          p_serials_out       OUT shuffle_array_typ,
                          p_respmsg_out       OUT VARCHAR2)
   AS
      l_rowid        ROWID;
      l_cntrl_numb   vms_product_serial_cntrl.vps_serl_numb%TYPE;
   BEGIN
      p_respmsg_out := 'OK';

      BEGIN
         SELECT rd, serial
           INTO l_rowid, l_cntrl_numb
           FROM (  SELECT ROWID rd, vps_serl_numb serial
                     FROM vms_product_serial_cntrl
                    WHERE vps_product_id = p_productid_in
                          AND (vps_serl_numb-1) + p_quantity_in <= vps_end_serl
                 ORDER BY vps_end_serl - vps_serl_numb)
          WHERE ROWNUM = 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_respmsg_out := 'Sufficient serials not available';
            RETURN;
         WHEN OTHERS
         THEN
            p_respmsg_out :=
               'Error While fetching product_serial_cntrl :'
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      BEGIN
         UPDATE vms_product_serial_cntrl
            SET vps_serl_numb = vps_serl_numb + p_quantity_in
          WHERE ROWID = l_rowid;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_respmsg_out :=
               'Error While fetching product_serial_cntrl :'
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

          SELECT l_cntrl_numb + (LEVEL - 1)
            BULK COLLECT INTO p_serials_out
            FROM DUAL
      CONNECT BY LEVEL <= p_quantity_in;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_respmsg_out := 'Main Excp :' || SUBSTR (SQLERRM, 1, 200);
   END get_serials;

   PROCEDURE delete_cards (p_card_nos_in    IN     shuffle_array_typ,
                           p_resp_msg_out      OUT VARCHAR2)
   AS
      excp_reject_orderprocess   EXCEPTION;
      v_cap_pan_code_encr        cms_appl_pan.cap_pan_code_encr%TYPE;
      v_tran_date                VARCHAR2 (50);
      v_tran_time                VARCHAR2 (50);
      l_ccs_tran_code            cms_card_stat.ccs_tran_code%TYPE;
      l_auth_id                  transactionlog.auth_id%TYPE;
      l_err_msg                  transactionlog.error_msg%TYPE;
      l_resp_cde                 transactionlog.response_code%TYPE;
      v_hash_pan                 vms_line_item_dtl.vli_pan_code%TYPE;
      v_cap_acct_no              cms_appl_pan.cap_acct_no%TYPE;
      l_drcr_flag                cms_statements_log.csl_trans_type%TYPE
                                                                      := 'DR';
      l_cam_acct_bal             cms_acct_mast.cam_acct_bal%TYPE;
      l_cam_ledger_bal           cms_acct_mast.cam_ledger_bal%TYPE;
      l_cap_prod_code            cms_appl_pan.cap_prod_code%TYPE;
      l_cap_card_type            cms_appl_pan.cap_card_type%TYPE;
      v_card_stat                cms_appl_pan.cap_card_stat%TYPE;
      l_delivery_channel         transactionlog.delivery_channel%TYPE := '17';
      l_txn_code                 transactionlog.txn_code%TYPE         := '04';
      l_timestamp                transactionlog.time_stamp%TYPE;
      l_rrn                      transactionlog.rrn%TYPE;
      l_business_time            transactionlog.business_time%TYPE;
      l_hashkey_id               cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_narration                cms_statements_log.csl_trans_narrration%TYPE;
      l_tran_desc                cms_transaction_mast.ctm_tran_desc%TYPE := 'Initial Load';
   BEGIN
      p_resp_msg_out := 'OK';


      FOR i IN 1 .. p_card_nos_in.COUNT
      LOOP
      v_hash_pan:=p_card_nos_in (i);
        /* BEGIN
            DELETE FROM transactionlog
                  WHERE customer_card_no = p_card_nos_in (i);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                  'Error While deleting  card txns:'
                  || SUBSTR (SQLERRM, 1, 200);
               EXIT;
         END;

         BEGIN
            DELETE FROM cms_transaction_log_dtl
                  WHERE ctd_customer_card_no = p_card_nos_in (i);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                  'Error While deleting  card txns dtls:'
                  || SUBSTR (SQLERRM, 1, 200);
               EXIT;
         END;

         BEGIN
            DELETE FROM cms_statements_log
                  WHERE csl_pan_no = p_card_nos_in (i);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                  'Error While deleting  card txns dtls:'
                  || SUBSTR (SQLERRM, 1, 200);
               EXIT;
         END;

         BEGIN
            DELETE FROM cms_cardissuance_status
                  WHERE ccs_pan_code = p_card_nos_in (i);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                  'Error While deleting Cards Issuance:'
                  || SUBSTR (SQLERRM, 1, 200);
               EXIT;
         END;

         BEGIN
            DELETE FROM cms_appl_pan
                  WHERE     cap_inst_code = 1
                        AND cap_mbr_numb = '000'
                        AND cap_pan_code = p_card_nos_in (i);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                  'Error While deleting Cards:' || SUBSTR (SQLERRM, 1, 200);
               EXIT;
         END;

         BEGIN
--            DELETE FROM vms_line_item_dtl
--                  WHERE vli_pan_code = p_card_nos_in (i);
              update vms_line_item_dtl
              set vli_pan_code=null,
                  VLI_PIN=null,
                  VLI_PROXY_PIN_ENCR=null,
                  VLI_PROXY_PIN_HASH=null,
                  VLI_SHIPPING_DATETIME=null,
                  VLI_STATUS=null,
                  VLI_TRACKING_NO=null
              where
                  vli_pan_code = p_card_nos_in (i);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                  'Error While deleting line_item_dtl:'
                  || SUBSTR (SQLERRM, 1, 200);
               EXIT;
         END;

         BEGIN
            UPDATE cms_appl_pan_inv
               SET cap_issue_stat = 'N'
             WHERE cap_pan_code = p_card_nos_in (i);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                  'Error While Updating Cards Issue Stat:'
                  || SUBSTR (SQLERRM, 1, 200);
               EXIT;
         END;*/

          BEGIN
             p_resp_msg_out := 'OK';
            IF v_hash_pan IS NOT NULL
            THEN
                        BEGIN
                           l_auth_id := LPAD (seq_auth_id.NEXTVAL, 6, '0');
                           l_rrn :=
                                 TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS')
                              || seq_passivestatupd_rrn.NEXTVAL;
                           l_business_time := TO_CHAR (SYSDATE, 'hh24miss');
                           l_timestamp := SYSTIMESTAMP;

                           SELECT cap_pan_code_encr, cap_acct_no,cap_card_stat,
                                  cap_prod_code, cap_card_type
                             INTO v_cap_pan_code_encr, v_cap_acct_no,v_card_stat,
                                  l_cap_prod_code, l_cap_card_type
                             FROM cms_appl_pan
                            WHERE cap_pan_code = v_hash_pan
			    and cap_mbr_numb='000'
			    and cap_inst_code=1;

                           BEGIN
                              SELECT cam_acct_bal, cam_ledger_bal
                                INTO l_cam_acct_bal, l_cam_ledger_bal
                                FROM cms_acct_mast
                               WHERE cam_acct_no = v_cap_acct_no
			       and cam_inst_code=1;

                               if l_cam_acct_bal > 0 Then

                              UPDATE cms_acct_mast
                                 SET cam_acct_bal = 0,
                                     cam_ledger_bal = 0,
				     CAM_INITIALLOAD_AMT = 0 --Added for VMS-4895
                               WHERE cam_acct_no = v_cap_acct_no
			       and cam_inst_code=1;

                              IF SQL%ROWCOUNT = 1
                              THEN
                                 BEGIN
                                    l_hashkey_id :=
                                       gethash
                                          (   l_delivery_channel
                                           || l_txn_code
                                           || fn_dmaps_main
                                                          (v_cap_pan_code_encr)
                                           || l_rrn
                                           || TO_CHAR (l_timestamp,
                                                       'YYYYMMDDHH24MISSFF5'
                                                      )
                                          );
                                    l_narration :=
                                          l_tran_desc
                                       || '/'
                                       || TO_CHAR (SYSDATE, 'yyyymmdd')
                                       || '/'
                                       || l_auth_id;

                                    BEGIN
                                       INSERT INTO cms_statements_log
                                                   (csl_pan_no,
                                                    csl_opening_bal,
                                                    csl_trans_amount,
                                                    csl_trans_type,
                                                    csl_trans_date,
                                                    csl_closing_balance,
                                                    csl_trans_narrration,
                                                    csl_pan_no_encr,
                                                    csl_rrn, csl_auth_id,
                                                    csl_business_date,
                                                    csl_business_time,
                                                    txn_fee_flag,
                                                    csl_delivery_channel,
                                                    csl_inst_code,
                                                    csl_txn_code,
                                                    csl_ins_date,
                                                    csl_ins_user,
                                                    csl_acct_no,
                                                    csl_panno_last4digit,
                                                    csl_time_stamp,
                                                    csl_prod_code,
                                                    csl_card_type
                                                   )
                                            VALUES (v_hash_pan,
                                                    l_cam_acct_bal,
                                                    l_cam_acct_bal,
                                                    l_drcr_flag,
                                                    SYSDATE,
                                                    0,
                                                    l_narration,
                                                    v_cap_pan_code_encr,
                                                    l_rrn, l_auth_id,
                                                    TO_CHAR (SYSDATE,
                                                             'yyyymmdd'
                                                            ),
                                                    l_business_time,
                                                    'N',
                                                    l_delivery_channel,
                                                    '1',
                                                    l_txn_code,
                                                    SYSDATE,
                                                    1,
                                                    v_cap_acct_no,
                                                    SUBSTR
                                                       (fn_dmaps_main
                                                           (v_cap_pan_code_encr
                                                           ),
                                                        -4
                                                       ),
                                                    l_timestamp,
                                                    l_cap_prod_code,
                                                    l_cap_card_type
                                                   );
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN

                                          p_resp_msg_out :=
                                                'Error While logging statements_log txn :'
                                             || SUBSTR (SQLERRM, 1, 200);
                                          RAISE excp_reject_orderprocess;
                                    END;

                                    BEGIN
                                       INSERT INTO transactionlog
                                                   (msgtype, rrn,
                                                    delivery_channel,
                                                    date_time, txn_code,
                                                    txn_type, txn_mode,
                                                    txn_status,
                                                    response_code,
                                                    business_date,
                                                    business_time,
                                                    customer_card_no,
                                                    total_amount,
                                                    productid,
                                                    categoryid,
                                                    auth_id, trans_desc,
                                                    amount,
                                                    instcode, tranfee_amt,
                                                    cr_dr_flag,
                                                    customer_card_no_encr,
                                                    reversal_code,
                                                    customer_acct_no,
                                                    acct_balance,
                                                    ledger_balance,
                                                    response_id,
                                                    add_ins_date,
                                                    add_ins_user,
                                                    cardstatus, error_msg,
                                                    time_stamp
                                                   )
                                            VALUES ('0400', l_rrn,
                                                    l_delivery_channel,
                                                    SYSDATE, l_txn_code,
                                                    1, '0',
                                                    'C',
                                                    '00',
                                                    TO_CHAR (SYSDATE,
                                                             'yyyymmdd'
                                                            ),
                                                    l_business_time,
                                                    v_hash_pan,
                                                    l_cam_acct_bal,
                                                    l_cap_prod_code,
                                                    l_cap_card_type,
                                                    l_auth_id, l_tran_desc,
                                                    l_cam_acct_bal,
                                                    1, '0.00',
                                                    l_drcr_flag,
                                                    v_cap_pan_code_encr,
                                                    '69',
                                                    v_cap_acct_no,
                                                    '0',
                                                    '0',
                                                    1,
                                                    SYSDATE,
                                                    1,
                                                    v_card_stat, 'OK',
                                                    l_timestamp
                                                   );
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN

                                          p_resp_msg_out :=
                                                'Error While logging transactionlog txn :'
                                             || SUBSTR (SQLERRM, 1, 200);
                                          RAISE excp_reject_orderprocess;
                                    END;

                                    BEGIN
                                       INSERT INTO cms_transaction_log_dtl
                                                   (ctd_delivery_channel,
                                                    ctd_txn_code,
                                                    ctd_txn_type,
                                                    ctd_txn_mode,
                                                    ctd_business_date,
                                                    ctd_business_time,
                                                    ctd_customer_card_no,
                                                    ctd_txn_amount,
                                                    ctd_actual_amount,
                                                    ctd_bill_amount,
                                                    ctd_process_flag,
                                                    ctd_process_msg,
                                                    ctd_rrn,
                                                    ctd_customer_card_no_encr,
                                                    ctd_msg_type,
                                                    ctd_cust_acct_number,
                                                    ctd_inst_code,
                                                    ctd_hashkey_id
                                                   )
                                            VALUES (l_delivery_channel,
                                                    l_txn_code,
                                                    1,
                                                    '0',
                                                    TO_CHAR (SYSDATE,
                                                             'yyyymmdd'
                                                            ),
                                                    l_business_time,
                                                    v_hash_pan,
                                                    l_cam_acct_bal,
                                                    l_cam_acct_bal,
                                                    l_cam_acct_bal,
                                                    'Y',
                                                    'Successful',
                                                    l_rrn,
                                                    v_cap_pan_code_encr,
                                                    '0400',
                                                    v_cap_acct_no,
                                                    '1',
                                                    l_hashkey_id
                                                   );
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN

                                          p_resp_msg_out :=
                                                'Error While logging log_dtl txn :'
                                             || SUBSTR (SQLERRM, 1, 200);
                                          RAISE excp_reject_orderprocess;
                                    END;
                                 EXCEPTION
                                    WHEN excp_reject_orderprocess
                                    THEN
                                       RAISE;
                                    WHEN OTHERS
                                    THEN

                                       p_resp_msg_out :=
                                             'Error While logging cancel order txn :'
                                          || SUBSTR (SQLERRM, 1, 200);
                                       RAISE excp_reject_orderprocess;
                                 END;
                              ELSE
                                 p_resp_msg_out :=
                                       'Account balance is not updated:'
                                    || v_cap_acct_no;

                                 RAISE excp_reject_orderprocess;
                              END IF;
                        End If;
                           EXCEPTION
                              WHEN excp_reject_orderprocess
                              THEN
                                 RAISE;
                              WHEN OTHERS
                              THEN
                                 p_resp_msg_out :=
                                       'Error While close card acct no:'
                                    || SUBSTR (SQLERRM, 1, 200);

                                 RAISE excp_reject_orderprocess;
                           END;
                        EXCEPTION
                           WHEN excp_reject_orderprocess
                           THEN
                              RAISE;
                           WHEN OTHERS
                           THEN
                              p_resp_msg_out :=
                                    'Error While closing txn code :'
                                 || SUBSTR (SQLERRM, 1, 200);

                              RAISE excp_reject_orderprocess;
                        END;



            ELSE
                     p_resp_msg_out := 'Card NO IS NULL' || v_hash_pan;

                     RAISE excp_reject_orderprocess;

            END IF;
         EXCEPTION
            WHEN excp_reject_orderprocess
            THEN
               NULL;
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                    'Error While closing cards :' || SUBSTR (SQLERRM, 1, 200);

         END;
         IF p_resp_msg_out = 'OK'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;
      END LOOP;


   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_msg_out := 'Main Excp:' || SUBSTR (SQLERRM, 1, 200);
   END delete_cards;

      PROCEDURE cancel_order_request (
      p_inst_code_in    IN       NUMBER,
      p_order_id_in     IN       VARCHAR2,
      p_partner_id_in   IN       VARCHAR2,
      p_resp_code_out   OUT      VARCHAR2,
      p_resp_msg_out    OUT      VARCHAR2
   )
   AS
      excp_reject_order    EXCEPTION;
      l_order_count        NUMBER (5) := 0;
      l_cancel_order_cnt   NUMBER (5) := 0;
      l_activation_cnt     NUMBER (5) := 0;
   BEGIN
      p_resp_msg_out := 'SUCCESS';
      p_resp_code_out := '00';

      BEGIN
         SELECT COUNT (1)
           INTO l_order_count
           FROM vms_order_details
          WHERE vod_order_id = p_order_id_in
            AND vod_partner_id = p_partner_id_in;

         IF l_order_count = 0
         THEN
            p_resp_msg_out :=
                  'NO ORDER EXISTS FOR ORDER ID AND PARTNER ID COMBINATION:Order ID:'
               || p_order_id_in
               || ':ParnerID:'
               || p_partner_id_in;
            p_resp_code_out := '40';
            RAISE excp_reject_order;
         END IF;
      EXCEPTION
         WHEN excp_reject_order
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
                  'Error While getting   ORDER_COUNT  :'
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code_out := '89';
      END;

      BEGIN
         SELECT COUNT (1)
           INTO l_cancel_order_cnt
           FROM vms_order_details
          WHERE vod_order_id = p_order_id_in
            AND vod_partner_id = p_partner_id_in
            AND UPPER (vod_order_status) = 'CANCELLED';

         IF l_cancel_order_cnt <> 0
         THEN
            p_resp_msg_out := 'ORDER ALREADY CANCELLED:';
            p_resp_code_out := '41';
            RAISE excp_reject_order;
         END IF;
      EXCEPTION
         WHEN excp_reject_order
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
                  'Error While getting ORDER ALREADY CANCELLED check :'
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code_out := '89';
      END;

      BEGIN
         SELECT COUNT (1)
           INTO l_activation_cnt
           FROM vms_line_item_dtl, cms_appl_pan
          WHERE vli_order_id = p_order_id_in
            AND vli_partner_id = p_partner_id_in
            AND cap_pan_code = vli_pan_code
            AND cap_active_date IS NOT NULL;

         IF l_activation_cnt <> 0
         THEN
            p_resp_msg_out :=
                  l_activation_cnt
               || ' CARDS ALREADY ACTIVATED IN ORDER ID:'
               || p_order_id_in;
            p_resp_code_out := '42';
            RAISE excp_reject_order;
         END IF;
      EXCEPTION
         WHEN excp_reject_order
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
                  'Error While getting CARDS ALREADY ACTIVATED check :'
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code_out := '89';
      END;

      BEGIN
         UPDATE vms_order_lineitem
            SET vol_ccf_flag = 3,
                vol_order_status = 'CANCELLED'
          WHERE vol_order_id = p_order_id_in
            AND vol_partner_id = p_partner_id_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
                  'Error While UPDATE ORDER STATUS AS CANCELLED IN OREDR LINE ITEM :'
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code_out := '89';
      END;

      BEGIN
         UPDATE vms_order_details
            SET vod_order_status = 'CANCELLED'
          WHERE vod_order_id = p_order_id_in
            AND vod_partner_id = p_partner_id_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
                  'Error While UPDATE OREDR DETAILS STATUS AS CANCELLED :'
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code_out := '89';
      END;
   EXCEPTION
      WHEN excp_reject_order
      THEN
         NULL;
      WHEN OTHERS
      THEN
         p_resp_msg_out :=
             'Error While cancel_order_request :' || SUBSTR (SQLERRM, 1, 200);
         p_resp_code_out := '89';
   END cancel_order_request;

   PROCEDURE cancel_order_process (
      p_inst_code_in       IN       NUMBER,
      p_order_id_in        IN       VARCHAR2,
      p_partner_id_in      IN       VARCHAR2,
      p_resp_code_out      OUT      VARCHAR2,
      p_resp_msg_out       OUT      VARCHAR2,
      p_postback_url_out   OUT      VARCHAR2
   )
   AS
      excp_reject_orderprocess   EXCEPTION;
      v_cap_pan_code_encr        cms_appl_pan.cap_pan_code_encr%TYPE;
      v_tran_date                VARCHAR2 (50);
      v_tran_time                VARCHAR2 (50);
      l_ccs_tran_code            cms_card_stat.ccs_tran_code%TYPE;
      l_auth_id                  transactionlog.auth_id%TYPE;
      l_err_msg                  transactionlog.error_msg%TYPE;
      l_resp_cde                 transactionlog.response_code%TYPE;
      v_hash_pan                 vms_line_item_dtl.vli_pan_code%TYPE;
      v_cap_acct_no              cms_appl_pan.cap_acct_no%TYPE;
      l_drcr_flag                cms_statements_log.csl_trans_type%TYPE
                                                                      := 'DR';
      l_cam_acct_bal             cms_acct_mast.cam_acct_bal%TYPE;
      l_cam_ledger_bal           cms_acct_mast.cam_ledger_bal%TYPE;
      l_cap_prod_code            cms_appl_pan.cap_prod_code%TYPE;
      l_cap_card_type            cms_appl_pan.cap_card_type%TYPE;
      l_delivery_channel         transactionlog.delivery_channel%TYPE := '05';
      l_txn_code                 transactionlog.txn_code%TYPE         := '77';
      l_timestamp                transactionlog.time_stamp%TYPE;
      l_rrn                      transactionlog.rrn%TYPE;
      l_business_time            transactionlog.business_time%TYPE;
      l_hashkey_id               cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_narration                cms_statements_log.csl_trans_narrration%TYPE;
      l_tran_desc                cms_transaction_mast.ctm_tran_desc%TYPE;

      CURSOR cur_cards (l_order_id VARCHAR2, l_partner_id VARCHAR2)
      IS
         SELECT linedtl.vli_pan_code
           FROM vms_line_item_dtl LINEDTL, vms_order_details ORDDTL
          WHERE linedtl.vli_order_id = l_order_id
            AND linedtl.vli_partner_id = l_partner_id
            AND UPPER (orddtl.vod_order_status) = 'CANCELLED'
            AND linedtl.vli_order_id = orddtl.vod_order_id
            AND linedtl.vli_partner_id = orddtl.vod_partner_id;
   BEGIN
      p_resp_code_out := '00';
      p_resp_msg_out := 'Success';

      BEGIN
         SELECT ctm_tran_desc
           INTO l_tran_desc
           FROM cms_transaction_mast
          WHERE ctm_delivery_channel = l_delivery_channel
            AND ctm_tran_code = l_txn_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            p_resp_msg_out :=
                  'Error While getting transaction details :'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_reject_orderprocess;
      END;

      OPEN cur_cards (p_order_id_in, p_partner_id_in);

      LOOP
         FETCH cur_cards
          INTO v_hash_pan;

         EXIT WHEN cur_cards%NOTFOUND;

         BEGIN
            IF v_hash_pan IS NOT NULL
            THEN
               BEGIN
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '9'
                   WHERE cap_pan_code = v_hash_pan;

                  IF SQL%ROWCOUNT = 1
                  THEN
                     BEGIN
                        SELECT ccs_tran_code
                          INTO l_ccs_tran_code
                          FROM cms_card_stat
                         WHERE ccs_stat_code = '9';

                        BEGIN
                           l_auth_id := LPAD (seq_auth_id.NEXTVAL, 6, '0');
                           l_rrn :=
                                 TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS')
                              || seq_passivestatupd_rrn.NEXTVAL;
                           l_business_time := TO_CHAR (SYSDATE, 'hh24miss');
                           l_timestamp := SYSTIMESTAMP;

                           SELECT cap_pan_code_encr, cap_acct_no,
                                  cap_prod_code, cap_card_type
                             INTO v_cap_pan_code_encr, v_cap_acct_no,
                                  l_cap_prod_code, l_cap_card_type
                             FROM cms_appl_pan
                            WHERE cap_pan_code = v_hash_pan;

                           sp_log_cardstat_chnge (1,
                                                  v_hash_pan,
                                                  v_cap_pan_code_encr,
                                                  l_auth_id,
                                                  l_ccs_tran_code,
                                                  '',
                                                  v_tran_date,
                                                  v_tran_time,
                                                  l_resp_cde,
                                                  l_err_msg
                                                 );

                           BEGIN
                              SELECT cam_acct_bal, cam_ledger_bal
                                INTO l_cam_acct_bal, l_cam_ledger_bal
                                FROM cms_acct_mast
                               WHERE cam_acct_no = v_cap_acct_no;

                              UPDATE cms_acct_mast
                                 SET cam_acct_bal = 0,
                                     cam_ledger_bal = 0
                               WHERE cam_acct_no = v_cap_acct_no;

                              IF SQL%ROWCOUNT = 1
                              THEN
                                 BEGIN
                                    l_hashkey_id :=
                                       gethash
                                          (   l_delivery_channel
                                           || l_txn_code
                                           || fn_dmaps_main
                                                          (v_cap_pan_code_encr)
                                           || l_rrn
                                           || TO_CHAR (l_timestamp,
                                                       'YYYYMMDDHH24MISSFF5'
                                                      )
                                          );
                                    l_narration :=
                                          l_tran_desc
                                       || '/'
                                       || TO_CHAR (SYSDATE, 'yyyymmdd')
                                       || '/'
                                       || l_auth_id;

                                    BEGIN
                                       INSERT INTO cms_statements_log
                                                   (csl_pan_no,
                                                    csl_opening_bal,
                                                    csl_trans_amount,
                                                    csl_trans_type,
                                                    csl_trans_date,
                                                    csl_closing_balance,
                                                    csl_trans_narrration,
                                                    csl_pan_no_encr,
                                                    csl_rrn, csl_auth_id,
                                                    csl_business_date,
                                                    csl_business_time,
                                                    txn_fee_flag,
                                                    csl_delivery_channel,
                                                    csl_inst_code,
                                                    csl_txn_code,
                                                    csl_ins_date,
                                                    csl_ins_user,
                                                    csl_acct_no,
                                                    csl_panno_last4digit,
                                                    csl_time_stamp,
                                                    csl_prod_code,
                                                    csl_card_type
                                                   )
                                            VALUES (v_hash_pan,
                                                    0,
                                                    l_cam_acct_bal,
                                                    l_drcr_flag,
                                                    SYSDATE,
                                                    0,
                                                    l_narration,
                                                    v_cap_pan_code_encr,
                                                    l_rrn, l_auth_id,
                                                    TO_CHAR (SYSDATE,
                                                             'yyyymmdd'
                                                            ),
                                                    l_business_time,
                                                    'N',
                                                    l_delivery_channel,
                                                    p_inst_code_in,
                                                    l_txn_code,
                                                    SYSDATE,
                                                    1,
                                                    v_cap_acct_no,
                                                    SUBSTR
                                                       (fn_dmaps_main
                                                           (v_cap_pan_code_encr
                                                           ),
                                                        -4
                                                       ),
                                                    l_timestamp,
                                                    l_cap_prod_code,
                                                    l_cap_card_type
                                                   );
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          p_resp_code_out := '89';
                                          p_resp_msg_out :=
                                                'Error While logging statements_log txn :'
                                             || SUBSTR (SQLERRM, 1, 200);
                                          RAISE excp_reject_orderprocess;
                                    END;

                                    BEGIN
                                       INSERT INTO transactionlog
                                                   (msgtype, rrn,
                                                    delivery_channel,
                                                    date_time, txn_code,
                                                    txn_type, txn_mode,
                                                    txn_status,
                                                    response_code,
                                                    business_date,
                                                    business_time,
                                                    customer_card_no,
                                                    total_amount,
                                                    productid,
                                                    categoryid,
                                                    auth_id, trans_desc,
                                                    amount,
                                                    instcode, tranfee_amt,
                                                    cr_dr_flag,
                                                    customer_card_no_encr,
                                                    reversal_code,
                                                    customer_acct_no,
                                                    acct_balance,
                                                    ledger_balance,
                                                    response_id,
                                                    add_ins_date,
                                                    add_ins_user,
                                                    cardstatus, error_msg,
                                                    time_stamp
                                                   )
                                            VALUES ('0200', l_rrn,
                                                    l_delivery_channel,
                                                    SYSDATE, l_txn_code,
                                                    1, '0',
                                                    'C',
                                                    '00',
                                                    TO_CHAR (SYSDATE,
                                                             'yyyymmdd'
                                                            ),
                                                    l_business_time,
                                                    v_hash_pan,
                                                    l_cam_acct_bal,
                                                    l_cap_prod_code,
                                                    l_cap_card_type,
                                                    l_auth_id, l_tran_desc,
                                                    l_cam_acct_bal,
                                                    p_inst_code_in, '0.00',
                                                    l_drcr_flag,
                                                    v_cap_pan_code_encr,
                                                    0,
                                                    v_cap_acct_no,
                                                    '0',
                                                    '0',
                                                    1,
                                                    SYSDATE,
                                                    1,
                                                    '9', 'OK',
                                                    l_timestamp
                                                   );
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          p_resp_code_out := '89';
                                          p_resp_msg_out :=
                                                'Error While logging transactionlog txn :'
                                             || SUBSTR (SQLERRM, 1, 200);
                                          RAISE excp_reject_orderprocess;
                                    END;

                                    BEGIN
                                       INSERT INTO cms_transaction_log_dtl
                                                   (ctd_delivery_channel,
                                                    ctd_txn_code,
                                                    ctd_txn_type,
                                                    ctd_txn_mode,
                                                    ctd_business_date,
                                                    ctd_business_time,
                                                    ctd_customer_card_no,
                                                    ctd_txn_amount,
                                                    ctd_actual_amount,
                                                    ctd_bill_amount,
                                                    ctd_process_flag,
                                                    ctd_process_msg,
                                                    ctd_rrn,
                                                    ctd_customer_card_no_encr,
                                                    ctd_msg_type,
                                                    ctd_cust_acct_number,
                                                    ctd_inst_code,
                                                    ctd_hashkey_id
                                                   )
                                            VALUES (l_delivery_channel,
                                                    l_txn_code,
                                                    1,
                                                    '0',
                                                    TO_CHAR (SYSDATE,
                                                             'yyyymmdd'
                                                            ),
                                                    l_business_time,
                                                    v_hash_pan,
                                                    l_cam_acct_bal,
                                                    l_cam_acct_bal,
                                                    l_cam_acct_bal,
                                                    'Y',
                                                    'Successful',
                                                    l_rrn,
                                                    v_cap_pan_code_encr,
                                                    '0200',
                                                    v_cap_acct_no,
                                                    p_inst_code_in,
                                                    l_hashkey_id
                                                   );
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          p_resp_code_out := '89';
                                          p_resp_msg_out :=
                                                'Error While logging log_dtl txn :'
                                             || SUBSTR (SQLERRM, 1, 200);
                                          RAISE excp_reject_orderprocess;
                                    END;
                                 EXCEPTION
                                    WHEN excp_reject_orderprocess
                                    THEN
                                       RAISE;
                                    WHEN OTHERS
                                    THEN
                                       p_resp_code_out := '89';
                                       p_resp_msg_out :=
                                             'Error While logging cancel order txn :'
                                          || SUBSTR (SQLERRM, 1, 200);
                                       RAISE excp_reject_orderprocess;
                                 END;
                              ELSE
                                 p_resp_msg_out :=
                                       'Account balance is not updated:'
                                    || v_cap_acct_no;
                                 p_resp_code_out := '89';
                                 RAISE excp_reject_orderprocess;
                              END IF;
                           EXCEPTION
                              WHEN excp_reject_orderprocess
                              THEN
                                 RAISE;
                              WHEN OTHERS
                              THEN
                                 p_resp_msg_out :=
                                       'Error While close card acct no:'
                                    || SUBSTR (SQLERRM, 1, 200);
                                 p_resp_code_out := '89';
                                 RAISE excp_reject_orderprocess;
                           END;
                        EXCEPTION
                           WHEN excp_reject_orderprocess
                           THEN
                              RAISE;
                           WHEN OTHERS
                           THEN
                              p_resp_msg_out :=
                                    'Error While closing txn code :'
                                 || SUBSTR (SQLERRM, 1, 200);
                              p_resp_code_out := '89';
                              RAISE excp_reject_orderprocess;
                        END;
                     EXCEPTION
                        WHEN excp_reject_orderprocess
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           p_resp_msg_out :=
                                 'Error While getting closed card txn code :'
                              || SUBSTR (SQLERRM, 1, 200);
                           p_resp_code_out := '89';
                           RAISE excp_reject_orderprocess;
                     END;
                  ELSE
                     p_resp_msg_out := 'Card Not Closed:' || v_hash_pan;
                     p_resp_code_out := '89';
                     RAISE excp_reject_orderprocess;
                  END IF;
               EXCEPTION
                  WHEN excp_reject_orderprocess
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     p_resp_msg_out :=
                           'Error While closinappl_pan closing cards :'
                        || SUBSTR (SQLERRM, 1, 200);
                     p_resp_code_out := '89';
                     RAISE excp_reject_orderprocess;
               END;
            ELSE
                     p_resp_msg_out := 'Card NO IS NULL' || v_hash_pan;
                     p_resp_code_out := '89';
                     RAISE excp_reject_orderprocess;

            END IF;
         EXCEPTION
            WHEN excp_reject_orderprocess
            THEN
               NULL;
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                    'Error While closing cards :' || SUBSTR (SQLERRM, 1, 200);
               p_resp_code_out := '89';
         END;
      END LOOP;

            IF p_resp_code_out = '00'
      THEN

     BEGIN

         SELECT DECODE (UPPER (vod_postback_response),
                        '1', vod_postback_url,
                        'TRUE', vod_postback_url,
                        ''
                       )
           INTO p_postback_url_out
           FROM vms_order_details
          WHERE vod_order_id = p_order_id_in
            AND vod_partner_id = p_partner_id_in;
      EXCEPTION
       WHEN OTHERS
            THEN
            p_postback_url_out := NULL;
     END;

      END IF;
   END cancel_order_process;

   PROCEDURE replace_card_b2b_v2
   			(p_customer_id_in IN NUMBER,
                         p_isexpedited_in IN VARCHAR2,
                         p_isfeewaived_in IN VARCHAR2,
                         p_comment_in     IN VARCHAR2,
                         p_createnewcard_in IN VARCHAR2 DEFAULT 'FALSE',
                         p_loadamounttype_in   IN VARCHAR2,
                         p_loadamount_in          IN VARCHAR2,
                         p_merchantid_in          IN VARCHAR2,
                         p_terminalid_in          IN VARCHAR2,
                         p_locationid_in          IN VARCHAR2,
                         p_merchantbillable_in    IN VARCHAR2,
                         p_activationcode_in      IN VARCHAR2,
                         p_firstname_in           IN VARCHAR2,
                         p_middlename_in          IN VARCHAR2,
                         p_lastname_in            IN VARCHAR2,
                         p_addrone_in             IN VARCHAR2,
                         p_addrtwo_in             IN VARCHAR2,
                         p_city_in                IN VARCHAR2,
                         p_state_in               IN VARCHAR2,
                         p_postalcode_in          IN VARCHAR2,
                         p_countrycode_in         IN VARCHAR2,
                         p_delivery_chnl_in	      IN VARCHAR2,
						 p_email_in				  IN VARCHAR2,
                         p_istoken_eligible_out   OUT VARCHAR2,
                         p_iscvvplus_eligible_out OUT VARCHAR2,
                         p_cardno_out             OUT VARCHAR2,
                         p_exprydate_out          OUT VARCHAR2,
                         p_new_cardno_out         OUT VARCHAR2,
                         p_new_exprydate_out      OUT VARCHAR2,
                         p_stan_out               OUT VARCHAR2,
                         p_rrn_out                OUT VARCHAR2,
                         p_activationcode_out     OUT VARCHAR2,
                         p_req_reason_out         OUT VARCHAR2,
                         p_forward_instcode_out   OUT VARCHAR2,
                         p_message_reasoncode_out OUT VARCHAR2,
                         p_new_maskcardno_out     OUT VARCHAR2,
                         p_token_dtls_out         OUT SYS_REFCURSOR,
                         p_status_out             OUT VARCHAR2,
                         p_err_msg_out            OUT VARCHAR2) AS

    l_encr_pan                  cms_appl_pan.cap_pan_code_encr%TYPE;
    l_hash_pan                  cms_appl_pan.cap_pan_code%TYPE;
    l_acct_no                   cms_appl_pan.cap_acct_no%TYPE;
    l_prod_code                 cms_appl_pan.cap_prod_code%TYPE;
    l_mbr_numb                  cms_appl_pan.cap_mbr_numb%TYPE;
    l_call_seq                  cms_calllog_details.ccd_call_seq%TYPE;
    l_fee_plan                  cms_fee_feeplan.cff_fee_plan%TYPE;
    l_card_type                 cms_appl_pan.cap_card_type%TYPE;
    l_plain_pan                 VARCHAR2(20);
    l_curr_code                 VARCHAR2(20);
    l_date                      VARCHAR2(20);
    l_time                      VARCHAR2(20);
    l_fee_amt                   VARCHAR2(50);
    l_expiry_date               VARCHAR2(10);
    l_expiry_date_parameter     DATE;
    l_new_expiry_date_parameter DATE;
    l_fee_desc                  cms_fee_mast.cfm_fee_desc%TYPE;
    l_feeflag                   VARCHAR2(1);
    l_avail_bal                 VARCHAR2(50);
    l_ledger_bal                VARCHAR2(50);
    l_clawback_flag             cms_fee_mast.cfm_clawback_flag%TYPE;
    l_auth_id                   VARCHAR2(20);
    l_resp_code                 VARCHAR2(5);
    l_resp_msg                  VARCHAR2(500);
    l_capture_date              DATE;

    l_field_name                VARCHAR2(20);
    l_flag                      PLS_INTEGER := 0;
    l_rrn                       transactionlog.rrn%TYPE;

    l_txn_code                  VARCHAR2(20);
    l_fee_flag                  CHAR(1);

    l_check_tokens          NUMBER;
    l_card_stat             vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_action                VARCHAR2(10);
    l_card_dtls             cms_appl_pan.cap_pan_code%TYPE;
    l_token_eligibility     cms_prod_cattype.cpc_token_eligibility%TYPE;
    l_cvvplus_eligibility   cms_prod_cattype.cpc_cvvplus_eligibility%TYPE;
    l_replace_optn          cms_prod_cattype.cpc_renew_replace_option%TYPE;

    l_acct_balance          cms_acct_mast.cam_acct_bal%TYPE;
    l_ledger_balance        cms_acct_mast.cam_ledger_bal%TYPE;
    l_acct_type             cms_acct_mast.cam_type_code%TYPE;
    l_newcard_flag          VARCHAR2(1) := 'N';
    l_new_pan               VARCHAR2(100);
    l_user_type             cms_prod_cattype.cpc_user_identify_type%TYPE;
    l_encrypt_enable        cms_prod_cattype.cpc_encrypt_enable%TYPE;
  	l_addr_one              vms_order_details.VOD_ADDRESS_LINE1%type;
	  l_addr_two 			        vms_order_details.VOD_ADDRESS_LINE2%type;
  	l_city 				          vms_order_details.VOD_CITY%type;
    l_postal_code 		      vms_order_details.VOD_POSTALCODE%type;
    l_first_name 		        vms_order_details.VOD_FIRSTNAME%type;
  	l_mid_name 			        vms_order_details.VOD_MIDDLEINITIAL%type;
    l_last_name			        vms_order_details.VOD_LASTNAME%type;
    l_order_id_num          VARCHAR2(50);
    l_order_id              VARCHAR2(50);
    l_line_item_id          VARCHAR2(50);
    l_parent_id             VARCHAR2(50);
    l_loadamounttype_in     VARCHAR2(50);
    l_package_id            vms_packageid_mast.vpm_package_id%type;
    l_product_id            cms_prod_cattype.cpc_product_id%TYPE;
    l_serial_number         cms_appl_pan.cap_serial_number%TYPE;
    l_proxy_number          cms_appl_pan.cap_proxy_number%TYPE;
    l_profile_code          cms_prod_cattype.cpc_profile_code%TYPE;
    l_shipping_method       VARCHAR2(20);
    l_cardpack_id           cms_appl_pan.cap_cardpack_id%TYPE;
    l_card_id               cms_prod_cattype.cpc_card_id%TYPE;
    l_replace_shipmethod    vms_packageid_mast.vpm_replace_shipmethod%TYPE;
    l_exp_replaceshipmethod vms_packageid_mast.vpm_exp_replaceshipmethod%TYPE;
    l_shipment_key          vms_shipment_tran_mast.vsm_shipment_key%TYPE;
    l_initialload_amt       cms_acct_mast.cam_acct_bal%TYPE;
    l_load_amt              cms_acct_mast.cam_acct_bal%TYPE;
    l_session_id            VARCHAR2(20);
    l_final_bal             cms_acct_mast.cam_acct_bal%TYPE;
    l_loadamount            cms_acct_mast.cam_acct_bal%TYPE;
    l_cust_first_name       cms_cust_mast.ccm_first_name%TYPE;
    l_cust_last_name        cms_cust_mast.ccm_last_name%TYPE;
    l_cust_business_name    cms_cust_mast.ccm_business_name%TYPE;
    l_embname               vms_order_lineitem.vol_embossedline%TYPE;
    l_encr_embname          vms_order_lineitem.vol_embossedline%TYPE;
    l_length                number := 21;
    l_merchant_id           cms_appl_pan.cap_merchant_id%TYPE;
    l_location_id           cms_appl_pan.cap_location_id%TYPE;
    l_cust_code             cms_appl_pan.cap_cust_code%TYPE;
    l_state_code            gen_state_mast.gsm_state_code%TYPE;
    l_cntry_code            gen_cntry_mast.gcm_cntry_code%TYPE;
	l_logo_id				vms_order_lineitem.vol_logo_id%TYPE;
	l_form_factor           cms_appl_pan.cap_form_factor%TYPE;
	l_virtual_email           vmscms.cms_addr_mast.cam_email%TYPE;
    l_ord_first_name          vmscms.vms_order_details.VOD_FIRSTNAME%type;
    l_ord_last_name           vmscms.vms_order_details.VOD_LASTNAME%type;

    V_EXP_REJECTION         EXCEPTION;



/************************************************************************************************************

    * Modified by      : UBAIDUR RAHMAN.H
    * Modified Date    : 06-May-2021
    * Modified For     : VMS-4223 - B2B Replace card for virtual product is not creating card in Active status
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR46_B0002

     * Modified By      : Puvanesh P
     * Modified Date    : 28-JUL-2021
     * Purpose          : VMS-4754- Update Address/Email for B2B initiated Replacement--B2B Spec Consolidation
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R50_B1

	 * Modified By      : Ubaidur Rahman.H
     * Modified Date    : 13-OCT-2021
     * Purpose          : VMS-5205
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R52_B2

     * Modified By      :  Ubaidur Rahman.H
     * Modified Date    :  03-Dec-2021
     * Modified Reason  :  VMS-5253 / 5372 - Do not pass sytem generated value from VMS to CCA.
     * Reviewer         :  Saravanakumar
     * Build Number     :  VMSGPRHOST_R55_RELEASE
************************************************************************************************************/
  BEGIN

    p_istoken_eligible_out   := 'FALSE';
    p_iscvvplus_eligible_out := 'FALSE';
    p_forward_instcode_out   := '000000';
    l_loadamounttype_in := upper(p_loadamounttype_in);



	  l_loadamount:= to_number(nvl(p_loadamount_in,
                                 0));

    BEGIN

    SELECT to_char(substr(to_char(SYSDATE,
                                  'YYMMDDHHMMSS'),
                          1,
                          9) || --Modified for CFIP-416
                   lpad(seq_deppending_rrn.nextval,
                        3,
                        '0')),
           lpad(seq_auth_stan.nextval,
                6,
                '0')
      INTO l_rrn,
           p_stan_out
      FROM dual;

    p_rrn_out := l_rrn;

	EXCEPTION
        WHEN OTHERS THEN
          p_status_out :=  '49';
          p_err_msg_out := 'Error while selecting Curr code / RRN' || SUBSTR(SQLERRM,1,300);
          RAISE V_EXP_REJECTION;
    END;

    CASE
      WHEN upper(p_isexpedited_in) = 'TRUE'
           AND upper(p_isfeewaived_in) = 'TRUE' THEN
        l_txn_code := '29';
        l_fee_flag := 'N';
      WHEN upper(p_isexpedited_in) = 'TRUE'
           AND upper(p_isfeewaived_in) = 'FALSE' THEN
        l_txn_code := '29';
        l_fee_flag := 'Y';
      WHEN upper(p_isexpedited_in) = 'FALSE'
           AND upper(p_isfeewaived_in) = 'TRUE' THEN
        l_txn_code := '22';
        l_fee_flag := 'N';
      WHEN upper(p_isexpedited_in) = 'FALSE'
           AND upper(p_isfeewaived_in) = 'FALSE' THEN
        l_txn_code := '22';
        l_fee_flag := 'Y';
    END CASE;

    --Check for mandatory fields
    CASE
      WHEN p_customer_id_in IS NULL THEN
        l_field_name := 'CUSTOMER ID';
        l_flag       := 1;
      WHEN p_isexpedited_in IS NULL THEN
        l_field_name := 'IS EXPEDITED';
        l_flag       := 1;
      WHEN p_isfeewaived_in IS NULL THEN
        l_field_name := 'IS FEE WAIVED';
        l_flag       := 1;
      WHEN p_comment_in IS NULL THEN
        l_field_name := 'COMMENT';
        l_flag       := 1;
	  WHEN l_loadamounttype_in='OTHER_AMOUNT' and l_loadamounttype_in is null then
        l_field_name := 'Load Amount';
        l_flag       := 1;
      ELSE
        NULL;
    END CASE;
    --Fetching the active PAN for the input customer id



	BEGIN
        SELECT  ccm_cust_code
          INTO l_cust_code
          FROM cms_cust_mast
         WHERE ccm_cust_id = p_customer_id_in;



	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  p_status_out :=  '49';
          p_err_msg_out := 'Customer Id not found in VMS -'|| p_customer_id_in;
          RAISE V_EXP_REJECTION;
        WHEN OTHERS THEN
          p_status_out :=  '49';
          p_err_msg_out := 'Error while selecting Customer_code' || SQLERRM;
          RAISE V_EXP_REJECTION;
      END;



    --Performance Fix
    BEGIN
      SELECT cap_pan_code,
             cap_pan_code_encr,
             cap_expry_date,
             cap_prod_code,
             cap_mbr_numb,
             cap_card_type,
             cap_acct_no,
             cap_card_stat,
             nvl(cap_cvvplus_reg_flag,
                 'N'),
             cap_serial_number,
             cap_proxy_number,
             cap_cardpack_id,
             cap_merchant_id,
             cap_location_id,
             cap_cust_code,
			 cap_form_factor
        INTO l_hash_pan,
             l_encr_pan,
             l_expiry_date,
             l_prod_code,
             l_mbr_numb,
             l_card_type,
             l_acct_no,
             l_card_stat,
             l_cvvplus_eligibility,
             l_serial_number,
             l_proxy_number,
             l_cardpack_id,
             l_merchant_id,
             l_location_id,
             l_cust_code,
			 l_form_factor
        FROM (SELECT cap_pan_code,
                     cap_pan_code_encr,
                     to_char(cap_expry_date,
                             'yyyymmdd') cap_expry_date,
                     cap_prod_code,
                     cap_mbr_numb,
                     cap_card_type,
                     cap_acct_no,
                     cap_card_stat,
                     cap_cvvplus_reg_flag,
                     cap_serial_number,
                     cap_proxy_number,
                     cap_cardpack_id,
                     cap_merchant_id,
                     cap_location_id,
                     cap_cust_code,
					 cap_form_factor
                FROM cms_appl_pan
               WHERE cap_cust_code = l_cust_code
                 AND cap_inst_code = 1
                 AND cap_active_date IS NOT NULL
                 AND cap_card_stat NOT IN ('9')
                 AND cap_startercard_flag <> 'Y'
               ORDER BY cap_active_date DESC)
       WHERE rownum < 2;
    EXCEPTION
      WHEN no_data_found THEN
        BEGIN
          SELECT cap_pan_code,
                 cap_pan_code_encr,
                 cap_expry_date,
                 cap_prod_code,
                 cap_mbr_numb,
                 cap_card_type,
                 cap_acct_no,
                 cap_card_stat,
                 nvl(cap_cvvplus_reg_flag,
                     'N'),
                 cap_serial_number,
                 cap_proxy_number,
                 cap_cardpack_id,
                 cap_merchant_id,
                 cap_location_id,
                 cap_cust_code,
				 cap_form_factor
            INTO l_hash_pan,
                 l_encr_pan,
                 l_expiry_date,
                 l_prod_code,
                 l_mbr_numb,
                 l_card_type,
                 l_acct_no,
                 l_card_stat,
                 l_cvvplus_eligibility,
                 l_serial_number,
                 l_proxy_number,
                 l_cardpack_id,
                 l_merchant_id,
                 l_location_id,
                 l_cust_code,
				 l_form_factor
            FROM (SELECT cap_pan_code,
                         cap_pan_code_encr,
                         to_char(cap_expry_date,
                                 'yyyymmdd') cap_expry_date,
                         cap_prod_code,
                         cap_mbr_numb,
                         cap_card_type,
                         cap_acct_no,
                         cap_card_stat,
                         cap_cvvplus_reg_flag,
                         cap_serial_number,
                         cap_proxy_number,
                         cap_cardpack_id,
                         cap_merchant_id,
                         cap_location_id,
                         cap_cust_code,
						 cap_form_factor
                    FROM cms_appl_pan
                   WHERE cap_cust_code = l_cust_code
                     AND cap_inst_code = 1
                     AND cap_startercard_flag <> 'Y'
                   ORDER BY cap_pangen_date DESC)
           WHERE rownum < 2;
        EXCEPTION

          WHEN no_data_found THEN
            BEGIN
              SELECT cap_pan_code,
                     cap_pan_code_encr,
                     cap_expry_date,
                     cap_prod_code,
                     cap_mbr_numb,
                     cap_card_type,
                     cap_acct_no,
                     cap_card_stat,
                     nvl(cap_cvvplus_reg_flag,
                         'N'),
                     cap_serial_number,
                     cap_proxy_number,
                     cap_cardpack_id,
                     cap_merchant_id,
                     cap_location_id,
                     cap_cust_code,
					 cap_form_factor
                INTO l_hash_pan,
                     l_encr_pan,
                     l_expiry_date,
                     l_prod_code,
                     l_mbr_numb,
                     l_card_type,
                     l_acct_no,
                     l_card_stat,
                     l_cvvplus_eligibility,
                     l_serial_number,
                     l_proxy_number,
                     l_cardpack_id,
                     l_merchant_id,
                     l_location_id,
                     l_cust_code,
					 l_form_factor
                FROM (SELECT cap_pan_code,
                             cap_pan_code_encr,
                             to_char(cap_expry_date,
                                     'yyyymmdd') cap_expry_date,
                             cap_prod_code,
                             cap_mbr_numb,
                             cap_card_type,
                             cap_acct_no,
                             cap_card_stat,
                             cap_cvvplus_reg_flag,
                             cap_serial_number,
                             cap_proxy_number,
                             cap_cardpack_id,
                             cap_merchant_id,
                             cap_location_id,
                             cap_cust_code,
							 cap_form_factor
                        FROM cms_appl_pan
                       WHERE cap_cust_code = l_cust_code
                         AND cap_inst_code = 1
                         AND cap_active_date IS NOT NULL
                         AND cap_card_stat NOT IN ('9')
                       ORDER BY cap_active_date DESC)
               WHERE rownum < 2;
            EXCEPTION
              WHEN no_data_found THEN
                BEGIN
                  SELECT cap_pan_code,
                         cap_pan_code_encr,
                         cap_expry_date,
                         cap_prod_code,
                         cap_mbr_numb,
                         cap_card_type,
                         cap_acct_no,
                         cap_card_stat,
                         nvl(cap_cvvplus_reg_flag,
                             'N'),
                         cap_serial_number,
                         cap_proxy_number,
                         cap_cardpack_id,
                         cap_merchant_id,
                         cap_location_id,
                         cap_cust_code,
						 cap_form_factor
                    INTO l_hash_pan,
                         l_encr_pan,
                         l_expiry_date,
                         l_prod_code,
                         l_mbr_numb,
                         l_card_type,
                         l_acct_no,
                         l_card_stat,
                         l_cvvplus_eligibility,
                         l_serial_number,
                         l_proxy_number,
                         l_cardpack_id,
                         l_merchant_id,
                         l_location_id,
                         l_cust_code,
						 l_form_factor
                    FROM (SELECT cap_pan_code,
                                 cap_pan_code_encr,
                                 to_char(cap_expry_date,
                                         'yyyymmdd') cap_expry_date,
                                 cap_prod_code,
                                 cap_mbr_numb,
                                 cap_card_type,
                                 cap_acct_no,
                                 cap_card_stat,
                                 cap_cvvplus_reg_flag,
                                 cap_serial_number,
                                 cap_proxy_number,
                                 cap_cardpack_id,
                                 cap_merchant_id,
                                 cap_location_id,
                                 cap_cust_code,
								 cap_form_factor
                            FROM cms_appl_pan
                           WHERE cap_cust_code = l_cust_code
                             AND cap_inst_code = 1
                           ORDER BY cap_pangen_date DESC)
                   WHERE rownum < 2;
                EXCEPTION

                  WHEN no_data_found THEN

                    l_hash_pan    := NULL;
                    l_encr_pan    := NULL;
                    l_expiry_date := NULL;

                    p_err_msg_out := 'PAN is unavailable For Cust Id - ' || p_customer_id_in;
                    p_status_out := '167';
                    RAISE V_EXP_REJECTION;
                END;
            END;
        END;
    END;


    IF l_flag = 1
    THEN
		p_err_msg_out :=  l_field_name || ' is mandatory';
		p_status_out := '49';

		RAISE V_EXP_REJECTION;
    END IF;

    --- Added for VMS-4754- Update Address/Email for B2B initiated Replacement--B2B Spec Consolidation.

    IF l_form_factor = 'V' and p_email_in IS NULL
    THEN
		p_err_msg_out :=  'Email is mandatory for Virtual Card Replacement.';
		p_status_out := '49';

		RAISE V_EXP_REJECTION;
    END IF;

	if l_loadamounttype_in not in ('INITIAL_LOAD_AMOUNT','CURRENT_BALANCE','OTHER_AMOUNT')
    THEN
        p_status_out :=  '49';
        p_err_msg_out := 'Invalid Load Amount Type';
        RAISE V_EXP_REJECTION;
    end if;

      BEGIN
        SELECT cam_acct_bal,
               cam_ledger_bal,
               cam_type_code,
               nvl(cam_initialload_amt,0)
          INTO l_acct_balance,
               l_ledger_balance,
               l_acct_type,
               l_initialload_amt
          FROM cms_acct_mast
         WHERE cam_acct_no = l_acct_no
           AND cam_inst_code = 1;
      EXCEPTION
        WHEN OTHERS THEN
          p_status_out :=  '49';
          p_err_msg_out := 'Error while selecting acct dtl' || SQLERRM;
          RAISE V_EXP_REJECTION;
      END;
      IF L_LOADAMOUNTTYPE_IN='OTHER_AMOUNT' AND l_loadamount < L_ACCT_BALANCE THEN
          p_status_out := '49';
          p_err_msg_out := 'Load Amount Should be Greater Than Account Balance';
          RAISE V_EXP_REJECTION;
      ELSIF l_loadamounttype_in='INITIAL_LOAD_AMOUNT' and l_acct_balance>l_initialload_amt then
          p_status_out := '49';
          p_err_msg_out := 'Initial Load Amount Should Be Greater Than Account Balance';
          RAISE V_EXP_REJECTION;
      END IF;


    l_date := to_char(SYSDATE,
                              'yyyymmdd');

    l_time := to_char(SYSDATE,'HH24MISS');

    l_plain_pan := fn_dmaps_main(l_encr_pan);

    p_cardno_out := l_plain_pan;

	BEGIN

    SELECT nvl(cpc_token_eligibility,
               'N'),
           nvl(cpc_user_identify_type,
               '0'),
           cpc_encrypt_enable,
           cpc_product_id,
           cpc_profile_code,
           cpc_card_id
      INTO l_token_eligibility,
           l_user_type,
           l_encrypt_enable,
           l_product_id,
           l_profile_code,
           l_card_id
      FROM cms_prod_cattype
     WHERE cpc_inst_code = 1
       AND cpc_prod_code = l_prod_code
       AND cpc_card_type = l_card_type;

	EXCEPTION
        WHEN OTHERS THEN
          p_status_out :=  '49';
          p_err_msg_out := 'Error while selecting from Prod cattype' || SQLERRM;
          RAISE V_EXP_REJECTION;
      END;


    IF l_user_type IN ( '1', '4')   and NVL(l_form_factor,'P') <> 'V'        --- 1 Anonymous Gift \ 4 Personalised Gift
    THEN
      CASE
        WHEN p_addrone_in IS NULL THEN
          l_field_name := 'Address 1';
          l_flag       := 1;
        WHEN p_city_in IS NULL THEN
          l_field_name := 'City';
          l_flag       := 1;
        WHEN p_state_in IS NULL THEN
          l_field_name := 'State';
          l_flag       := 1;
        WHEN p_postalcode_in IS NULL THEN
          l_field_name := 'Postal Code';
          l_flag       := 1;
        WHEN p_countrycode_in IS NULL THEN
          l_field_name := 'Country Code';
          l_flag       := 1;
        ELSE
          NULL;
      END CASE;

    END IF;

    IF l_flag = 1
    THEN
		p_err_msg_out :=  l_field_name ||
                            ' is mandatory for Anonymous User';
		p_status_out := '49';
	RAISE V_EXP_REJECTION;

    END IF;

    IF l_token_eligibility = 'Y'
    THEN
      p_istoken_eligible_out := 'TRUE';
    END IF;

    IF l_cvvplus_eligibility = 'Y'
    THEN
      p_iscvvplus_eligible_out := 'TRUE';
    END IF;


    IF upper(p_createnewcard_in) = 'TRUE'
    THEN
      l_newcard_flag := 'Y';
    END IF;

	BEGIN

    --Performance Fix
    SELECT cbp_param_value
      INTO l_curr_code
      FROM cms_bin_param
     WHERE cbp_inst_code = 1
       AND cbp_profile_code = l_profile_code
       AND cbp_param_name = 'Currency';

	EXCEPTION
        WHEN OTHERS THEN
          p_status_out :=  '49';
          p_err_msg_out := 'Error while selecting bin param ' || SUBSTR(SQLERRM,1,300);
          RAISE V_EXP_REJECTION;
      END;


    BEGIN

      SELECT gpp_feeplan.get_fee_plan(l_hash_pan,
                                             l_prod_code,
                                             l_card_type)
        INTO l_fee_plan
        FROM dual;

    EXCEPTION
    WHEN OTHERS
    THEN
    	p_err_msg_out :=  'Error while fetching feeplan' || SUBSTR(SQLERRM,1,300);
		p_status_out := '49';
	RAISE V_EXP_REJECTION;
    END;


	BEGIN
        SELECT TRIM(to_char(a.cfm_fee_amt,
                            '9999999999999990.00'))
          INTO l_fee_amt
          FROM cms_fee_mast a
         WHERE a.cfm_inst_code = 1
           AND a.cfm_fee_code IN
               (SELECT b.cff_fee_code
                  FROM cms_fee_feeplan b
                 WHERE b.cff_fee_plan = l_fee_plan
                   AND b.cff_inst_code = 1)
           AND a.cfm_delivery_channel = p_delivery_chnl_in
           AND (cfm_tran_code = l_txn_code OR cfm_tran_code = 'A')
           AND nvl(cfm_normal_rvsl,
                   'N') = 'N';
      EXCEPTION
        WHEN no_data_found THEN
          l_fee_amt := '0.00';
      END;


      BEGIN

              sp_csr_order_replace('1',
                                  '0200',
                                  l_rrn,
                                  p_delivery_chnl_in,
                                  NULL,
                                  l_txn_code,
                                  '0',
                                  l_date,
                                  l_time,
                                  l_plain_pan,
                                  '1',
                                  '0',
                                  NULL,
                                  l_curr_code,
                                  NULL,
                                  l_expiry_date,
                                  p_stan_out,
                                  l_mbr_numb,
                                  '0',
                                  NULL,
                                  NULL,
                                  NULL,
                                  p_comment_in,
                                  l_fee_flag,
                                  p_activationcode_out,
                                  l_resp_code,
                                  l_resp_msg,
                                  l_capture_date,
                                  l_fee_amt,
                                  l_avail_bal,
                                  l_ledger_bal,
                                  p_err_msg_out,
                                  l_expiry_date_parameter,
                                  l_new_expiry_date_parameter,
                                  l_replace_optn,
                                  l_newcard_flag
                                  );



        IF l_resp_msg <> 'OK'
		THEN
          p_status_out  := l_resp_code;
          p_err_msg_out := l_resp_msg;
          dbms_output.put_line ('l_resp_msg -'||l_resp_msg );
          RAISE V_EXP_REJECTION;
		END IF;

      EXCEPTION
      WHEN V_EXP_REJECTION
      THEN
      RAISE;
	  WHEN OTHERS THEN

          p_status_out  := '49';
          p_err_msg_out := 'Error from procedure sp_chw_order_replace ' || substr(sqlerrm,1,300);
          RAISE V_EXP_REJECTION;
      END;

 dbms_output.put_line ('After sp chw order replace -'||l_resp_msg );

      p_exprydate_out     := to_char(l_expiry_date_parameter,
                                     'MMYY');
      p_new_exprydate_out := to_char(l_new_expiry_date_parameter,
                                     'MMYY');
      IF l_encrypt_enable = 'Y'
      THEN
        l_addr_one           := fn_emaps_main(p_addrone_in);
        l_addr_two           := fn_emaps_main(p_addrtwo_in);
        l_city               := fn_emaps_main(p_city_in);
        l_postal_code        := fn_emaps_main(p_postalcode_in);
        l_first_name         := fn_emaps_main(p_firstname_in);
        l_mid_name           := fn_emaps_main(p_middlename_in);
        l_last_name          := fn_emaps_main(p_lastname_in);

		l_virtual_email      := vmscms.fn_emaps_main(p_email_in);
      ELSE
        l_addr_one           := p_addrone_in;
        l_addr_two           := p_addrtwo_in;
        l_city               := p_city_in;
        l_postal_code        := p_postalcode_in;
        l_first_name         := p_firstname_in;
        l_mid_name           := p_middlename_in;
        l_last_name          := p_lastname_in;

		l_virtual_email      := p_email_in;
      END IF;

      IF l_resp_code = '00'
      THEN
        BEGIN
          SELECT vmscms.fn_dmaps_main(cap_pan_code_encr)
            INTO l_new_pan
            FROM cms_htlst_reisu,
                 cms_appl_pan
           WHERE chr_inst_code = 1
             AND chr_pan_code = l_hash_pan
             AND chr_mbr_numb = l_mbr_numb
             AND cap_inst_code = chr_inst_code
             AND cap_mbr_numb = l_mbr_numb
             AND cap_pan_code = chr_new_pan;

          p_new_cardno_out     := l_new_pan;
          p_new_maskcardno_out := vmscms.fn_getmaskpan(l_new_pan);

          p_message_reasoncode_out := '3721';
          p_req_reason_out         := 'New PAN Replacement By Program Manager';

         dbms_output.put_line ('l_new_pan 1 -'||l_new_pan );
          IF l_token_eligibility = 'Y'
          THEN
            SELECT COUNT(*)
              INTO l_check_tokens
              FROM vms_token_info
             WHERE vti_acct_no = l_acct_no
               AND vti_token_stat <> 'D';

            IF l_check_tokens > 0
            THEN
              IF l_card_stat = '2'
              THEN
                gpp_tokens.update_token_status(l_hash_pan,
                                                      gethash(l_new_pan),
                                                      'R',
                                                      l_action,
                                                      l_card_dtls,
                                                      l_card_dtls,
                                                      p_token_dtls_out,
                                                      p_err_msg_out);


                IF p_err_msg_out <> 'OK'
                THEN
				p_err_msg_out := 'Update Tokens failed for ' ||
                                   'CUSTOMER ID ' || p_customer_id_in ||
                                   ', Error: ' || p_err_msg_out;
				p_status_out  := '49';
				RAISE V_EXP_REJECTION;

                END IF;
              ELSE
                l_action := 'N';
              END IF;
            END IF;

            IF p_err_msg_out = 'OK'
               AND l_action IN ('N',
                                'D')
            THEN
              p_stan_out               := '';
              p_rrn_out                := '';
              p_activationcode_out     := '';
              p_req_reason_out         := '';
              p_forward_instcode_out   := '';
              p_message_reasoncode_out := '';
            END IF;

          END IF;
        EXCEPTION
          WHEN V_EXP_REJECTION
          THEN
          RAISE V_EXP_REJECTION;
          WHEN no_data_found THEN
            l_new_pan                := l_plain_pan;
            p_message_reasoncode_out := '3720';
            p_req_reason_out         := 'Same PAN Relpacement By Program Manager';
        END;

     BEGIN
        UPDATE cms_appl_pan
           SET cap_replace_merchant_id = p_merchantid_in,
               cap_replace_terminal_id = p_terminalid_in,
               cap_activation_code     = p_activationcode_in,
               cap_serial_number       = l_serial_number,
               cap_proxy_number        = l_proxy_number,
               cap_merchant_billable   = DECODE(upper(p_merchantbillable_in),
                                                'TRUE',
                                                'Y',
                                                'N'),
               cap_replace_location_id = p_locationid_in,
               cap_merchant_id = NVL(p_merchantid_in,l_merchant_id),
               cap_location_id = NVL(p_locationid_in,l_location_id),
			   cap_form_factor = l_form_factor,
               cap_card_stat = decode(l_form_factor,'V',1,cap_card_stat),
               cap_active_date = decode(l_form_factor,'V',SYSDATE,cap_active_date)
         WHERE cap_pan_code = gethash(l_new_pan)
           AND cap_mbr_numb = l_mbr_numb
           AND cap_inst_code = 1;




	IF l_form_factor = 'V'
        THEN

        UPDATE cms_cardissuance_status
        SET ccs_card_status = 15   				--- SHIPPED
        where ccs_pan_code =  gethash(l_new_pan);

        END IF;

	   EXCEPTION
		 WHEN OTHERS
		 THEN
          p_status_out  := '49';
          p_err_msg_out := 'Error while updating cms_appl_pan / card_issuance ' || substr(sqlerrm,1,300);
          RAISE V_EXP_REJECTION;
      END;



		--- 3 KYC \ 2 Personalised

	--- Added for VMS-4754- Update Address/Email for B2B initiated Replacement--B2B Spec Consolidation

	      IF p_firstname_in IS NOT NULL
	        THEN
			UPDATE vmscms.cms_cust_mast
                                   SET ccm_first_name = l_first_name,
                                       ccm_mid_name = nvl(l_mid_name,ccm_mid_name),
                                       ccm_last_name = nvl(l_last_name,ccm_last_name),
                                       ccm_first_name_encr = vmscms.fn_emaps_main(p_firstname_in),
                                       ccm_last_name_encr = nvl(vmscms.fn_emaps_main(p_lastname_in),trim(ccm_last_name_encr))
                                 WHERE ccm_inst_code = 1
                                   AND ccm_cust_code = l_cust_code;


	      END IF;


       	BEGIN
        SELECT fn_dmaps_main(ccm_first_name),
               fn_dmaps_main(ccm_last_name),
               ccm_business_name
          INTO l_cust_first_name,
               l_cust_last_name,
               l_cust_business_name
          FROM cms_cust_mast
         WHERE ccm_cust_id = p_customer_id_in;

    l_embname := FN_B2B_EMBNAME(l_cust_first_name, l_cust_last_name, l_length);

    EXCEPTION
    WHEN OTHERS THEN
          p_status_out :=  '49';
          p_err_msg_out := 'Error while selecting Emboss NaME' || SQLERRM;
          RAISE V_EXP_REJECTION;
      END;


       	IF l_encrypt_enable = 'Y'
      THEN
        l_encr_embname       := fn_emaps_main(l_embname);
        l_cust_business_name := fn_emaps_main(l_cust_business_name);
      ELSE
        l_encr_embname       := l_embname;
        l_cust_business_name := l_cust_business_name;
      END IF;


        IF p_addrone_in IS NOT NULL and p_city_in IS NOT NULL and
        p_state_in IS NOT NULL and p_postalcode_in IS NOT NULL and p_countrycode_in IS NOT NULL

        THEN
           BEGIN
                  SELECT gsm_state_code
                  INTO l_state_code
                  FROM gen_state_mast
                  WHERE gsm_inst_code = 1
                  AND gsm_switch_state_code = upper(p_state_in);

                  SELECT gcm_cntry_code
                  INTO l_cntry_code
                  FROM gen_cntry_mast
                  WHERE gcm_inst_code = 1
                  AND gcm_switch_cntry_code = upper(p_countrycode_in);


                  MERGE INTO cms_addr_mast
                  USING (select l_cust_code cust_code,'O' addr_flag from dual) a
                  ON (cam_cust_code = a.cust_code and cam_addr_flag = a.addr_flag)
                  WHEN MATCHED THEN
                    UPDATE
                    SET CAM_ADD_ONE      = l_addr_one,
                      CAM_ADD_TWO        = l_addr_two,
                      CAM_CITY_NAME      = l_city,
                      CAM_STATE_CODE     = l_state_code,
                      CAM_PIN_CODE       = l_postal_code,
                      CAM_CNTRY_CODE     = l_cntry_code,
                      CAM_LUPD_DATE      = sysdate,
                      CAM_ADD_ONE_ENCR   = vmscms.fn_emaps_main(p_addrone_in),
                      CAM_ADD_TWO_ENCR   = vmscms.fn_emaps_main(p_addrtwo_in),
                      CAM_CITY_NAME_ENCR = vmscms.fn_emaps_main(p_city_in),
                      CAM_PIN_CODE_ENCR  = vmscms.fn_emaps_main(p_postalcode_in)
                  WHEN NOT MATCHED THEN
                      INSERT (
                              CAM_INST_CODE,
                              CAM_CUST_CODE,
                              CAM_ADDR_CODE,
                              CAM_ADD_ONE,
                              CAM_ADD_TWO,
                              CAM_PIN_CODE,
                              CAM_CNTRY_CODE,
                              CAM_CITY_NAME,
                              CAM_ADDR_FLAG,
                              CAM_INS_DATE,
                              CAM_STATE_CODE,
                              CAM_ADD_ONE_ENCR,
                              CAM_ADD_TWO_ENCR,
                              CAM_PIN_CODE_ENCR,
                              CAM_CITY_NAME_ENCR,
							  CAM_INS_USER,					--- Added for VMS-5205
							  CAM_LUPD_USER
                            )
                      VALUES
                            (
                              1,
                              l_cust_code,
                              seq_addr_code.nextval,
                              l_addr_one,
                              l_addr_two,
                              l_postal_code,
                              l_cntry_code,
                              l_city,
                              'O',
                              sysdate,
                              l_state_code,
                              fn_emaps_main(p_addrone_in),
                              fn_emaps_main(p_addrtwo_in),
                              fn_emaps_main(p_postalcode_in),
                              fn_emaps_main(p_city_in),
							  1,
							  1
                            );

			IF l_user_type in ('1','4') THEN

				 UPDATE vmscms.cms_addr_mast
							SET CAM_ADD_ONE      = l_addr_one,
							  CAM_ADD_TWO        = l_addr_two,
							  CAM_CITY_NAME      = l_city,
							  CAM_STATE_CODE     = l_state_code,
							  CAM_PIN_CODE       = l_postal_code,
							  CAM_CNTRY_CODE     = l_cntry_code,
							  CAM_LUPD_DATE      = sysdate,
							  CAM_ADD_ONE_ENCR   = vmscms.fn_emaps_main(p_addrone_in),
							  CAM_ADD_TWO_ENCR   = vmscms.fn_emaps_main(p_addrtwo_in),
							  CAM_CITY_NAME_ENCR = vmscms.fn_emaps_main(p_city_in),
							  CAM_PIN_CODE_ENCR  = vmscms.fn_emaps_main(p_postalcode_in)
				 WHERE CAM_INST_CODE = 1
					   AND CAM_CUST_CODE = l_cust_code
				   AND CAM_ADDR_FLAG  = 'P' ;

			END IF;
            					--- Added for VMS-5253 / VMS-5372

            		UPDATE CMS_CUST_MAST
	                   SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
	                   WHERE CCM_INST_CODE = 1
	                    AND CCM_CUST_CODE = l_cust_code;


            EXCEPTION
              WHEN OTHERS THEN

                  p_status_out  := '49';
                  p_err_msg_out :=  'Error while updating the adrress' || substr(sqlerrm,1,300);
                  RAISE V_EXP_REJECTION;
            END;
        END IF;


	--- Added for VMS-4754- Update Address/Email for B2B initiated Replacement--B2B Spec Consolidation

	IF p_email_in IS NOT NULL
	THEN

	UPDATE CMS_ADDR_MAST
        SET CAM_EMAIL = l_virtual_email,
        CAM_EMAIL_ENCR = fn_emaps_main(p_email_in)
        WHERE CAM_CUST_CODE = l_cust_code
        AND CAM_INST_CODE = 1;

	END IF;


        IF l_user_type in ('1','4')					--- 1 Anonymous Gift \ 4 Personalised Gift
        THEN

          SELECT replace_order_id.nextval,
                 seq_parent_id.nextval
            INTO l_order_id_num,
                 l_parent_id
            FROM dual;

          l_order_id     := 'ROID' || l_order_id_num;
          l_line_item_id := 'RLID' || l_order_id_num;




          IF l_user_type = '1' THEN

            BEGIN
                SELECT lineitem.vol_embossedline,
                       lineitem.vol_embossed_line1
                INTO l_encr_embname,
                     l_cust_business_name
                FROM vms_order_lineitem lineitem,
                     vms_line_item_dtl lineitem_dtl
                WHERE lineitem.vol_line_item_id = lineitem_dtl.vli_lineitem_id
                AND lineitem.vol_order_id       = lineitem_dtl.vli_order_id
                AND lineitem.vol_parent_oid     = lineitem_dtl.vli_parent_oid
                AND lineitem_dtl.vli_pan_code   = l_hash_pan
                AND rownum = 1;
            EXCEPTION
            WHEN OTHERS THEN
              l_encr_embname := NULL;
              l_cust_business_name := NULL;
            END;

          END IF;


		  BEGIN

          SELECT vpm_replace_shipmethod,
                 vpm_exp_replaceshipmethod,
		             vpm_package_id
            INTO l_replace_shipmethod,
                 l_exp_replaceshipmethod,
		             l_package_id
            FROM vms_packageid_mast
           WHERE vpm_package_id IN
                 (SELECT vpm_replacement_package_id
                    FROM vms_packageid_mast
                   WHERE vpm_package_id IN
                         (SELECT cpc_card_details
                            FROM cms_prod_cardpack
                           WHERE cpc_prod_code = l_prod_code
                             AND cpc_card_id = nvl(l_cardpack_id,
                                                   l_card_id)));

		EXCEPTION
			WHEN OTHERS
			THEN
                  p_status_out  := '49';
                  p_err_msg_out :=  'Error while selecting replacement package id details.' || substr(sqlerrm,1,300);
                  RAISE V_EXP_REJECTION;
		END;

          IF upper(p_isexpedited_in) = 'TRUE'
          THEN
            l_shipping_method := l_exp_replaceshipmethod;
          ELSE
            l_shipping_method := l_replace_shipmethod;
          END IF;

		BEGIN
          SELECT vsm_shipment_key
            INTO l_shipment_key
            FROM vms_shipment_tran_mast
           WHERE vsm_shipment_id = l_shipping_method;

		 EXCEPTION
			WHEN OTHERS
			THEN
                  p_status_out  := '49';
                  p_err_msg_out :=  'Error while selecting shipment key' || substr(sqlerrm,1,300);
                  RAISE V_EXP_REJECTION;
		END;


		BEGIN
		   SELECT vpl_logo_id
			INTO l_logo_id
			FROM VMS_PACKID_LOGOID_MAPPING
			WHERE vpl_package_id = l_package_id
			  AND vpl_default_flag = 'Y';
		EXCEPTION
			WHEN OTHERS
			THEN l_logo_id :='000000';
		END;

        IF p_firstname_in IS  NULL AND p_lastname_in IS NULL
        THEN

        BEGIN
                SELECT ord.vod_firstname,
                       ord.vod_lastname
                INTO l_ord_first_name,
                     l_ord_last_name
                FROM vmscms.vms_order_details ord,
                     vmscms.vms_line_item_dtl lineitem_dtl
                WHERE ord.vod_order_id       = lineitem_dtl.vli_order_id
                AND ord.vod_partner_id     = lineitem_dtl.vli_partner_id
                AND lineitem_dtl.vli_pan_code   = l_hash_pan
                AND rownum = 1;
            EXCEPTION
            WHEN OTHERS THEN
                NULL;
            END;

         END IF;


		BEGIN
          INSERT INTO vms_order_details
            (vod_order_id,
             vod_partner_id,
             vod_merchant_id,
             vod_order_default_card_status,
             vod_postback_response,
             vod_activation_code,
             vod_shipping_method,
             vod_order_status,
             vod_address_line1,
             vod_address_line2,
             vod_city,
             vod_state,
             vod_postalcode,
             vod_country,
             vod_firstname,
             vod_middleinitial,
             vod_lastname,
             vod_ins_date,
             vod_error_msg,
             vod_channel_id,
             vod_accept_partial,
             vod_order_type,
             vod_parent_oid,
			 VOD_EMAIL)
          VALUES
            (l_order_id,
             'Replace_Partner_ID',
             p_merchantid_in,
             decode(l_form_factor,'V','ACTIVE','INACTIVE'),
             'False',
             p_activationcode_in,
             l_shipment_key,
             decode(l_form_factor,'V','Completed','Processed'),
             l_addr_one,
             l_addr_two,
             l_city,
             DECODE (l_encrypt_enable,'N',p_state_in,fn_emaps_main(p_state_in)),
             l_postal_code,
             DECODE (l_encrypt_enable,'N',p_countrycode_in,fn_emaps_main(p_countrycode_in)),
             nvl(l_first_name,l_ord_first_name),
             l_mid_name,
             nvl(l_last_name,l_ord_last_name),
             SYSDATE,
             'OK',
             'WEB',
             'true',
             'IND',
             l_parent_id,
			 l_virtual_email);

          INSERT INTO vms_order_lineitem
            (vol_order_id,
             vol_line_item_id,
             vol_package_id,
             vol_product_id,
             vol_quantity,
             vol_order_status,
             vol_ins_date,
             vol_error_msg,
             vol_partner_id,
             vol_parent_oid,
             vol_ccf_flag,
             vol_return_file_msg,
             vol_embossedline,
             vol_embossed_line1,
			 vol_logo_id)
          VALUES
            (l_order_id,
             l_line_item_id,
             l_package_id,
             l_product_id,
             1,
             decode(l_form_factor,'V','Completed','Processed'),
             SYSDATE,
             'OK',
             'Replace_Partner_ID',
             l_parent_id,
             decode(l_form_factor,'V',2,1),
             NULL,
             l_encr_embname,
             l_cust_business_name,
			 l_logo_id);

          INSERT INTO vms_line_item_dtl
            (vli_pan_code,
             vli_order_id,
             vli_partner_id,
             vli_lineitem_id,
             vli_parent_oid,
             vli_serial_number)
          VALUES
            (gethash(l_new_pan),
             l_order_id,
             'Replace_Partner_ID',
             l_line_item_id,
             l_parent_id,
             l_serial_number);

		EXCEPTION
			WHEN OTHERS
			THEN
                  p_status_out  := '49';
                  p_err_msg_out :=  'Error while inserting into order related tables.' || substr(sqlerrm,1,300);
                  RAISE V_EXP_REJECTION;
		END;


        END IF;

      END IF;

                 IF l_loadamounttype_in='INITIAL_LOAD_AMOUNT' THEN
                    l_load_amt         :=l_initialload_amt;
                  ELSIF l_loadamounttype_in='OTHER_AMOUNT' THEN
                    l_load_amt            := l_loadamount;
                  END IF;

                  IF l_load_amt IS NOT NULL THEN
                    UPDATE cms_acct_mast
                    SET cam_new_initialload_amt=l_load_amt
                    WHERE cam_inst_code        =1
                    AND cam_acct_no            =l_acct_no
                    AND cam_initialload_amt    < l_load_amt ;
                  END IF;

                  dbms_output.put_line ('l_new_pan -'||l_new_pan );

         IF l_load_amt <>0 and l_loadamounttype_in <> 'CURRENT_BALANCE' THEN
         BEGIN
				sp_manual_adj_csr(1,
                                 '000',
                                 '0200',
                                 '03',
                                 '14',
                                 '0',
                                 l_date,
                                 l_time,
                                 l_new_pan,
                                 l_rrn,
                                 NULL,
                                 l_load_amt,
                                 CASE
                                 WHEN p_loadamounttype_in='INITIAL_LOAD_AMOUNT'
                                 THEN '260'
                                 WHEN p_loadamounttype_in='OTHER_AMOUNT'
                                 THEN '262'
                                 END,
                                 p_comment_in,
                                 0,
                                 l_curr_code,
                                 NULL,
                                 NULL,
                                 NULL,
                                 l_acct_no,
                                 1,
                                null,
                                 1,
                                 NULL,
                                 l_final_bal,
                                 l_resp_code,
                                 l_resp_msg);

			IF l_resp_msg <>'OK'
			THEN
			p_status_out  := '49';
			p_err_msg_out := 'Error from sp_manual_adj_csr - ' ||  l_resp_msg;
			RAISE V_EXP_REJECTION;

			END IF;
      EXCEPTION
		WHEN V_EXP_REJECTION THEN
		RAISE V_EXP_REJECTION;

        WHEN OTHERS THEN

          p_status_out  := '49';
          p_err_msg_out := 'Error from sp_manual_adj_csr - ' || substr(sqlerrm,1,300);
          RAISE V_EXP_REJECTION;
      END;
      END iF;



     IF l_acct_balance<>0  and l_loadamounttype_in <> 'CURRENT_BALANCE'  THEN
      BEGIN
				sp_manual_adj_csr(1,
                                 '000',
                                 '0200',
                                 '03',
                                 '13',
                                 '0',
                                 l_date,
                                 l_time,
                                 l_new_pan,
                                 l_rrn,
                                 NULL,
                                 l_acct_balance,
                                 CASE
                                 WHEN p_loadamounttype_in='INITIAL_LOAD_AMOUNT'
                                 THEN '260'
                                 WHEN p_loadamounttype_in='OTHER_AMOUNT'
                                 THEN '262'
                                 END,
                                 p_comment_in,
                                 0,
                                 l_curr_code,
                                 NULL,
                                 NULL,
                                 l_session_id,
                                 l_acct_no,
                                 1,
                                  null,
                                 1,
                                 NULL,
                                 l_final_bal,
                                 l_resp_code,
                                 l_resp_msg);

			IF l_resp_msg <>'OK'
			THEN
				p_status_out  := '49';
				p_err_msg_out := 'Error from sp_manual_adj_csr - ' ||  l_resp_msg;
				RAISE V_EXP_REJECTION;

			END IF;
      EXCEPTION
		WHEN V_EXP_REJECTION
		THEN
		RAISE V_EXP_REJECTION;

        WHEN OTHERS THEN

          p_status_out  := '49';
          p_err_msg_out := 'Error from sp_manual_adj_csr - ' || substr(sqlerrm,1,300);
          RAISE V_EXP_REJECTION;
      END;

      IF l_resp_code = '00'
      THEN
      BEGIN
					sp_clawback_recovery('1',
                                        l_plain_pan,
                                        '000',
                                        l_resp_msg);

                                IF l_resp_msg <> 'OK'
                                THEN
                                  p_status_out  :=  '49';
                                  p_err_msg_out := 'Error from sp_clawback_recovery - '|| l_resp_msg;
                                    RAISE V_EXP_REJECTION;

                                END IF;

          EXCEPTION
           WHEN V_EXP_REJECTION
           THEN RAISE V_EXP_REJECTION;
            WHEN OTHERS THEN
					p_status_out  :=  '49';
                    p_err_msg_out := 'Error from sp_clawback_recovery - '|| SUBSTR(SQLERRM,1,300);
                RAISE V_EXP_REJECTION;

          END;
      END IF;
     END IF;

      BEGIN
        SELECT cam_acct_bal,
               cam_ledger_bal,
               cam_type_code
          INTO l_acct_balance,
               l_ledger_balance,
               l_acct_type
          FROM cms_acct_mast
         WHERE cam_acct_no = l_acct_no
           AND cam_inst_code = 1;

      EXCEPTION
        WHEN OTHERS THEN
          p_err_msg_out := 'Error while selecting acct dtl' || SQLERRM;
		  RAISE V_EXP_REJECTION;
      END;




      UPDATE VMSCMS.TRANSACTIONLOG		--Added for VMS-5733/FSP-991
	  SET
             merchant_id   =   p_merchantid_in,
             terminal_id   =   p_terminalid_in
       WHERE rrn = l_rrn;

	   IF SQL%ROWCOUNT = 0 THEN

	   UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST		--Added for VMS-5733/FSP-991
	  SET
             merchant_id   =   p_merchantid_in,
             terminal_id   =   p_terminalid_in
       WHERE rrn = l_rrn;
	   END IF;

       IF p_locationid_in IS NOT NULL THEN
           UPDATE VMSCMS.CMS_TRANSACTION_LOG_DTL	--Added for VMS-5733/FSP-991
              SET ctd_location_id = p_locationid_in
           WHERE ctd_rrn = l_rrn;
		   IF SQL%ROWCOUNT = 0 THEN
		    UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST	--Added for VMS-5733/FSP-991
              SET ctd_location_id = p_locationid_in
           WHERE ctd_rrn = l_rrn;
		   END IF;
       END IF;

      p_status_out  := '00';
      p_err_msg_out := 'SUCCESS';


  EXCEPTION

    WHEN V_EXP_REJECTION
    THEN
    ROLLBACK;
                      INSERT INTO transactionlog
                        (msgtype,
                         rrn,
                         delivery_channel,
                         txn_code,
                         trans_desc,
                         txn_type,
                         txn_mode,
                         customer_card_no,
                         customer_card_no_encr,
                         business_date,
                         business_time,
                         txn_status,
                         response_code,
                         auth_id,
                         instcode,
                         date_time,
                         response_id,
                         customer_acct_no,
                         acct_balance,
                         ledger_balance,
                         acct_type,
                         cardstatus,
                         error_msg,
                         productid,
                         categoryid,
                         system_trace_audit_no)
                      VALUES
                        ('0200',
                         l_rrn,
                         p_delivery_chnl_in,
                         l_txn_code,
                         (SELECT ctm_tran_desc
                          FROM cms_transaction_mast
                         WHERE ctm_inst_code = 1
                           AND ctm_tran_code = l_txn_code
                           AND ctm_delivery_channel = p_delivery_chnl_in),
                         '0',
                         0,
                         l_hash_pan,
                         l_encr_pan,
                         to_char(SYSDATE,
                             'yyyymmdd'),
                         to_char(SYSDATE,
                             'hh24miss'),
                         'C',
                         p_status_out,
                         p_activationcode_out,
                         '1',
                         SYSDATE,
                         (SELECT cms_iso_respcde
								FROM cms_response_mast
								WHERE cms_inst_code = 1
								AND cms_delivery_channel = 17
								AND cms_response_id = p_status_out),
                         l_acct_no,
                         l_acct_balance,
                         l_ledger_balance,
                         l_acct_type,
                         l_card_stat,
                         p_err_msg_out,
                         l_prod_code,
                         l_card_type,
                         p_stan_out);

		INSERT INTO vmscms.cms_transaction_log_dtl
                        (ctd_delivery_channel,
                         ctd_txn_code,
                         ctd_txn_type,
                         ctd_msg_type,
                         ctd_txn_mode,
                         ctd_business_date,
                         ctd_business_time,
                         ctd_customer_card_no,
                         ctd_process_flag,
                         ctd_process_msg,
                         ctd_rrn,
                         ctd_inst_code,
                         ctd_customer_card_no_encr,
                         ctd_cust_acct_number,
                         ctd_system_trace_audit_no,
                         ctd_auth_id)
                      VALUES
                        (p_delivery_chnl_in,
                         l_txn_code,
                         '0',
                         '0200',
                         0,
                         to_char(SYSDATE,
                             'yyyymmdd'),
                         to_char(SYSDATE,
                             'hh24miss'),
                         l_hash_pan,
                         'Y',
                         p_err_msg_out,
                         l_rrn,
                         1,
                         l_encr_pan,
                         l_acct_no,
                         p_stan_out,
                         p_activationcode_out);

	WHEN OTHERS
    THEN

    ROLLBACK;

					p_status_out  :=  '49';
                    p_err_msg_out := SUBSTR(SQLERRM,1,300);

                      INSERT INTO transactionlog
                        (msgtype,
                         rrn,
                         delivery_channel,
                         txn_code,
                         trans_desc,
                         txn_type,
                         txn_mode,
                         customer_card_no,
                         customer_card_no_encr,
                         business_date,
                         business_time,
                         txn_status,
                         response_code,
                         auth_id,
                         instcode,
                         date_time,
                         response_id,
                         customer_acct_no,
                         acct_balance,
                         ledger_balance,
                         acct_type,
                         cardstatus,
                         error_msg,
                         productid,
                         categoryid,
                         system_trace_audit_no)
                      VALUES
                        ('0200',
                         l_rrn,
                         p_delivery_chnl_in,
                         l_txn_code,
                         (SELECT ctm_tran_desc
                          FROM cms_transaction_mast
                         WHERE ctm_inst_code = 1
                           AND ctm_tran_code = l_txn_code
                           AND ctm_delivery_channel = p_delivery_chnl_in),
                         '0',
                         0,
                         l_hash_pan,
                         l_encr_pan,
                         to_char(SYSDATE,
                             'yyyymmdd'),
                         to_char(SYSDATE,
                             'hh24miss'),
                         'C',
                         (SELECT cms_iso_respcde
								FROM cms_response_mast
								WHERE cms_inst_code = 1
								AND cms_delivery_channel = 17
								AND cms_response_id = p_status_out),
                         p_activationcode_out,
                         '1',
                         SYSDATE,
                         p_status_out,
                         l_acct_no,
                         l_acct_balance,
                         l_ledger_balance,
                         l_acct_type,
                         l_card_stat,
                         p_err_msg_out,
                         l_prod_code,
                         l_card_type,
                         p_stan_out);

		INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel,
                         ctd_txn_code,
                         ctd_txn_type,
                         ctd_msg_type,
                         ctd_txn_mode,
                         ctd_business_date,
                         ctd_business_time,
                         ctd_customer_card_no,
                         ctd_process_flag,
                         ctd_process_msg,
                         ctd_rrn,
                         ctd_inst_code,
                         ctd_customer_card_no_encr,
                         ctd_cust_acct_number,
                         ctd_system_trace_audit_no,
                         ctd_auth_id)
                      VALUES
                        (p_delivery_chnl_in,
                         l_txn_code,
                         '0',
                         '0200',
                         0,
                         to_char(SYSDATE,
                             'yyyymmdd'),
                         to_char(SYSDATE,
                             'hh24miss'),
                         l_hash_pan,
                         'Y',
                         p_err_msg_out,
                         l_rrn,
                         1,
                         l_encr_pan,
                         l_acct_no,
                         p_stan_out,
                         p_activationcode_out);


  END replace_card_b2b_v2;

END VMSB2BAPI;