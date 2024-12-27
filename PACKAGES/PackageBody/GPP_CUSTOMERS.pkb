create or replace PACKAGE BODY  vmscms.GPP_CUSTOMERS IS
  -- Author  : Rojalin
  -- Created : 10/27/2015 11:35:30 AM
  -- Purpose :
  --global variable declarations
  g_api_name VARCHAR2(30) := 'SEARCH CUSTOMERS';
  -- global variables for the FS framework
  g_config fsfw.fstype.parms_typ;
  g_debug  fsfw.fsdebug_t;

  --declare all FS errors here
  g_err_nodata       fsfw.fserror_t;
  g_err_unknown      fsfw.fserror_t;
  g_err_mandatory    fsfw.fserror_t;
  g_err_invalid_data fsfw.fserror_t;

  -- Function and procedure implementations
  PROCEDURE mandatory_check(p_searchtype_in     IN VARCHAR2,
                            p_accountnumber_in  IN VARCHAR2,
                            p_serialnumber_in   IN VARCHAR2,
                            p_proxynumber_in    IN VARCHAR2,
                            p_pan_in            IN VARCHAR2,
                            p_firstname_in      IN VARCHAR2,
                            p_lastname_in       IN VARCHAR2,
                            p_identity_id_in    IN VARCHAR2,
                            p_identity_type_in  IN VARCHAR2,
                            p_dateofbirth_in    IN VARCHAR2,
                            p_email_in          IN VARCHAR2,
                            p_address_in        IN VARCHAR2,
                            p_city_in           IN VARCHAR2,
                            p_state_in          IN VARCHAR2,
                            p_postalcode_in     IN VARCHAR2,
                            p_onlineuserid_in   IN VARCHAR2,
                            p_card_id_in        IN VARCHAR2,
                            p_transaction_id_in IN VARCHAR2,
                            p_from_date_in      IN VARCHAR2,
                            p_to_date_in        IN VARCHAR2,
                            p_err_msg_out       OUT VARCHAR2,
                            p_flag              OUT PLS_INTEGER) AS

  BEGIN

    CASE
      WHEN (length(p_pan_in) = 4 AND p_lastname_in IS NULL) THEN
        p_err_msg_out := 'LAST NAME is mandatory when PAN is provided as input';
        p_flag        := 1;
      WHEN ((p_identity_id_in IS NOT NULL AND p_identity_type_in IS NULL) OR
           (p_identity_id_in IS NULL AND p_identity_type_in IS NOT NULL)) THEN
        p_err_msg_out := 'Both IDENTIFICATION ID and IDENTIFICATION TYPE are mandatory';
        p_flag        := 1;
      WHEN ((upper(p_identity_type_in) IN
           ('SSN',
              'SIN')) AND length(p_identity_id_in) = 4 AND
           p_lastname_in IS NULL) THEN
        p_err_msg_out := 'LAST NAME is mandatory when Identity Type is SSN or SIN';
        p_flag        := 1;
      WHEN ((p_identity_type_in IS NOT NULL) AND
           (upper(p_identity_type_in) NOT IN
           ('SSN',
              'SIN',
              'DL',
              'PASS',
              'ITIN'))) THEN
        p_err_msg_out := 'Invalid IDENTIFICATION TYPE';
        p_flag        := 1;
      WHEN (p_searchtype_in IS NOT NULL AND upper(p_searchtype_in) <> 'KYC') THEN
        p_err_msg_out := 'Invalid search type';
        p_flag        := 1;
      WHEN (p_accountnumber_in IS NULL AND p_proxynumber_in IS NULL AND
           p_serialnumber_in IS NULL AND p_onlineuserid_in IS NULL AND
           p_email_in IS NULL AND p_address_in IS NULL AND
           p_pan_in IS NULL AND p_card_id_in IS NULL AND
           p_transaction_id_in IS NULL) THEN

        CASE

          WHEN (p_firstname_in IS NOT NULL AND p_lastname_in IS NULL AND
               p_dateofbirth_in IS NULL AND p_city_in IS NULL AND
               p_state_in IS NULL AND p_postalcode_in IS NULL AND
               p_identity_id_in IS NULL AND p_identity_type_in IS NULL) THEN
            p_err_msg_out := 'FIRST NAME with any of the fields LAST NAME, DATEOFBIRTH, (IDENTITY ID and IDENTITY TYPE), CITY, STATE, POSTALCODE are mandatory';
            p_flag        := 1;
          WHEN (p_lastname_in IS NOT NULL AND p_firstname_in IS NULL AND
               p_dateofbirth_in IS NULL AND p_city_in IS NULL AND
               p_state_in IS NULL AND p_postalcode_in IS NULL AND
               p_identity_id_in IS NULL AND p_identity_type_in IS NULL) THEN
            p_err_msg_out := 'LAST NAME with any of the fields FIRST NAME, DATEOFBIRTH, (IDENTITY ID and IDENTITY TYPE), CITY, STATE, POSTALCODE are mandatory';
            p_flag        := 1;
          WHEN (p_city_in IS NOT NULL AND p_firstname_in IS NULL AND
               p_lastname_in IS NULL AND p_dateofbirth_in IS NULL AND
               p_state_in IS NULL AND p_postalcode_in IS NULL AND
               p_identity_id_in IS NULL AND p_identity_type_in IS NULL) THEN
            p_err_msg_out := 'CITY with any of the fields FIRST NAME, LAST NAME, DATEOFBIRTH, (IDENTITY ID and IDENTITY TYPE), STATE, POSTALCODE are mandatory';
            p_flag        := 1;
          WHEN (p_state_in IS NOT NULL AND p_firstname_in IS NULL AND
               p_lastname_in IS NULL AND p_dateofbirth_in IS NULL AND
               p_city_in IS NULL AND p_postalcode_in IS NULL AND
               p_identity_id_in IS NULL AND p_identity_type_in IS NULL) THEN
            p_err_msg_out := 'STATE with any of the fields FIRST NAME, LAST NAME, DATEOFBIRTH, (IDENTITY ID and IDENTITY TYPE), CITY, POSTALCODE are mandatory';
            p_flag        := 1;
          WHEN (p_postalcode_in IS NOT NULL AND p_firstname_in IS NULL AND
               p_lastname_in IS NULL AND p_dateofbirth_in IS NULL AND
               p_city_in IS NULL AND p_state_in IS NULL AND
               p_identity_id_in IS NULL AND p_identity_type_in IS NULL) THEN
            p_err_msg_out := 'POSTALCODE with any of the fields FIRST NAME, LAST NAME, DATEOFBIRTH, (IDENTITY ID and IDENTITY TYPE), CITY, STATE are mandatory';
            p_flag        := 1;
          WHEN (p_firstname_in IS NULL AND p_lastname_in IS NULL AND
               p_dateofbirth_in IS NULL AND p_city_in IS NULL AND
               p_state_in IS NULL AND p_postalcode_in IS NULL AND
               p_identity_id_in IS NULL AND p_identity_type_in IS NULL) THEN
            p_err_msg_out := 'SEARCH TYPE alone is insufficient input';
            p_flag        := 1;

          ELSE

            p_flag := 0;
        END CASE;
      ELSE

        p_flag := 0;
    END CASE;
  END mandatory_check;

  ---- CFIP 376 start
  PROCEDURE search_address(p_address_in     IN VARCHAR2,
                           p_sort_clause_in IN VARCHAR2,
                           p_status_out     OUT VARCHAR2,
                           p_err_msg_out    OUT VARCHAR2,
                           c_customers_out  OUT SYS_REFCURSOR,
                           c_customer_list  OUT SYS_REFCURSOR) AS
    l_partner_id vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;
    l_query      VARCHAR2(32000);
  BEGIN
    l_start_time := dbms_utility.get_time;
    g_debug.display('l_start_time' || l_start_time);
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    --l_partner_id := 'INCOMM';
    l_query := q'[ SELECT DISTINCT b.ccm_cust_id customerid,
                                    spending.cam_acct_no accountnumber,
                                   -- i.cpc_rout_num routing_number,
								   	NVL(i.cpc_rout_num,i.cpc_institution_id
                                        ||'-'
                                        ||i.cpc_transit_number) routing_number,
--                                    b.ccm_first_name firstname,
--                                    b.ccm_mid_name middlename,
--                                    b.ccm_last_name lastname,
                                    vmscms.fn_dmaps_main(b.ccm_first_name) firstname,
                                    vmscms.fn_dmaps_main(b.ccm_mid_name) middlename,
                                    vmscms.fn_dmaps_main(b.ccm_last_name) lastname,
--                                    b.ccm_mother_name mother_maidenname,
                                    vmscms.fn_dmaps_main(b.ccm_mother_name) mother_maidenname,
                                    CASE
                                      WHEN saving.CAM_INITIALLOAD_AMT > 0 THEN
                                       saving.CAM_INITIALLOAD_AMT
                                      ELSE
                                       spending.CAM_INITIALLOAD_AMT
                                    END initial_load_amt,
                                    f.cim_idtype_desc identity_type,
                                    b.ccm_ssn identity_number,
                                    TO_CHAR(b.ccm_birth_date,
                                            'yyyy-mm-dd') dateofbirth,
--                                    a.cam_email email,
                                    vmscms.fn_dmaps_main(a.cam_email) email,
                                    CASE a.cam_addr_flag
                                      WHEN 'P' THEN
                                       'PHYSICAL'
                                    END addr_type1,
--                                    a.cam_add_one physical_address1,
--                                    a.cam_add_two physical_address2,
--                                    a.cam_city_name physical_city,
                                    vmscms.fn_dmaps_main(a.cam_add_one) physical_address1,
                                    vmscms.fn_dmaps_main(a.cam_add_two) physical_address2,
                                    vmscms.fn_dmaps_main(a.cam_city_name) physical_city,
                                    (SELECT upper(gsm_switch_state_code)
                                       FROM vmscms.gen_state_mast
                                      WHERE gsm_inst_code = a.cam_inst_code
                                        AND gsm_state_code = a.cam_state_code
                                        AND gsm_cntry_code = a.cam_cntry_code) physical_state,
 --                                     a.cam_pin_code physical_postalcode,
                                      decode(i.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(a.cam_pin_code),a.cam_pin_code) physical_postalcode,
                                      (SELECT SUBSTR(upper(gcm_cntry_name),
                                                   1,
                                                   2)
                                       FROM vmscms.gen_cntry_mast
                                      WHERE gcm_inst_code = 1
                                        AND gcm_inst_code = a.cam_inst_code
                                        AND gcm_cntry_code = a.cam_cntry_code) physical_countrycode,
                                    a.cam_lupd_date physical_lastupdatetimestamp,
                                    CASE e.cam_addr_flag
                                      WHEN 'O' THEN
                                       'MAILING'
                                    END addr_type2,
--                                    e.cam_add_one mailing_address1,
--                                    e.cam_add_two mailing_address2,
--                                    e.cam_city_name mailing_city,
                                    vmscms.fn_dmaps_main(e.cam_add_one) mailing_address1,
                                    vmscms.fn_dmaps_main(e.cam_add_two) mailing_address2,
                                    vmscms.fn_dmaps_main(e.cam_city_name) mailing_city,
                                    (SELECT upper(gsm_switch_state_code)
                                       FROM vmscms.gen_state_mast
                                      WHERE gsm_inst_code = e.cam_inst_code
                                        AND gsm_state_code = e.cam_state_code
                                        AND gsm_cntry_code = e.cam_cntry_code) mailing_state,
--                                    e.cam_pin_code mailing_postalcode,
                                      decode(i.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(e.cam_pin_code),e.cam_pin_code) mailing_postalcode,
                                      (SELECT SUBSTR(upper(gcm_cntry_name),
                                                   1,
                                                   2)
                                       FROM vmscms.gen_cntry_mast
                                      WHERE gcm_inst_code = 1
                                        AND gcm_inst_code = e.cam_inst_code
                                        AND gcm_cntry_code = e.cam_cntry_code) mailing_countrycode,
                                    e.cam_lupd_date mailing_lastupdatetimestamp,
--                                    b.ccm_user_name onlineuserid,
                                    vmscms.fn_dmaps_main(b.ccm_user_name) onlineuserid,
				                    case when i.cpc_user_identify_type in ('1','4') then 'GIFT' else 'GPR' end cardtype,
                                    TO_CHAR(NVL(spending.cam_ledger_bal,
                                                0),
                                            '9,999,999,990.99') spendingacct_ledgerbalance,
                                    TO_CHAR(NVL(spending.cam_acct_bal,
                                                0),
                                            '9,999,999,990.99') spendingacct_availablebalance,
                                    TO_CHAR(NVL(saving.cam_acct_bal,
                                                0),
                                            '9,999,999,990.99') savingacct_ledgerbalance,
                                    NULL regn_source,
                                    NULL status,
                                    NULL kyc_failure_reason,
                                    NULL ofac_status,
                                    NULL ofac_desc
                      FROM vmscms.cms_addr_mast a,
                           vmscms.cms_cust_mast b,
                           --vmscms.cms_prod_mast c,
                           vmscms.cms_prod_cattype i,
                           vmscms.cms_addr_mast e,
                           (SELECT *
                              FROM vmscms.cms_acct_mast, vmscms.cms_cust_acct
                             WHERE cam_type_code = '1'
                               AND cca_acct_id = cam_acct_id
                               AND cca_inst_code = cam_inst_code
                               AND cca_inst_code = 1) spending,
                           (SELECT *
                              FROM vmscms.cms_acct_mast, vmscms.cms_cust_acct
                             WHERE cam_type_code = '2'
                               AND cca_acct_id = cam_acct_id
                               AND cca_inst_code = cam_inst_code
                               AND cca_inst_code = 1) saving,
                           vmscms.cms_idtype_mast f
                     WHERE a.cam_inst_code = b.ccm_inst_code
                       AND a.cam_cust_code = b.ccm_cust_code
                       AND a.cam_addr_flag = 'P'
                       AND b.ccm_inst_code = e.cam_inst_code(+)
                       AND b.ccm_cust_code = e.cam_cust_code(+)
                       AND 'O'             = e.cam_addr_flag(+)
                       AND b.ccm_inst_code = saving.cca_inst_code(+)
                       AND b.ccm_cust_code = saving.cca_cust_code(+)
                       AND b.ccm_inst_code = spending.cca_inst_code
                       AND b.ccm_cust_code = spending.cca_cust_code
                       AND b.ccm_inst_code = i.cpc_inst_code
                       AND b.ccm_prod_code = i.cpc_prod_code
                       AND b.ccm_card_type = i.cpc_card_type
                       -- changes for Global Search
                       -- AND b.ccm_partner_id = :l_partner_id
                       AND nvl(b.ccm_prod_code,'~') || nvl(to_char(b.ccm_card_type),'^') =
                                   vmscms.gpp_utils.get_prod_code_card_type
                                   (
                                   p_partner_id_in => :partner_id,
                                   p_prod_code_in => b.ccm_prod_code,
                                   p_card_type_in => b.ccm_card_type
                                   )
                       AND b.ccm_id_type    = f.cim_idtype_code(+)
                       AND EXISTS
                     (SELECT 1
                              FROM vmscms.cms_appl_pan d
                             WHERE d.cap_inst_code = b.ccm_inst_code
                               AND d.cap_cust_code = b.ccm_cust_code
                               AND d.cap_inst_code = i.cpc_inst_code
                               AND d.cap_prod_code = i.cpc_prod_code
			                   AND d.cap_card_type = i.cpc_card_type)
                       AND upper(a.cam_add_one || a.cam_add_two) = :p_address_in
                       ORDER BY ]';

    l_query := l_query || p_sort_clause_in;

    g_debug.display(p_message_in => l_query);

    OPEN c_customer_list FOR l_query
      USING l_partner_id, p_address_in;
    OPEN c_customers_out FOR l_query
      USING l_partner_id, p_address_in;

    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

  EXCEPTION
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(g_api_name,
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(g_api_name,
                                                   NULL, --customer id
                                                   NULL, --hash pan
                                                   NULL, --encrypted pan
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken); --Remarks
      RETURN;
  END search_address;
  ---- CFIP 376 end

  PROCEDURE get_cards_array(c_customer_list   IN  SYS_REFCURSOR,
                            c_cards_out       OUT SYS_REFCURSOR,
                            p_status_out      OUT VARCHAR2,
                            p_err_msg_out     OUT VARCHAR2) AS
    l_timetaken NUMBER;

    --Index by table to store the customer details
    TYPE ty_rec_cust_list IS RECORD(
      customerid               vmscms.cms_cust_mast.ccm_cust_id%type,
      accountnumber            vmscms.cms_appl_pan.cap_acct_no%type,
      routing_number           VARCHAR2(50),
      firstname                vmscms.cms_cust_mast.ccm_first_name%type,
      middlename               vmscms.cms_cust_mast.ccm_mid_name%type,
      lastname                 vmscms.cms_cust_mast.ccm_last_name%type,
      mother_maidenname        vmscms.cms_cust_mast.ccm_mother_name%type,
      initial_load_amt         vmscms.cms_acct_mast.cam_initialload_amt%type,
      identity_type            vmscms.cms_idtype_mast.cim_idtype_desc%type,
      identity_number          vmscms.cms_cust_mast.ccm_ssn%type,
      dateofbirth              VARCHAR2(20),
      email                    vmscms.cms_addr_mast.cam_email%type,
      addr_type1               VARCHAR2(50),
      phy_address1             vmscms.cms_addr_mast.cam_add_one%type,
      phy_address2             vmscms.cms_addr_mast.cam_add_two%type,
      phy_city                 vmscms.cms_addr_mast.cam_city_name%type,
      phy_state                vmscms.gen_state_mast.gsm_switch_state_code%type,
      phy_postalcode           vmscms.cms_addr_mast.cam_pin_code%type,
      phy_countrycode          vmscms.gen_cntry_mast.gcm_cntry_name%type,
      phy_lastupdatetimestamp  vmscms.cms_addr_mast.cam_lupd_date%type,
      addr_type2               VARCHAR2(50),
      mail_address1            vmscms.cms_addr_mast.cam_add_one%type,
      mail_address2            vmscms.cms_addr_mast.cam_add_two%type,
      mail_city                vmscms.cms_addr_mast.cam_city_name%type,
      mail_state               vmscms.gen_state_mast.gsm_switch_state_code%type,
      mail_postalcode          vmscms.cms_addr_mast.cam_pin_code%type,
      mail_countrycode         vmscms.gen_cntry_mast.gcm_cntry_name%type,
      mail_lastupdatetimestamp vmscms.cms_addr_mast.cam_lupd_date%type,
      onlineuserid             vmscms.cms_cust_mast.ccm_user_name%type,
	    cardtype                 VARCHAR2(20),
      spend_acc_led_bal        VARCHAR2(20),
      spend_acc_available_bal  VARCHAR2(20),
      savings_led_bal          VARCHAR2(20),
      regn_source              VARCHAR2(20),
      status                   vmscms.cms_kycstatus_mast.ckm_flag_desc%type,
      failurereason            vmscms.cms_kyctxn_log.ckl_kyc_msg%type,
      ofacstatus               VARCHAR2(10),
      ofacdescription          vmscms.cms_kyctxn_log.ckl_kycres_restricted_message%type);
    TYPE ty_tbl_cust_list IS TABLE OF ty_rec_cust_list INDEX BY PLS_INTEGER;
    l_tbl_cust_list ty_tbl_cust_list;

    --Index by table to store the cards details
    TYPE ty_rec_acct_list IS RECORD(
      accountnumber   vmscms.cms_appl_pan.cap_acct_no%type,
      pan             vmscms.cms_appl_pan.cap_mask_pan%type,
      productcategory vmscms.cms_prod_cattype.cpc_cardtype_desc%TYPE,
      activationdate  vmscms.cms_appl_pan.cap_active_date%type,
      card_status     vmscms.cms_card_stat.ccs_stat_desc%type,
      card_id         vmscms.cms_appl_pan.cap_mask_pan%type,
      isstartercard   VARCHAR2(10), -- JIRA:CFIP-359
      proxynumber     vmscms.cms_appl_pan.cap_proxy_number%TYPE,
      serialnumber    vmscms.cms_appl_pan.cap_serial_number%TYPE,
      parentserialno  vmscms.cms_appl_pan.cap_panmast_param2%TYPE);
    TYPE ty_tbl_acct_list IS TABLE OF ty_rec_acct_list INDEX BY PLS_INTEGER;
    l_tbl_acct_list ty_tbl_acct_list;

    --Table of globally declared object:card_list_t...To store cards array--required for table casting
    l_tbl_card_list tb_card_list_t := tb_card_list_t();

    l_start_card_step NUMBER;
    l_end_card_step   NUMBER;

    c_vms_del_channel VARCHAR2(1) := '1'; -- JIRA:CFIP-359
  BEGIN
    --g_debug.display('fetching cust list to table');
    --Populating index by table(l_tbl_cust_list) with customer details from the input cursor
    l_start_card_step := dbms_utility.get_time;
    g_debug.display('l_start_card_step - loop fetch cust list -' ||
                    l_start_card_step);

    LOOP
      FETCH c_customer_list BULK COLLECT
        INTO l_tbl_cust_list;
      EXIT WHEN c_customer_list%NOTFOUND;
    END LOOP;

    l_end_card_step := dbms_utility.get_time;
    g_debug.display('l_end_card_step - loop fetch cust list -' ||
                    l_end_card_step);

    CLOSE c_customer_list;

    --Loop for debug
    -- g_debug.display('l_tbl_cust_list.count' || l_tbl_cust_list.count);
    /*IF l_tbl_cust_list.count > 0
    THEN
       FOR i IN l_tbl_cust_list.first .. l_tbl_cust_list.last
       LOOP
          g_debug.display(g_debug.format('account number : $1',
                                         l_tbl_cust_list(i).accountnumber));
       END LOOP;
    END IF;*/

    --g_debug.display('using object implementation');

    IF l_tbl_cust_list.count > 0
    THEN
      FOR i IN l_tbl_cust_list.first .. l_tbl_cust_list.last
      LOOP
        --g_debug.display(g_debug.format('i : $1', i));
        --Populating index by table(l_tbl_acct_list) with cards details for the account numbers fetched from cursor

        SELECT cap_acct_no,
               --cap_mask_pan pan,
               vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) pan,
               cpc_cardtype_desc productcategory,
               cap_active_date activationdate,
               (SELECT ccs_stat_desc
                  FROM vmscms.cms_card_stat
                 WHERE ccs_inst_code = cap_inst_code
                   AND ccs_stat_code = cap_card_stat) cardstatus,
               substr(vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)),
                      0,
                      6) || c_vms_del_channel || cap_card_id AS card_id, -- JIRA:CFIP-359
               decode(cap_startercard_flag,
                      'Y',
                      'TRUE',
                      'N',
                      'FALSE',
                      'FALSE') AS isstartercard, -- CFIP 393
               a.cap_proxy_number,
               a.cap_serial_number,
               a.cap_panmast_param2
          BULK COLLECT
          INTO l_tbl_acct_list
          FROM vmscms.cms_appl_pan a, vmscms.cms_prod_cattype
         WHERE cap_prod_code = cpc_prod_code
           AND cap_card_type = cpc_card_type
           AND cap_acct_no = l_tbl_cust_list(i).accountnumber;

        IF l_tbl_acct_list.count > 0
        THEN
          FOR j IN l_tbl_acct_list.first .. l_tbl_acct_list.last
          LOOP
            --g_debug.display(g_debug.format('j : $1', j));
            --Populating table of object type(l_tbl_card_list) with cards details
            l_tbl_card_list.extend();
            l_tbl_card_list(l_tbl_card_list.last) := card_list_t(l_tbl_acct_list(j)
                                                                 .accountnumber,
                                                                 l_tbl_acct_list(j).pan,
                                                                 l_tbl_acct_list(j)
                                                                 .productcategory,
                                                                 l_tbl_acct_list(j)
                                                                 .activationdate,
                                                                 l_tbl_acct_list(j)
                                                                 .card_status,
                                                                 l_tbl_acct_list(j)
                                                                 .card_id,
                                                                 l_tbl_acct_list(j) .
                                                                  isstartercard,
                                                                 l_tbl_acct_list(j) .
                                                                  proxynumber,
                                                                  l_tbl_acct_list(j).serialnumber, -- JIRA:CFIP-359
                                                                  l_tbl_acct_list(j).parentserialno);
          END LOOP;

        END IF;
      END LOOP;
    END IF;

    --Loop for debug
    /* IF l_tbl_card_list.count > 0
    THEN
       FOR i IN l_tbl_card_list.first .. l_tbl_card_list.last
       LOOP
          g_debug.display(g_debug.format('pan no : $1',
                                         l_tbl_card_list(i).pan));
       END LOOP;
    END IF;*/

    --Casting table of object to table
    l_start_card_step := dbms_utility.get_time;
    g_debug.display('l_start_card_step - OPEN c_cards_out -' ||
                    l_start_card_step);

    OPEN c_cards_out FOR
      SELECT * FROM TABLE(l_tbl_card_list);

    l_end_card_step := dbms_utility.get_time;
    g_debug.display('l_end_card_step - OPEN c_cards_out -' ||
                    l_end_card_step);

  EXCEPTION
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(g_api_name,
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(g_api_name,
                                                   NULL, --customer id
                                                   NULL, --hash pan
                                                   NULL, --encrypted pan
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken); --Remarks
      RETURN;
  END get_cards_array;
  --Search Customers API
  PROCEDURE get_customers(p_searchtype_in     IN VARCHAR2,
                          p_sortorder_in      IN VARCHAR2,
                          p_sortelement_in    IN VARCHAR2,
                          p_recordsperpage_in IN VARCHAR2,
                          p_pagenumber_in     IN VARCHAR2,
                          p_accountnumber_in  IN VARCHAR2,
                          p_serialnumber_in   IN VARCHAR2,
                          p_proxynumber_in    IN VARCHAR2,
                          p_pan_in            IN VARCHAR2,
                          p_firstname_in      IN VARCHAR2,
                          p_lastname_in       IN VARCHAR2,
                          p_identity_id_in    IN VARCHAR2,
                          p_identity_type_in  IN VARCHAR2,
                          p_dateofbirth_in    IN VARCHAR2,
                          p_email_in          IN VARCHAR2,
                          p_address_in        IN VARCHAR2,
                          p_city_in           IN VARCHAR2,
                          p_state_in          IN VARCHAR2,
                          p_postalcode_in     IN VARCHAR2,
                          p_onlineuserid_in   IN VARCHAR2,
                          p_card_id_in        IN VARCHAR2,
                          p_transaction_id_in IN VARCHAR2,
                          p_from_date_in      IN VARCHAR2,
                          p_to_date_in        IN VARCHAR2,
                          p_status_out        OUT VARCHAR2,
                          p_err_msg_out       OUT VARCHAR2,
                          c_customers_out     OUT SYS_REFCURSOR,
                          c_cards_out         OUT SYS_REFCURSOR) AS
    l_recordsperpage PLS_INTEGER;
    l_pagenumber     PLS_INTEGER;
    l_rec_start_no   PLS_INTEGER;
    l_rec_end_no     PLS_INTEGER;
    l_sort_element   VARCHAR2(20);
    l_ssn_length     PLS_INTEGER;
    l_ssn_flag       CHAR(1);
    exp_mandatory_chk   EXCEPTION;
    exp_customers_array EXCEPTION;
    c_customer_list  SYS_REFCURSOR;
    l_flag           PLS_INTEGER := 0;
    l_partner_id     vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_state          VARCHAR2(10);
    l_order_by       VARCHAR2(100);
    l_sort_order     VARCHAR2(20);
    l_identity_type  VARCHAR2(50);
    l_query          VARCHAR2(32000);
    l_common_where   VARCHAR2(32000);
    l_common_from    VARCHAR2(32000);
    l_where_query    VARCHAR2(32000);
    l_row_query      VARCHAR2(32000);
    l_identity_type  VARCHAR2(50);
    l_pan            vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_firstname      vmscms.cms_cust_mast.ccm_first_name%TYPE;
    l_lastname       vmscms.cms_cust_mast.ccm_last_name%TYPE;
    l_firstname_wc   vmscms.cms_cust_mast.ccm_first_name%TYPE;
    l_lastname_wc    vmscms.cms_cust_mast.ccm_last_name%TYPE;
    l_firstname_wild vmscms.cms_cust_mast.ccm_first_name%TYPE;
    l_lastname_wild  vmscms.cms_cust_mast.ccm_first_name%TYPE;
    l_card_id        VARCHAR2(50);
    l_start_time     NUMBER;
    l_end_time       NUMBER;
    l_timetaken      NUMBER;

    l_start_step_time NUMBER;
    l_end_step_time   NUMBER;
    l_step_timetaken  NUMBER;

    l_ctr          PLS_INTEGER;
    l_id_type_text VARCHAR2(100);

    l_kyc_with_sql VARCHAR2(32000);
    l_kyc_query    VARCHAR2(32000);

    l_from_date DATE;
    l_to_date   DATE;
    l_parent_serialno   vmscms.cms_appl_pan.cap_panmast_param2%TYPE;
    V_REC_CHECK    number;
    V_DELETE_DATE DATE;
    V_D_SQL  VARCHAR2(4000);
/***************************************************************************************
	     * Modified By        : Vini
         * Modified Date      : 15-Feb-2019
         * Modified Reason    : VMS-754
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 15-Feb-2019
         * Build Number       : R12_B0005
	 
	 * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002
		 
		  * Modified By                  : Ubaidur Rahman.H
	 * Modified Date                : 26-NOV-2021
	 * Modified Reason              : VMS-5253 - Do not pass system Generated Profile from VMS to CCA
	 * Build Number                 : R55 B3
	 * Reviewer                     : Saravanakumar A.
	 * Reviewed Date                : 26-Nov-2021
	 
	 * Modified By                  : John G
	 * Modified Date                : 08-DEC-2022
	 * Modified Reason              : VMS-6034
	 * Build Number                 : R73 B1
	 * Reviewer                     : Venkat S
	 * Reviewed Date                : 
	 
***************************************************************************************/
BEGIN
    l_start_time := dbms_utility.get_time;
    --g_debug.display('l_start_time' || l_start_time);

    g_debug.display('new code');
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    --l_partner_id := 'INCOMM';
    l_sort_order := CASE upper(p_sortorder_in)
                      WHEN 'ASCENDING' THEN
                       'ASC'
                      WHEN 'DESCENDING' THEN
                       'DESC'
                      ELSE
                       'ASC'
                    END;

    l_order_by        := nvl(upper(p_sortelement_in),
                             'FIRSTNAME') || ' ' || l_sort_order;
    l_start_step_time := dbms_utility.get_time;
    g_debug.display('l_start_step_time - mandatory_check ' ||
                    l_start_step_time);
    --Check for mandatory fields
    mandatory_check(p_searchtype_in,
                    p_accountnumber_in,
                    p_serialnumber_in,
                    p_proxynumber_in,
                    p_pan_in,
                    p_firstname_in,
                    p_lastname_in,
                    p_identity_id_in,
                    p_identity_type_in,
                    p_dateofbirth_in,
                    p_email_in,
                    p_address_in,
                    p_city_in,
                    p_state_in,
                    p_postalcode_in,
                    p_onlineuserid_in,
                    p_card_id_in,
                    p_transaction_id_in,
                    p_from_date_in,
                    p_to_date_in,
                    p_err_msg_out,
                    l_flag);

    l_end_step_time := dbms_utility.get_time;
    g_debug.display('l_end_step_time - mandatory_check - : ' ||
                    l_end_step_time);
    l_step_timetaken := (l_end_step_time - l_start_step_time) / 100;
    g_debug.display(p_message_in => 'Time taken by mandatory_check');

    IF l_flag = 1
    THEN
      p_status_out := vmscms.gpp_const.c_mandatory_status;
      g_err_mandatory.raise(g_api_name,
                            ',0002,',
                            p_err_msg_out);
      p_err_msg_out := p_status_out || ',' || '0002' || ',' ||
                       p_err_msg_out;
      vmscms.gpp_transaction.audit_transaction_log(g_api_name,
                                                   NULL, --customer id
                                                   NULL, --hash pan
                                                   NULL, --encrypted pan
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken); --Remarks
      RETURN;
    END IF;
    IF (p_identity_type_in IN ('SSN',
                               'SIN') AND
       length(p_identity_id_in) NOT IN
       ('4',
         '9'))
    THEN
      p_status_out := vmscms.gpp_const.c_invalid_idlength_status;
      g_err_invalid_data.raise(g_api_name,
                               ',0043,',
                               'FOR SSN SIN, ID NUMBER SHOULD BE 9 OR 4 CHARACTER');
      p_err_msg_out := g_err_invalid_data.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(g_api_name,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL, --Remarks
                                                   l_timetaken);
      RETURN;
    END IF;

    l_start_step_time := dbms_utility.get_time;
    g_debug.display('l_start_step_time REGEXP' || l_start_step_time);

    IF (regexp_instr(substr(p_firstname_in,
                            1,
                            3),
                     '[^a-z^A-Z^0-9]') = 0) = FALSE
       OR (regexp_instr(substr(p_lastname_in,
                               1,
                               3),
                        '[^a-z^A-Z^0-9]') = 0) = FALSE
    THEN
      p_status_out := vmscms.gpp_const.c_invalid_fllength_status;
      g_err_invalid_data.raise(g_api_name,
                               ',0038,',
                               'FIRST  AND LAST NAME SHOULD NOT HAVE WILD CARD CHARACTER IN FIRST 3 CHARACTER');
      p_err_msg_out := g_err_invalid_data.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(g_api_name,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL, --Remarks
                                                   l_timetaken);
      RETURN;
    END IF;

    l_end_step_time := dbms_utility.get_time;
    g_debug.display('l_end_step_time - regexp - ' || l_end_step_time);

    l_step_timetaken := (l_end_step_time - l_start_step_time) / 100;
    g_debug.display(p_message_in => 'Time taken by first_name last_name reg exp check');

    IF upper(p_searchtype_in) = 'KYC'
    THEN
      g_debug.display('In KYC');

      l_kyc_with_sql := q'[WITH kyctab AS
                           (SELECT *
                              FROM (SELECT a.cci_starter_acct_no accountnumber,
--                                           a.cci_seg12_name_line1 firstname,
--                                           a.cci_seg12_name_line2 lastname,
--                                           a.cci_mothers_maiden_name mother_maidenname,
                                           vmscms.fn_dmaps_main(a.cci_seg12_name_line1) firstname,
                                           vmscms.fn_dmaps_main(a.cci_seg12_name_line2) lastname,
                                           vmscms.fn_dmaps_main(a.cci_mothers_maiden_name) mother_maidenname,
                                           a.cci_document_verify IDTYPE,
                                           decode(nvl(a.cci_document_verify,
                                                      '-'),
                                                  '-',
                                                  '-',
                                                  'SSN',
                                                  'Social Security Number',
                                                  'DL',
                                                  'Driving License',
                                                  'PASS',
                                                  'Passport',
                                                  'SIN',
                                                  'Social Insurance Number',
                                                  a.cci_document_verify) identity_type,
                                           DECODE(a.CCI_ID_NUMBER,
                                                  NULL,
                                                  a.cci_ssn,
                                                  a.cci_id_number) identity_number,
                                           a.cci_ssn cci_ssn,
                                           a.cci_ssn_encr cci_ssn_encr, -- CFIP 301 to make full ssn search,
                                           a.cci_id_number_encr cci_id_number_encr, -- CFIP 301 to make full DL,Pass encrypted search,
                                           to_char(a.cci_birth_date,
                                                   'yyyy-mm-dd') dateofbirth,
                                           a.cci_birth_date birthdate,
--                                           a.cci_seg12_emailid email,
                                           vmscms.fn_dmaps_main(a.cci_seg12_emailid) email,
                                           'PHYSICAL' addr_type1,
--                                           a.cci_seg12_addr_line1 physical_address1,
--                                           a.cci_seg12_addr_line2 physical_address2,
--                                           a.cci_seg12_city physical_city,
                                           vmscms.fn_dmaps_main(a.cci_seg12_addr_line1) physical_address1,
                                           vmscms.fn_dmaps_main(a.cci_seg12_addr_line2) physical_address2,
                                           vmscms.fn_dmaps_main(a.cci_seg12_city) physical_city,
                                           a.cci_seg12_state physical_state,
--                                           a.cci_seg12_postal_code physical_postalcode,
                                           vmscms.fn_dmaps_main(a.cci_seg12_postal_code) physical_postalcode,
                                           (SELECT substr(upper(gcm_cntry_name),
                                                          1,
                                                          2)
                                              FROM vmscms.gen_cntry_mast cs
                                             WHERE cs.gcm_inst_code = cci_inst_code
                                               AND cs.gcm_cntry_code = a.cci_seg12_country_code) physical_countrycode,
                                           'MAILING' addr_type2,
--                                           a.cci_seg13_addr_line1 mailing_address1,
--                                           a.cci_seg13_addr_line2 mailing_address2,
--                                           a.cci_seg13_city mailing_city,
                                           vmscms.fn_dmaps_main(a.cci_seg13_addr_line1) mailing_address1,
                                           vmscms.fn_dmaps_main(a.cci_seg13_addr_line2) mailing_address2,
                                           vmscms.fn_dmaps_main(a.cci_seg13_city) mailing_city,
                                           a.cci_seg13_state mailing_state,
--                                           a.cci_seg13_postal_code mailing_postalcode,
                                           vmscms.fn_dmaps_main(a.cci_seg13_postal_code) mailing_postalcode,
                                           (SELECT substr(upper(gcm_cntry_name),
                                                          1,
                                                          2)
                                              FROM vmscms.gen_cntry_mast cs
                                             WHERE cs.gcm_inst_code = cci_inst_code
                                               AND cs.gcm_cntry_code = a.cci_seg13_country_code) mailing_countrycode,
                                           --c.ckm_flag_desc status,
                                           (SELECT c.ckm_flag_desc
                                              FROM vmscms.cms_kycstatus_mast c
                                             WHERE a.cci_kyc_flag = c.ckm_flag) status,
                                           decode(b.ckl_kycres_qualifier_message,
                                                  NULL,
                                                  nvl(b.ckl_kyc_msg,
                                                      'NA'),
                                                  b.ckl_kycres_qualifier_message) kyc_failure_reason,
                                           decode(a.cci_ofac_fail_flag,
                                                  'Y',
                                                  'FAILED',
                                                  'SUCCESS') ofac_status,
                                           b.ckl_kycres_restricted_message ofac_desc,
                                           rank() over(PARTITION BY b.ckl_row_id, b.ckl_inst_code ORDER BY ckl_kycres_date DESC) rn,
                                           a.cci_starter_card_no cci_starter_card_no,
                                           a.cci_kyc_flag,
                                           NULL serial_number,
                                           NULL proxy_number,
                                           vmscms.fn_getmaskpan(vmscms.FN_DMAPS_MAIN(a.cci_pan_code_encr)) cap_mask_pan,
                                           NULL initial_load_amt,
                                           e.cam_inst_code cam_inst_code,
                                           e.cam_acct_id cam_acct_id,
										   case when cpc.cpc_user_identify_type in ('1','4') then 'GIFT' else 'GPR' end cardtype,
										   NVL(cpc.cpc_rout_num,cpc.cpc_institution_id
											   ||'-'
											   ||cpc.cpc_transit_number) routing_number
                                      FROM vmscms.cms_caf_info_entry a,
                                           vmscms.cms_kyctxn_log     b,
                                           vmscms.cms_acct_mast       e,
                                           vmscms.cms_prod_cattype   cpc
                                     WHERE a.cci_inst_code = e.cam_inst_code (+)
                                       AND a.cci_starter_acct_no = e.cam_acct_no (+)
                                       AND a.cci_row_id = b.ckl_row_id
                                       AND a.cci_inst_code = b.ckl_inst_code
                                       AND a.cci_kyc_flag IN ('E',
                                                              'F')
                                       AND a.cci_approved = 'A'
                                       AND a.cci_upld_stat = 'P'
                                       AND a.cci_override_flag <> 2
                                       AND a.cci_ins_date BETWEEN  sysdate-90 and sysdate
                                       AND a.cci_inst_code = cpc.cpc_inst_code
                                       AND a.cci_prod_code = cpc.cpc_prod_code
                                       AND a.cci_card_type = cpc.cpc_card_type
                                       ]';--Added cci_ins_date condition to improve performance

      l_kyc_query := q'[SELECT f.ccm_cust_id customerid,
                               h.accountnumber,
                               h.routing_number,
                               h.firstname,
--                               f.ccm_mid_name middlename,
                               vmscms.fn_dmaps_main(f.ccm_mid_name) middlename,
                               h.lastname,
                               h.mother_maidenname,
                               h.initial_load_amt,
                               h.identity_type,
                               h.identity_number,
                               h.dateofbirth,
                               h.email,
                               h.addr_type1,
                               h.physical_address1,
                               h.physical_address2,
                               h.physical_city,
                               h.physical_state,
                               h.physical_postalcode,
                               h.physical_countrycode,
                               f.ccm_lupd_date physical_lastupdatetimestamp,
                               h.addr_type2,
                               h.mailing_address1,
                               h.mailing_address2,
                               h.mailing_city,
                               h.mailing_state,
                               h.mailing_postalcode,
                               h.mailing_countrycode,
                               f.ccm_lupd_date mailing_lastupdatetimestamp,
--                               f.ccm_user_name onlineuserid,
                               vmscms.fn_dmaps_main(f.ccm_user_name) onlineuserid,
                						   h.cardtype,
                               NULL spendingacct_ledgerbalance,
                               NULL spendingacct_availablebalance,
                               NULL savingacct_ledgerbalance,
                               decode(f.ccm_kyc_source,
                                      '03',
                                      'Desktop',
                                      '06',
                                      'Website',
                                      '04',
                                      'MMPOS',
                                      '08',
                                      'SPIL') regn_source,
                               h.status,
                               h.kyc_failure_reason,
                               h.ofac_status,
                               h.ofac_desc
                          FROM vmscms.cms_cust_acct i,
                               vmscms.cms_cust_mast f,
                               kyctab h
                         WHERE h.cam_inst_code = i.cca_inst_code (+)
                           and h.cam_acct_id = i.cca_acct_id (+)
                           AND i.cca_inst_code = f.ccm_inst_code (+)
                           AND i.cca_cust_code = f.ccm_cust_code(+)
                        ]';

      CASE

      --pan number
        WHEN p_pan_in IS NOT NULL
             AND length(p_pan_in) > 4 THEN

          l_kyc_with_sql := l_kyc_with_sql ||
                            ' AND a.cci_starter_card_no = ''' ||
                            vmscms.gethash(p_pan_in) || '''
                               ) tab
                             WHERE rn = 1 ) ';

      -- Jira CFIP 301 starts
      --SSN SIN full search
        WHEN (p_identity_type_in IN ('SSN',
                                     'SIN') AND
             length(p_identity_id_in) = 9) THEN
          -- CFIP 376
          l_kyc_with_sql := l_kyc_with_sql ||
                            ' AND a.cci_ssn_encr = vmscms.fn_emaps_main(''' ||
                            p_identity_id_in || ''')
                          AND upper(a.cci_document_verify) = ''' ||
                            upper(p_identity_type_in) || '''
                       ) tab
                     WHERE rn = 1 ) ';

      -- DL Pass full search
        WHEN p_identity_type_in NOT IN ('SSN',
                                        'SIN') THEN
          l_kyc_with_sql := l_kyc_with_sql ||
                            ' AND a.cci_id_number_encr = ''' ||
                            vmscms.fn_emaps_main(p_identity_id_in) || '''
                                         AND upper(a.cci_document_verify) = ''' ||
                            upper(p_identity_type_in) || '''
                               ) tab
                             WHERE rn = 1 ) ';

      -- CFIP 301 ends

      --pan last 4

        WHEN p_pan_in IS NOT NULL
             AND length(p_pan_in) = 4
             AND p_lastname_in IS NOT NULL

         THEN

          IF (regexp_instr(p_lastname_in,
                           '[^a-z^A-Z^0-9]') > 0) = TRUE
          THEN
            l_lastname_wild := substr(p_lastname_in,
                                      1,
                                      (regexp_instr(p_lastname_in,
                                                    '[^a-z^A-Z^0-9]')) - 1);
            l_kyc_with_sql  := l_kyc_with_sql ||
                              /*' AND substr(vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(a.cci_pan_code_encr)),
                                                                                                                                                                                                                                                                                                                                                   length(vmsc
ms.fn_getmaskpan(vmscms.FN_DMAPS_MAIN(a.cci_pan_code_encr))) - 3,
                                                                                                                                                                                                                                                                                                                                                   length(vmsc
ms.fn_getmaskpan(vmscms.FN_DMAPS_MAIN(a.cci_pan_code_encr)))) =''' ||*/
                               ' AND substr(vmscms.fn_dmaps_main(CCI_STARTER_CARD_NO_ENCR),-4) =''' ||
                               p_pan_in ||
                               ''' AND upper(a.cci_seg12_name_line2) LIKE''' ||
                               upper(l_lastname_wild || '%') || '''
                               ) tab
                             WHERE rn = 1 ) ';
          ELSE

            l_kyc_with_sql := l_kyc_with_sql ||
                             /*' AND substr(vmscms.fn_getmaskpan(vmscms.FN_DMAPS_MAIN(a.cci_pan_code_encr)),
                                                                                                                                                                                                                                                                                                                                          length(vmscms.fn_get
maskpan(vmscms.FN_DMAPS_MAIN(a.cci_pan_code_encr))) - 3,
                                                                                                                                                                                                                                                                                                                                          length(vmscms.fn_get
maskpan(vmscms.FN_DMAPS_MAIN(a.cci_pan_code_encr)))) =''' ||*/
                              ' AND substr(vmscms.fn_dmaps_main(CCI_STARTER_CARD_NO_ENCR),-4) =''' ||
                              p_pan_in ||
                              ''' AND upper(a.cci_seg12_name_line2) =''' ||
                              upper(p_lastname_in) || '''
                               ) tab
                             WHERE rn = 1 ) ';
          END IF;

      --online user id
        WHEN p_onlineuserid_in IS NOT NULL THEN
          l_kyc_query := l_kyc_query || ' AND f.ccm_user_name = ''' ||
                         p_onlineuserid_in || '''';

          l_kyc_with_sql := l_kyc_with_sql ||
                            ' ) tab
                             WHERE rn = 1 ) ';
          --email
        WHEN p_email_in IS NOT NULL THEN
          l_kyc_with_sql := l_kyc_with_sql ||
                            ' AND a.cci_seg12_emailid =''' || p_email_in || '''
                               ) tab
                             WHERE rn = 1 ) ';

      --address
        WHEN p_address_in IS NOT NULL THEN
          l_kyc_with_sql := l_kyc_with_sql ||
                            ' AND upper(a.cci_seg12_addr_line1 ||
                                           a.cci_seg12_addr_line2) = ''' ||
                            upper(p_address_in) || '''
                               ) tab
                             WHERE rn = 1 ) ';

      --ssn last 4--with wildcard search
        WHEN (p_identity_type_in IN ('SSN',
                                     'SIN') AND
             length(p_identity_id_in) = 4) THEN

          l_lastname := NULL;

          IF (regexp_instr(p_lastname_in,
                           '[^a-z^A-Z^0-9]') > 0)
          THEN
            l_lastname := substr(p_lastname_in,
                                 1,
                                 (regexp_instr(p_lastname_in,
                                               '[^a-z^A-Z^0-9]')) - 1) || '%';
          ELSE
            l_lastname := p_lastname_in;
          END IF;

          /* CFIP 301 Start
           l_where_query := ' AND (substr(decode(identity_number,
                                                 NULL,
                                                 ssn,
                                                 identity_number),
                                          length(decode(identity_number,
                                                        NULL,
                                                        ssn,
                                                        identity_number)) - 3,
                                          length(decode(identity_number,
                                                        NULL,
                                                        ssn,
                                                        identity_number))
                                          )
                                   LIKE(''%'' || :p_identity_id_in || ''%'')
                               AND upper(idtype) = upper(nvl(:p_identity_type_in,
                                                             idtype
                                                            )
                                                         )
                              AND upper(lastname) LIKE
                                        upper(:l_lastname)
                              )
                              ORDER BY ' ||l_order_by;
          */

          l_kyc_with_sql := l_kyc_with_sql || ' AND (a.cci_ssn   LIKE(''' || '%' ||
                            p_identity_id_in ||
                            ''' )
                                 AND upper(a.cci_document_verify) = ''' ||
                            upper(p_identity_type_in) || '''
                                 AND upper(a.cci_seg12_name_line2) LIKE  ''' ||
                            upper(l_lastname) || ''')
                               ) tab
                             WHERE rn = 1 ) ';

        WHEN p_firstname_in IS NOT NULL
             AND p_lastname_in IS NOT NULL THEN

          IF (regexp_instr(p_firstname_in,
                           '[^a-z^A-Z^0-9]') > 0 OR
             regexp_instr(p_lastname_in,
                           '[^a-z^A-Z^0-9]') > 0)
          THEN

            ---substring the character before any special character appears
            l_firstname_wild := NULL;
            l_lastname_wild  := NULL;

            l_firstname_wild := (substr(p_firstname_in,
                                        1,
                                        (regexp_instr(p_firstname_in,
                                                      '[^a-z^A-Z^0-9]')) - 1));
            --
            -- Start JIRA: CFIP-257
            -- 5/18/2016
            -- Wildcard search for KYC was doing a wildcard search even if no wildcard character was passed.
            -- Updated so that the whole name will be considered in the absence of a wildcard.
            IF l_firstname_wild IS NOT NULL
            THEN
              l_firstname_wild := l_firstname_wild || '%';
            ELSE
              l_firstname_wild := p_firstname_in;
            END IF;

            l_lastname_wild := (substr(p_lastname_in,
                                       1,
                                       (regexp_instr(p_lastname_in,
                                                     '[^a-z^A-Z^0-9]')) - 1));

            IF l_lastname_wild IS NOT NULL
            THEN
              l_lastname_wild := l_lastname_wild || '%';
            ELSE
              l_lastname_wild := p_lastname_in;
            END IF;
            l_kyc_with_sql := l_kyc_with_sql ||
                              ' AND upper(a.cci_seg12_name_line1) LIKE''' ||
                              upper(l_firstname_wild) || '''
                                   AND upper(a.cci_seg12_name_line2) LIKE''' ||
                              upper(l_lastname_wild) || '''
                               ) tab
                             WHERE rn = 1 ) ';

          ELSE

            l_kyc_with_sql := l_kyc_with_sql ||
                              ' AND upper(a.cci_seg12_name_line1) =''' ||
                              upper(p_firstname_in) || '''
                               AND upper(a.cci_seg12_name_line2) =''' ||
                              upper(p_lastname_in) || '''
                               ) tab
                             WHERE rn = 1 ) ';

          END IF;

        ELSE
          --KYC all combintion search with wild card search

          --Check for first and last name contains any special charecter--
          /*IF (regexp_instr(p_firstname_in,
                           '[^a-z^A-Z^0-9]') > 0 OR
             regexp_instr(p_lastname_in,
                           '[^a-z^A-Z^0-9]') > 0)
          THEN
          */
          /*IF p_serialnumber_in IS NOT NULL
          THEN
            l_kyc_with_sql := l_kyc_with_sql ||
                              ' AND e.cap_serial_number = ''' ||
                              p_serialnumber_in || '''';
          END IF;

          IF p_proxynumber_in IS NOT NULL
          THEN
            l_kyc_with_sql := l_kyc_with_sql ||
                              ' AND e.cap_proxy_number = ''' ||
                              p_proxynumber_in || '''';
          END IF;
          */
          IF p_pan_in IS NOT NULL
          THEN

            l_kyc_with_sql := l_kyc_with_sql ||
                              ' AND a.cci_starter_card_no = ''' ||
                              vmscms.gethash(p_pan_in) || '''';
          END IF;

          IF p_email_in IS NOT NULL
          THEN
            l_kyc_with_sql := l_kyc_with_sql ||
                              ' AND a.cci_seg12_emailid =''' || p_email_in || '''';
          END IF;

          IF p_address_in IS NOT NULL
          THEN
            l_kyc_with_sql := l_kyc_with_sql ||
                              ' AND upper(a.cci_seg12_addr_line1 ||
                                           a.cci_seg12_addr_line2) = ''' ||
                              upper(p_address_in) || '''';
          END IF;

          IF p_onlineuserid_in IS NOT NULL
          THEN
            l_kyc_query := l_kyc_query || ' AND f.ccm_user_name = ''' ||
                           p_onlineuserid_in || '''';
          END IF;

          IF p_identity_id_in IS NOT NULL
             AND p_identity_type_in IS NOT NULL
          THEN

            l_kyc_with_sql := l_kyc_with_sql ||
                              ' AND (a.cci_id_number LIKE ''' || '%' ||
                              p_identity_id_in || '%' ||
                              ''' OR a.cci_ssn LIKE
                              ''' || '%' ||
                              p_identity_id_in || '%' || ''')
                                 AND a.cci_document_verify = ''' ||
                              p_identity_type_in || '''';
          END IF;

          -- firstname lastname
          IF p_firstname_in IS NOT NULL
          THEN
            l_ctr := regexp_instr(p_firstname_in,
                                  '[^a-z^A-Z^0-9]');

            IF l_ctr > 0
            THEN
              l_kyc_with_sql := l_kyc_with_sql ||
                                ' AND upper(a.cci_seg12_name_line1) like ''' ||
                                substr(upper(p_firstname_in),
                                       1,
                                       (l_ctr - 1)) || '%' || '''';
            ELSE
              l_kyc_with_sql := l_kyc_with_sql ||
                                ' AND upper(a.cci_seg12_name_line1) like ''' ||
                                upper(p_firstname_in) || '''';
            END IF;
          END IF;

          IF p_lastname_in IS NOT NULL
          THEN
            l_ctr := regexp_instr(p_lastname_in,
                                  '[^a-z^A-Z^0-9]');

            IF l_ctr > 0
            THEN
              l_kyc_with_sql := l_kyc_with_sql ||
                                ' AND upper(a.cci_seg12_name_line2) like ''' ||
                                substr(upper(p_lastname_in),
                                       1,
                                       (l_ctr - 1)) || '%' || '''';
            ELSE
              l_kyc_with_sql := l_kyc_with_sql ||
                                ' AND upper(a.cci_seg12_name_line2) like ''' ||
                                upper(p_lastname_in) || '''';
            END IF;
          END IF;

          IF p_dateofbirth_in IS NOT NULL
          THEN
            l_kyc_with_sql := l_kyc_with_sql ||
                              ' AND a.cci_birth_date = to_date(''' ||
                              p_dateofbirth_in || ''',
                                     ''yyyy-mm-dd'')';
          END IF;

          IF p_city_in IS NOT NULL
          THEN
            l_kyc_with_sql := l_kyc_with_sql ||
                              ' AND upper(a.cci_seg12_city) = upper(''' ||
                              p_city_in || ''')';
          END IF;

          IF p_state_in IS NOT NULL
          THEN
            l_kyc_with_sql := l_kyc_with_sql ||
                              ' AND upper(a.cci_seg12_state) = upper(''' ||
                              p_state_in || ''')';
          END IF;

          IF p_postalcode_in IS NOT NULL
          THEN
            l_kyc_with_sql := l_kyc_with_sql ||
                              ' AND upper(a.cci_seg12_postal_code) = upper(''' ||
                              p_postalcode_in || ''')';
          END IF;

          l_kyc_with_sql := l_kyc_with_sql || '
                               ) tab
                             WHERE rn = 1 ) ';
      END CASE;

      l_query := l_kyc_with_sql || l_kyc_query || ' order by ' ||
                 l_order_by;

      dbms_output.put_line(l_query);

      OPEN c_customer_list FOR l_query;
      OPEN c_customers_out FOR l_query;

    ELSE
      --Search type - Non KYC
      g_debug.display('Non KYC');

      l_start_step_time := dbms_utility.get_time;
      g_debug.display('l_start_step_time - gsm_state_code - ' ||
                      l_start_step_time);
      IF p_state_in IS NOT NULL
      THEN

        SELECT gsm_state_code
          INTO l_state
          FROM vmscms.gen_state_mast
         WHERE gsm_inst_code = 1
           AND upper(gsm_switch_state_code) = upper(p_state_in);
      ELSE
        l_state := p_state_in;
      END IF;

      l_end_step_time := dbms_utility.get_time;
      g_debug.display('l_end_step_time - gsm_state_code - ' ||
                      l_end_step_time);

      l_step_timetaken := (l_end_step_time - l_start_step_time) / 100;
      g_debug.display(p_message_in => 'Time taken by gsm_state_code');
      --
      -- JIRA: CFIP-260
      -- 5/18/2016
      -- Add initial load amount, Mother???s Maiden name in search customer response
      l_query := q'[SELECT DISTINCT ccm.ccm_cust_id      customerid,
                              spending.cam_acct_no accountnumber,
                              --cpm.cpm_rout_num routing_number,
                              NVL(cpc.cpc_rout_num,cpc.cpc_institution_id
                                          ||'-'
                                          ||cpc.cpc_transit_number)  routing_number,
--                              ccm.ccm_first_name firstname,
--                              ccm.ccm_mid_name middlename,
--                              ccm.ccm_last_name lastname,
                              vmscms.fn_dmaps_main(ccm.ccm_first_name) firstname,
                              vmscms.fn_dmaps_main(ccm.ccm_mid_name) middlename,
                              vmscms.fn_dmaps_main(ccm.ccm_last_name) lastname,
--                              ccm.ccm_mother_name mother_maidenname,
                              vmscms.fn_dmaps_main(ccm.ccm_mother_name) mother_maidenname,
                              CASE
                                WHEN saving.cam_initialload_amt > 0 THEN
                                 saving.cam_initialload_amt
                                ELSE
                                 spending.cam_initialload_amt
                              END initial_load_amt,
                              cim.cim_idtype_desc identity_type,
                              /* CFIP 301 Start
                              decode(upper(cim.cim_idtype_code),
                                                       'SSN',
                                                       lpad(substr(ccm.ccm_ssn,
                                                                   length(ccm.ccm_ssn) - 3,
                                                                   length(ccm.ccm_ssn)),
                                                            length(ccm.ccm_ssn),
                                                            'X'),
                                                       ccm.ccm_ssn) identity_number,
                              CFIP 301 end */
                              ccm.ccm_ssn identity_number, -- Added for CFIP 301
                              to_char(ccm.ccm_birth_date,
                                      'yyyy-mm-dd') dateofbirth,
--                              physical_addr.cam_email email,
                              vmscms.fn_dmaps_main(physical_addr.cam_email) email,
                              CASE physical_addr.cam_addr_flag
                                WHEN 'P' THEN
                                 'PHYSICAL'
                              END addr_type1,
--                              physical_addr.cam_add_one physical_address1,
--                              physical_addr.cam_add_two physical_address2,
--                              physical_addr.cam_city_name physical_city,           ---- Modified for VMS-5253
                               decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',vmscms.fn_dmaps_main(physical_addr.cam_add_one)) physical_address1,
                               decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',vmscms.fn_dmaps_main(physical_addr.cam_add_two)) physical_address2,
                               decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',vmscms.fn_dmaps_main(physical_addr.cam_city_name)) physical_city,
                              decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',(SELECT upper(gsm_switch_state_code)
                                 FROM vmscms.gen_state_mast
                                WHERE gsm_inst_code = physical_addr.cam_inst_code
                                  AND gsm_state_code = physical_addr.cam_state_code
                                  AND gsm_cntry_code = physical_addr.cam_cntry_code)) physical_state,
--                              physical_addr.cam_pin_code physical_postalcode,
			                    decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',vmscms.fn_dmaps_main(physical_addr.cam_pin_code)) physical_postalcode,
                                decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',(SELECT substr(upper(gcm_cntry_name),
                                             1,
                                             2)
                                 FROM vmscms.gen_cntry_mast
                                WHERE gcm_inst_code = 1
                                  AND gcm_inst_code = physical_addr.cam_inst_code
                                  AND gcm_cntry_code = physical_addr.cam_cntry_code)) physical_countrycode,
                              physical_addr.cam_lupd_date physical_lastupdatetimestamp,
                              CASE mailing_addr.cam_addr_flag
                                WHEN 'O' THEN
                                 'MAILING'
                              END addr_type2,
--                              mailing_addr.cam_add_one mailing_address1,
--                              mailing_addr.cam_add_two mailing_address2,
--                              mailing_addr.cam_city_name mailing_city,
                              decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',vmscms.fn_dmaps_main(mailing_addr.cam_add_one)) mailing_address1,
                              decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',vmscms.fn_dmaps_main(mailing_addr.cam_add_two)) mailing_address2,
                              decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',vmscms.fn_dmaps_main(mailing_addr.cam_city_name)) mailing_city,
                              decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',(SELECT upper(gsm_switch_state_code)
                                 FROM vmscms.gen_state_mast
                                WHERE gsm_inst_code = mailing_addr.cam_inst_code
                                  AND gsm_state_code = mailing_addr.cam_state_code
                                  AND gsm_cntry_code = mailing_addr.cam_cntry_code)) mailing_state,
--                              mailing_addr.cam_pin_code mailing_postalcode,
		                       decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N', vmscms.fn_dmaps_main(mailing_addr.cam_pin_code)) mailing_postalcode,
                              decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',(SELECT substr(upper(gcm_cntry_name),
                                             1,
                                             2)
                                 FROM vmscms.gen_cntry_mast
                                WHERE gcm_inst_code = 1
                                  AND gcm_inst_code = mailing_addr.cam_inst_code
                                  AND gcm_cntry_code = mailing_addr.cam_cntry_code)) mailing_countrycode,
                              mailing_addr.cam_lupd_date mailing_lastupdatetimestamp,
--                              ccm.ccm_user_name onlineuserid,
                              vmscms.fn_dmaps_main(ccm.ccm_user_name) onlineuserid,
                              case when cpc.cpc_user_identify_type in ('1','4') then 'GIFT' else 'GPR' end cardtype,
                              to_char(nvl(spending.cam_ledger_bal,
                                          0),
                                      '9,999,999,990.99') spendingacct_ledgerbalance,
                              to_char(nvl(spending.cam_acct_bal,
                                          0),
                                      '9,999,999,990.99') spendingacct_availablebalance,
                              to_char(nvl(saving.cam_acct_bal,
                                          0),
                                      '9,999,999,990.99') savingacct_ledgerbalance,
                              NULL regn_source,
                              NULL status,
                              NULL kyc_failure_reason,
                              NULL ofac_status,
                              NULL ofac_desc
                      FROM ]';

      -- common 'From' clause
      l_common_from := q'[vmscms.cms_cust_mast ccm,
                             (select cam_email,
                                     cam_addr_flag,
                                     cam_add_one,
                                     cam_add_two,
                                     cam_city_name,
                                     cam_inst_code,
                                     cam_state_code,
                                     cam_cntry_code,
                                     cam_pin_code,
                                     cam_lupd_date,
                                     cam_cust_code
                                from vmscms.cms_addr_mast
                                        where cam_addr_flag = 'P') PHYSICAL_ADDR,
                             (select cam_email,
                                     cam_addr_flag,
                                     cam_add_one,
                                     cam_add_two,
                                     cam_city_name,
                                     cam_inst_code,
                                     cam_state_code,
                                     cam_cntry_code,
                                     cam_pin_code,
                                     cam_lupd_date,
                                     cam_cust_code
                                from  vmscms.cms_addr_mast
                                        where cam_addr_flag = 'O') MAILING_ADDR,
                             vmscms.cms_prod_cattype cpc,
                             vmscms.cms_idtype_mast cim,
                             (SELECT *
                              ---- updated v2.3
                                FROM vmscms.cms_acct_mast, vmscms.cms_cust_acct
                              ---- updated v2.3
                               WHERE cam_type_code = '1'
                                    ---- updated v2.3
                                 AND cca_acct_id = cam_acct_id
                                    ---- updated v2.3
                                 AND cca_inst_code = cam_inst_code
                                    ---- updated v2.3
                                 AND cca_inst_code = 1
                              ---- updated v2.3
                              ) spending,
                             ---- updated v2.3
                             (SELECT *
                              ---- updated v2.3
                                FROM vmscms.cms_acct_mast, vmscms.cms_cust_acct
                              ---- updated v2.3
                               WHERE cam_type_code = '2'
                                    ---- updated v2.3
                                 AND cca_acct_id = cam_acct_id
                                    ---- updated v2.3
                                 AND cca_inst_code = cam_inst_code
                                    ---- updated v2.3
                                 AND cca_inst_code = 1
                              --updated v2.3
                              ) saving ]';

      -- Common 'Where' clause
      l_common_where := q'[
                        WHERE ccm.ccm_inst_code = physical_addr.cam_inst_code -- Added
                             AND ccm.ccm_cust_code = physical_addr.cam_cust_code
                             AND physical_addr.cam_addr_flag = 'P'
                             -- Added
                             AND ccm.ccm_inst_code = mailing_addr.cam_inst_code(+)
                             AND ccm.ccm_cust_code = mailing_addr.cam_cust_code(+)
                             AND mailing_addr.cam_addr_flag(+) = 'O'
                             AND ccm.ccm_inst_code = spending.cca_inst_code
                                ---- updated v2.3
                             AND ccm.ccm_cust_code = spending.cca_cust_code
                                ---- updated v2.3
                             AND ccm.ccm_inst_code = saving.cca_inst_code(+)
                                ---- updated v2.3
                             AND ccm.ccm_cust_code = saving.cca_cust_code(+)
                                ---- updated v2.3
                             -- changes for Global Search
                             AND nvl(ccm_prod_code,'~') || nvl(to_char(ccm_card_type),'^') =
                                   vmscms.gpp_utils.get_prod_code_card_type
                                   (
                                   p_partner_id_in => :partner_id,
                                   p_prod_code_in => ccm_prod_code,
                                   p_card_type_in => ccm_card_type
                                   )
                             AND ccm.ccm_inst_code  = cim.cim_inst_code(+)
                             AND ccm.ccm_id_type    = cim.cim_idtype_code(+)
                             AND ccm.ccm_inst_code = cim.cim_inst_code(+)
                             AND ccm.ccm_id_type = cim.cim_idtype_code(+)
                             AND ccm.ccm_inst_code = cpc.cpc_inst_code
                             AND ccm.ccm_prod_code = cpc.cpc_prod_code
                             AND ccm.ccm_card_type = cpc.cpc_card_type]';

      l_start_step_time := dbms_utility.get_time;
      g_debug.display('Start of the case statement ' || l_start_step_time);
      CASE
      --account number
        WHEN p_accountnumber_in IS NOT NULL THEN

          g_debug.display('case accountnumber');

          -- Add specific condition to the where query
          l_where_query := l_common_where ||
                           ' AND spending.cam_acct_no = :p_accountnumber_in order by ' ||
                           l_order_by;
          l_query       := l_query || l_common_from || l_where_query;
          OPEN c_customer_list FOR l_query
            USING l_partner_id, p_accountnumber_in;
          OPEN c_customers_out FOR l_query
            USING l_partner_id, p_accountnumber_in;

      --serial number
        WHEN p_serialnumber_in IS NOT NULL THEN
          g_debug.display('case serialnumber');

          BEGIN
              SELECT cap_panmast_param2
                INTO l_parent_serialno
                FROM vmscms.cms_appl_pan
               WHERE cap_serial_number = p_serialnumber_in
                 AND cap_panmast_param2 IS NOT NULL;
             EXCEPTION
                  WHEN OTHERS THEN
                      l_parent_serialno := NULL;
          END;

          l_where_query := l_common_where ||
                           q'[ AND EXISTS (SELECT 1
                                                  FROM vmscms.cms_appl_pan cap
                                                 WHERE cap.cap_inst_code = ccm.ccm_inst_code
                                                   AND cap.cap_cust_code = ccm.ccm_cust_code
                                                   AND ( cap.cap_serial_number = :p_serialnumber_in
                                                   OR cap_panmast_param2 in (:l_parent_serialno, :p_serialnumber_in)))
                                    ORDER BY ]' ||
                           l_order_by;
          l_query       := l_query || l_common_from || l_where_query;

          g_debug.display(l_query);
          OPEN c_customer_list FOR l_query
            USING l_partner_id, p_serialnumber_in,l_parent_serialno, p_serialnumber_in;
          OPEN c_customers_out FOR l_query
            USING l_partner_id, p_serialnumber_in,l_parent_serialno, p_serialnumber_in;



      --proxy number
        WHEN p_proxynumber_in IS NOT NULL THEN

          g_debug.display('case proxynumber');

          l_where_query := l_common_where ||
                           q'[ AND EXISTS (SELECT 1
                                                  FROM vmscms.cms_appl_pan cap
                                                 WHERE cap.cap_inst_code = ccm.ccm_inst_code
                                                   AND cap.cap_cust_code = ccm.ccm_cust_code
                                                   AND cap.cap_proxy_number = :p_proxynumber_in)
                                    ORDER BY ]' ||
                           l_order_by;
          l_query       := l_query || l_common_from || l_where_query;

          OPEN c_customer_list FOR l_query
            USING l_partner_id, p_proxynumber_in;
          OPEN c_customers_out FOR l_query
            USING l_partner_id, p_proxynumber_in;

      --pan number
        WHEN p_pan_in IS NOT NULL
             AND length(p_pan_in) > 4 THEN

          g_debug.display('case pan > 4 digits');

          l_where_query := l_common_where ||
                           q'[ AND EXISTS (SELECT 1
                                                  FROM vmscms.cms_appl_pan cap
                                                 WHERE cap.cap_inst_code = ccm.ccm_inst_code
                                                   AND cap.cap_cust_code = ccm.ccm_cust_code
                                                   AND cap.cap_pan_code = vmscms.gethash(:p_pan_in) )
                                    ORDER BY ]' ||
                           l_order_by;
          l_query       := l_query || l_common_from || l_where_query;

          OPEN c_customer_list FOR l_query
            USING l_partner_id, p_pan_in;
          OPEN c_customers_out FOR l_query
            USING l_partner_id, p_pan_in;

      --pan last 4
        WHEN p_pan_in IS NOT NULL
             AND length(p_pan_in) = 4
             AND p_lastname_in IS NOT NULL THEN

          g_debug.display('case pan - 4 digits');

          l_where_query := l_common_where ||
                           q'[ AND EXISTS (SELECT 1
                                             FROM vmscms.cms_appl_pan cap
                                            WHERE cap.cap_inst_code = ccm.ccm_inst_code
                                              AND cap.cap_cust_code = ccm.ccm_cust_code
                                              AND substr(vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap.cap_pan_code_encr)),length(vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap.cap_pan_code_encr))) - 3,
                                                          length(vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap.cap_pan_code_encr)))) =
                                                   :p_pan_in)
                                            ]';

          l_ctr := 0;
          l_ctr := regexp_instr(p_lastname_in,
                                '[^a-z^A-Z^0-9]');
          IF l_ctr > 0
          THEN
            l_lastname_wild := substr(p_lastname_in,
                                      1,
                                      l_ctr - 1) || '%';

            l_where_query := l_where_query ||
                             ' AND UPPER(ccm.ccm_last_name) LIKE
                                       UPPER(''' ||
                             l_lastname_wild || ''') ';
          ELSE
            -- no special character in last name parameter

            l_where_query := l_where_query ||
                             ' AND upper(ccm.ccm_last_name) =
                                   upper(''' ||
                             p_lastname_in || ''') ';
          END IF;

          l_where_query := l_where_query || ' order by ' || l_order_by;

          l_query := l_query || l_common_from || l_where_query;

          g_debug.display(l_query);

          OPEN c_customer_list FOR l_query
            USING l_partner_id, p_pan_in;
          OPEN c_customers_out FOR l_query
            USING l_partner_id, p_pan_in;

      --online user id
        WHEN p_onlineuserid_in IS NOT NULL THEN
          g_debug.display(' case onlineuserid');
          l_where_query := l_common_where ||
                           '  AND ccm.ccm_user_name = :p_onlineuserid_in order by ' ||
                           l_order_by;
          l_query       := l_query || l_common_from || l_where_query;

          dbms_output.put_line('user : ' || l_query);
          OPEN c_customer_list FOR l_query
            USING l_partner_id, p_onlineuserid_in;
          OPEN c_customers_out FOR l_query
            USING l_partner_id, p_onlineuserid_in;

      --email
        WHEN p_email_in IS NOT NULL THEN
          g_debug.display('case email');

          l_where_query := l_common_where ||                                          
                           -- Added UPPER() to use the fn based index on email
                           '  AND UPPER(physical_addr.cam_email) = UPPER(:p_email_in) order by ' ||
                           l_order_by;
          l_query       := l_query || l_common_from || l_where_query;

          OPEN c_customer_list FOR l_query
            USING l_partner_id, p_email_in;
          OPEN c_customers_out FOR l_query
            USING l_partner_id, p_email_in;

      --address
        WHEN p_address_in IS NOT NULL THEN
          g_debug.display('case address');
          -- CFIP 376
          --Performance improvement for Address search (seperate routine to handle address search)
          search_address(upper(p_address_in),
                         l_order_by,
                         p_status_out,
                         p_err_msg_out,
                         c_customers_out,
                         c_customer_list);

      --pan last 4 and ssn last 4--with wildcard search
        WHEN (p_identity_type_in IN ('SSN',
                                     'SIN',
                                     'DL',
                                     'PASS')) THEN
          IF length(p_identity_id_in) = 4
          THEN

            g_debug.display('case identity_code ');
            l_ctr := regexp_instr(p_lastname_in,
                                  '[^a-z^A-Z^0-9]');
            IF l_ctr > 0
            THEN
              ---substring the character before any special character appears
              l_lastname_wild := NULL;

              l_lastname_wild := substr(p_lastname_in,
                                        1,
                                        l_ctr - 1);

              -- Removed NVL check from parameters p_identity_type_in and l_lastname_wild
              -- along with the related columns
              -- Also removed all the other unnecessary checks to improve performance
              l_where_query := l_common_where ||
                               '   AND (substr(ccm_ssn,-4) LIKE(:p_identity_id_in)
                                       AND  upper(cim.cim_idtype_code) =
                                            upper(:p_identity_type_in)
                                       AND upper(ccm_last_name) LIKE
                                                (upper(:l_lastname_wild) || ''%''))
                                            order by ' ||
                               l_order_by;

              l_query := l_query || l_common_from || l_where_query;

              OPEN c_customer_list FOR l_query
                USING l_partner_id, p_identity_id_in, p_identity_type_in, l_lastname_wild;

              OPEN c_customers_out FOR l_query
                USING l_partner_id, p_identity_id_in, p_identity_type_in, l_lastname_wild;
            ELSE
              -- Removed NVL check from parameters p_identity_type_in and l_lastname
              -- along with the related columns
              -- Also removed all the other unnecessary checks to improve performance
              g_debug.display('case identity_code -- complete last name');
              l_where_query := l_common_where ||
                               '  AND (substr(ccm_ssn,-4) LIKE(:p_identity_id_in)
                                       AND  upper(cim.cim_idtype_code) =
                                            upper(:p_identity_type_in)
                                       AND upper(ccm_last_name) =
                                                (upper(:p_lastname_in)))
                                             order by ' ||
                               l_order_by;

              l_query := l_query || l_common_from || l_where_query;

              OPEN c_customer_list FOR l_query
                USING l_partner_id, p_identity_id_in, p_identity_type_in, p_lastname_in;

              OPEN c_customers_out FOR l_query
                USING l_partner_id, p_identity_id_in, p_identity_type_in, p_lastname_in;

            END IF;
            -- Adding code for complete SSN input
          ELSE

            g_debug.display('here....');
            -- length(p_identity_id_in) > 4
            l_where_query := l_common_where ||
                            -- ') AND ccm_ssn LIKE(:p_identity_id_in) commented to use ccm_ssn_encr for full search CFIP 301
                             '  AND ccm.ccm_ssn_encr = vmscms.fn_emaps_main(:p_identity_id_in)  -- CFIP-301
                                       AND  upper(cim.cim_idtype_code) = upper(:p_identity_type_in)
                                            order by ' ||
                             l_order_by;

            l_query := l_query || l_common_from || l_where_query;

            --Testing
            dbms_output.put_line(l_query);

            OPEN c_customer_list FOR l_query
              USING l_partner_id, p_identity_id_in, p_identity_type_in;

            OPEN c_customers_out FOR l_query
              USING l_partner_id, p_identity_id_in, p_identity_type_in;

          END IF;

        WHEN p_firstname_in IS NOT NULL
             AND p_lastname_in IS NOT NULL THEN
          g_debug.display('firstname, lastname');

          l_ctr := regexp_instr(p_firstname_in,
                                '[^a-z^A-Z^0-9]');
          IF l_ctr > 0
          THEN
            l_where_query := l_common_where ||
                             '  AND UPPER(ccm.ccm_first_name) like
                                       upper(''' ||
                             substr(p_firstname_in,
                                    1,
                                    (l_ctr - 1)) || ''')||''%''';
          ELSE
            l_where_query := l_common_where ||
                             '  AND UPPER(ccm.ccm_first_name) like
                                       upper(''' ||
                             p_firstname_in || ''')';
          END IF;
          l_ctr := regexp_instr(p_lastname_in,
                                '[^a-z^A-Z^0-9]');
          IF l_ctr > 0
          THEN
            l_where_query := l_where_query ||
                             ' AND UPPER(ccm.ccm_last_name) like
                                       upper(''' ||
                             substr(p_lastname_in,
                                    1,
                                    (l_ctr - 1)) || ''')||''%''';
          ELSE
            l_where_query := l_where_query ||
                             ' AND UPPER(ccm.ccm_last_name) like
                                       upper(''' ||
                             p_lastname_in || ''')';
          END IF;
          l_where_query := l_where_query || ' order by ' || l_order_by;
          l_query       := l_query || l_common_from || l_where_query;

          g_debug.display(l_query);
          OPEN c_customer_list FOR l_query
            USING l_partner_id;

          OPEN c_customers_out FOR l_query
            USING l_partner_id;
          --dbms_output.put_line('**TEST** ' || l_partner_id);

      --serial number
        WHEN p_card_id_in IS NOT NULL THEN
          g_debug.display('case cardID');

          l_card_id := substr(p_card_id_in,-12);

          l_where_query := l_common_where ||
                           q'[ AND EXISTS (SELECT 1
                                                  FROM vmscms.cms_appl_pan cap
                                                 WHERE cap.cap_inst_code = ccm.ccm_inst_code
                                                   AND cap.cap_cust_code = ccm.ccm_cust_code
                                                   AND cap.cap_card_id = :l_card_id)
                                    ORDER BY ]' ||
                           l_order_by;

          l_query := l_query || l_common_from || l_where_query;

          g_debug.display(' ' || l_query);
          OPEN c_customer_list FOR l_query
            USING l_partner_id, l_card_id;
          OPEN c_customers_out FOR l_query
            USING l_partner_id, l_card_id;

        WHEN p_transaction_id_in IS NOT NULL THEN
          -- If the date parameters are null,
          -- the date range will default to the complete current year.

          IF p_from_date_in IS NULL
          THEN
            l_from_date := to_date('1-1-' || to_char(SYSDATE,
                                                     'YYYY')||' 00:00:00',
                                   'MM-DD-YYYY HH24:MI:SS');
          ELSE
            l_from_date := to_date(p_from_date_in||' 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
          END IF;

          IF p_to_date_in IS NULL
          THEN
            l_to_date := to_date('12-31-' || to_char(SYSDATE,
                                                       'YYYY')||' 23:59:59',
                                   'MM-DD-YYYY HH24:MI:SS');
          ELSE
            l_to_date := to_date(p_to_date_in||' 23:59:59', 'YYYY-MM-DD HH24:MI:SS');
          END IF;

          l_where_query := l_common_where ||
                           ' AND EXISTS
                                  (SELECT 1
                                     FROM vmscms.transactionlog x,
                                          vmscms.cms_acct_mast cam,
                                          vmscms.cms_cust_acct cca
                                    WHERE cca.cca_inst_code = cam.cam_inst_code
                                       AND cca.cca_acct_id = cam.cam_acct_id
                                       AND cca.cca_cust_code = ccm.ccm_cust_code
                                       AND x.customer_acct_no = cam.cam_acct_no
                                       and x.instcode=cam.cam_inst_code
                                       AND x.rrn = :p_transaction_id_in
                                       AND x.add_ins_date BETWEEN :l_from_date AND :l_to_date)
                                     order by ' ||
                           l_order_by;
          l_query       := l_query || l_common_from || l_where_query;

          dbms_output.put_line('transaction id,l_from_date, l_to_date : ' ||
                                p_transaction_id_in||','||l_from_date||','||l_to_date);

          g_debug.display(l_query);

          OPEN c_customer_list FOR l_query
            USING l_partner_id, p_transaction_id_in, l_from_date, l_to_date;
          OPEN c_customers_out FOR l_query
            USING l_partner_id, p_transaction_id_in, l_from_date, l_to_date;

      --with all the combination
        ELSE
          g_debug.display('Default case');
          l_end_step_time := dbms_utility.get_time;
          g_debug.display('l_end_step_time - default case - ' ||
                          l_end_step_time);
          l_step_timetaken := (l_end_step_time - l_start_step_time) / 100;
          g_debug.display(p_message_in => 'Time taken to come to default case - ' ||
                                          l_step_timetaken);

          l_start_step_time := dbms_utility.get_time;
          g_debug.display('l_start_step_time - default - regexp check - ' ||
                          l_end_step_time);

          l_where_query := l_common_where;

          IF p_serialnumber_in IS NOT NULL
          THEN

           BEGIN
                      SELECT cap_panmast_param2
                        INTO l_parent_serialno
                        FROM vmscms.cms_appl_pan
                       WHERE cap_serial_number = p_serialnumber_in
                         AND cap_panmast_param2 IS NOT NULL;
                     EXCEPTION
                          WHEN OTHERS THEN
                              l_parent_serialno := NULL;
              END;

            l_where_query := l_where_query ||
                             ' AND EXISTS (SELECT 1
                                              FROM vmscms.cms_appl_pan cap
                                             WHERE cap.cap_inst_code = ccm.ccm_inst_code
                                               AND cap.cap_cust_code = ccm.ccm_cust_code
                                               AND cap.cap_serial_number = ''' ||
                             p_serialnumber_in || ''' OR cap_panmast_param2 IN ( ''' || l_parent_serialno|| ''',''' ||
                             p_serialnumber_in ||'''))';


          END IF;

          IF p_proxynumber_in IS NOT NULL
          THEN
            l_where_query := l_where_query ||
                             ' AND EXISTS (SELECT 1
                                              FROM vmscms.cms_appl_pan cap
                                             WHERE cap.cap_inst_code = ccm.ccm_inst_code
                                               AND cap.cap_cust_code = ccm.ccm_cust_code
                                               AND cap.cap_proxy_number = '' ' ||
                             p_proxynumber_in || ' '') ';
          END IF;

          IF p_pan_in IS NOT NULL
          THEN
            l_where_query := l_where_query ||
                             ' AND EXISTS (SELECT 1
                                              FROM vmscms.cms_appl_pan cap
                                             WHERE cap.cap_inst_code = ccm.ccm_inst_code
                                               AND cap.cap_cust_code = ccm.ccm_cust_code
                              and cap.cap_pan_code = vmscms.gethash(''' ||
                             p_pan_in || ''') )';
          END IF;

         -- l_where_query := l_where_query || ' ) '; -- end of bracket for cms_appl_pan exists

          IF p_accountnumber_in IS NOT NULL
          THEN
            l_where_query := l_where_query ||
                             ' and spending.cam_acct_no = ''' ||
                             p_accountnumber_in || '''';
          END IF;

          IF p_email_in IS NOT NULL
          THEN
            l_where_query := l_where_query ||
                             ' and UPPER(physical_addr.cam_email) = ''' ||
                             upper(p_email_in) || ''' ';
          END IF;

          IF p_address_in IS NOT NULL
          THEN
            l_where_query := l_where_query ||
                             ' and upper(physical_addr.cam_add_one || physical_addr.cam_add_two) = upper(''' ||
                             p_address_in || ''')';
          END IF;

          IF p_onlineuserid_in IS NOT NULL
          THEN
            l_where_query := l_where_query ||
                             ' AND upper(ccm_user_name) = ''' ||
                             p_onlineuserid_in || ''' ';
          END IF;

          IF p_identity_type_in IS NOT NULL
             AND p_identity_id_in IS NOT NULL
          THEN
            l_where_query := l_where_query ||
                             ' AND (substr(ccm_ssn,length(ccm_ssn) - 3,
                                    length(ccm_ssn)) LIKE(''' || '%' ||
                             p_identity_id_in || '%' || ''')
                                   AND  upper(cim.cim_idtype_code) =
                                        upper(''' ||
                             p_identity_type_in || ''')) ';
          END IF;

          IF p_firstname_in IS NOT NULL
          THEN
            l_ctr := regexp_instr(p_firstname_in,
                                  '[^a-z^A-Z^0-9]');
            IF l_ctr > 0
            THEN
              l_where_query := l_where_query || '
                                    AND UPPER(ccm.ccm_first_name) like
                                             upper(''' ||
                               substr(p_firstname_in,
                                      1,
                                      (l_ctr - 1)) || ''')||''%''';
            ELSE
              l_where_query := l_where_query || '
                             AND UPPER(ccm.ccm_first_name) like
                                       upper(''' ||
                               p_firstname_in || ''')';
            END IF;
          END IF;
          IF p_lastname_in IS NOT NULL
          THEN
            l_ctr := regexp_instr(p_lastname_in,
                                  '[^a-z^A-Z^0-9]');
            IF l_ctr > 0
            THEN
              l_where_query := l_where_query || '
                                    AND UPPER(ccm.ccm_last_name) like
                                             upper(''' ||
                               substr(p_lastname_in,
                                      1,
                                      (l_ctr - 1)) || ''')||''%''';
            ELSE
              l_where_query := l_where_query || '
                             AND UPPER(ccm.ccm_last_name) like
                                       upper(''' ||
                               p_lastname_in || ''')';
            END IF;
          END IF;

          IF p_dateofbirth_in IS NOT NULL
          THEN

            l_where_query := l_where_query || '
                             AND ccm.ccm_birth_date = to_date(''' ||
                             p_dateofbirth_in || ''',''YYYY-MM-DD'') ';
          END IF;
          IF p_city_in IS NOT NULL
          THEN
            l_where_query := l_where_query ||
                             ' AND upper(physical_addr.cam_city_name) = upper(''' ||
                             p_city_in || ''')';
          END IF;

          IF l_state IS NOT NULL
          THEN
            l_where_query := l_where_query ||
                             ' AND upper(physical_addr.cam_state_code) = upper(''' ||
                             l_state || ''')';
          END IF;

          IF p_postalcode_in IS NOT NULL
          THEN
            l_where_query := l_where_query ||
                             ' AND physical_addr.cam_pin_code = ''' ||
                             p_postalcode_in || ''' ';
          END IF;

          l_query := l_query || l_common_from || l_where_query ||
                     ' ORDER BY ' || l_order_by;

          OPEN c_customer_list FOR l_query
            USING l_partner_id;

          OPEN c_customers_out FOR l_query
            USING l_partner_id;

          g_debug.display('main query');
          g_debug.display('l_query - ' || l_query);

          l_end_step_time := dbms_utility.get_time;
          g_debug.display('l_end_step_time - build where clause - ' ||
                          l_end_step_time);
          l_step_timetaken := (l_end_step_time - l_start_step_time) / 100;
          g_debug.display(p_message_in => 'Time taken build where clause - ' ||
                                          l_step_timetaken);

          l_start_step_time := dbms_utility.get_time;
          g_debug.display('l_start_step_time - Open cursor - ' ||
                          l_end_step_time);

          l_end_step_time := dbms_utility.get_time;
          g_debug.display('l_end_step_time - Open cursor - ' ||
                          l_end_step_time);
          l_step_timetaken := (l_end_step_time - l_start_step_time) / 100;
          g_debug.display(p_message_in => 'Time taken open cursor - ' ||
                                          l_step_timetaken);

      END CASE;
      
      VMSCMS.ZBDDD_DELETE_CHECK (
    P_SERIALNUMBER_IN,
    L_PARENT_SERIALNO,
    P_PROXYNUMBER_IN,
    P_PAN_IN,
    P_ONLINEUSERID_IN,
    P_ACCOUNTNUMBER_IN,
    P_FIRSTNAME_IN,
    P_LASTNAME_IN,
    P_IDENTITY_ID_IN,
    P_IDENTITY_TYPE_IN,
    P_ADDRESS_IN,
    P_EMAIL_IN,
    V_DELETE_DATE,
    P_ERR_MSG_OUT );

         IF V_DELETE_DATE IS NOT NULL THEN

        OPEN C_CUSTOMERS_OUT FOR
	   SELECT 'Account deleted on ' || TO_CHAR(V_DELETE_DATE,'MM/DD/YYYY') || ' due to inactivity. Card has zero balance at time of deletion.' accountDeletionDescription
        FROM DUAL;

         vmscms.gpp_transaction.audit_transaction_log(g_api_name,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL, --Remarks
                                                   l_timetaken);

p_status_out := vmscms.gpp_const.c_success_status;

      RETURN;
         END IF;
      
      
    END IF;
    --To retrieve cards array
    l_start_step_time := dbms_utility.get_time;
    g_debug.display('l_start_step_time - retrieve cards array - ' ||
                    l_end_step_time);
    get_cards_array(c_customer_list,
                    c_cards_out,
                    p_status_out,
                    p_err_msg_out);

    l_end_step_time := dbms_utility.get_time;
    g_debug.display('l_end_step_time - retrieve cards array - ' ||
                    l_end_step_time);
    l_step_timetaken := (l_end_step_time - l_start_step_time) / 100;
    g_debug.display(p_message_in => 'Time taken retrieve cards array - ' ||
                                    l_step_timetaken);
    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out := vmscms.gpp_const.c_success_status;

    l_start_step_time := dbms_utility.get_time;
    g_debug.display('l_start_step_time - audit txn log - ' ||
                    l_end_step_time);

    /*vmscms.gpp_transaction.audit_transaction_log(g_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 'C',
                                                 p_err_msg_out,
                                                 vmscms.gpp_const.c_success_res_id,
                                                 NULL,
                                                 l_timetaken);*/

    l_end_step_time := dbms_utility.get_time;
    g_debug.display('l_end_step_time - audit txn log - ' ||
                    l_end_step_time);
    l_step_timetaken := (l_end_step_time - l_start_step_time) / 100;
    g_debug.display(p_message_in => 'Time taken audit txn log - ' ||
                                    l_step_timetaken);
  EXCEPTION
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(g_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(g_api_name,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(g_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(g_api_name,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
  END get_customers;

  -- the init procedure is private and should ALWAYS exist

  PROCEDURE init IS
  BEGIN
    -- initialize all errors here
    g_err_nodata    := fsfw.fserror_t('E-NO-DATA',
                                      '$1 $2');
    g_err_mandatory := fsfw.fserror_t('E-MANDATORY',
                                      'Mandatory Field is NULL: $1 $2 $3',
                                      'NOTIFY');

    g_err_unknown      := fsfw.fserror_t('E-UNKNOWN',
                                         'Unknown error: $1 $2',
                                         'NOTIFY');
    g_err_invalid_data := fsfw.fserror_t('E-INVALID_DATA',
                                         '$1 $2 $3');
    -- load configuration elements
    g_config := fsfw.fsconfig.get_configuration($$PLSQL_UNIT);
    IF g_config.exists(fsfw.fsconst.c_debug)
    THEN
      g_debug := fsfw.fsdebug_t($$PLSQL_UNIT,
                                g_config(fsfw.fsconst.c_debug));
    ELSE
      g_debug := fsfw.fsdebug_t($$PLSQL_UNIT,
                                '');
    END IF;
  END init;

  -- the get_cpp_context function returns the value of the specific
  -- context value set in the application context for the GPP application

  FUNCTION get_gpp_context(p_name_in IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                       p_name_in));
  END get_gpp_context;

BEGIN
  -- Initialization
  init;
END gpp_customers;
/
show error