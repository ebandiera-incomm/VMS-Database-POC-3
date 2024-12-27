CREATE OR REPLACE PACKAGE BODY "VMSCMS"."GPP_IDENTIFICATION" AS

-- global variables for the FS framework
  g_config fsfw.fstype.parms_typ;
  g_debug  fsfw.fsdebug_t;

  --declare all FS errors here
  g_err_nodata       fsfw.fserror_t;
  g_err_failure      fsfw.fserror_t;
  g_err_unknown      fsfw.fserror_t;
  g_err_mandatory    fsfw.fserror_t;
  g_err_invalid_data fsfw.fserror_t;

PROCEDURE update_identification_info(
                           p_customer_id_in         IN VARCHAR2,
                           p_action_in              IN VARCHAR2,
                           --identification
                           p_id_type_in             IN VARCHAR2,
                           p_number_in              IN VARCHAR2,
                           p_issuedby_in            IN VARCHAR2,
                           p_issuance_date_in       IN VARCHAR2,
                           p_expiration_date_in     IN VARCHAR2,
                           p_province_in            IN VARCHAR2,
                           p_countryin              IN VARCHAR2,
                           p_verification_date_in   IN VARCHAR2,
                           --occupation
                           p_occupation_type_in     IN VARCHAR2,
                           p_occupation_in          IN VARCHAR2,
                           --tax info
                           p_istax_res_can_in       IN VARCHAR2,
                           p_taxpin_in              IN VARCHAR2,
                           p_no_tax_reason_id_in    IN VARCHAR2,
                           p_no_tax_reason_desc_in  IN VARCHAR2,
                           p_tax_juris_resident_in  IN VARCHAR2,
                           -- third party info
                           p_isthird_party_benft_in IN VARCHAR2,
                           p_third_party_type_in    IN VARCHAR2,
                           p_firstname_in           IN VARCHAR2,
                           p_lastname_in            IN VARCHAR2,
                           p_corporationaname_in    IN VARCHAR2,
                           p_dob_in                 IN VARCHAR2,
                           p_addrone_in             IN VARCHAR2,
                           p_addrtwo_in             IN VARCHAR2,
                           p_city_in                IN VARCHAR2,
                           p_state_in               IN VARCHAR2,
                           p_postalcode_in          IN VARCHAR2,
                           p_countrycode_in         IN VARCHAR2,
                           p_occupation_code_in     IN VARCHAR2,
                           p_occupation_desc_in     IN VARCHAR2,
                           p_in_corporation_no_in   IN VARCHAR2,
                           p_nature_of_relation_in  IN VARCHAR2,
                           p_nature_of_business_in  IN VARCHAR2,
                           --common
                           p_status_out             OUT VARCHAR2 ,
                           p_err_msg_out            OUT VARCHAR2) AS
/***************************************************************************************
         * Modified By        : Ubaidur Rahman H
         * Modified Date      : 26-Jun-2019
         * Modified Reason    : VMS-1008 - Modified to select currency code from product category instead of Prod Mast.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 26-Jun-2019
         * Build Number       : R17_B0005
 ***************************************************************************************/                          
			   
    l_date           VARCHAR2(50);
    l_time           VARCHAR2(50);
    l_api_name       VARCHAR2(50) := 'UPDATE IDENTIFICATION INFO';
    l_field_name     VARCHAR2(50);
    l_flag           PLS_INTEGER := 0;
    l_hash_pan       vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan       vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_acct_no        vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_plain_pan      VARCHAR2(20);
    l_curr_code      VARCHAR2(20);
    l_rrn            vmscms.transactionlog.rrn%TYPE;
    l_start_time     NUMBER;
    l_end_time       NUMBER;
    l_timetaken      NUMBER;
    l_cnt            NUMBER;
	  l_occ_count      NUMBER;
    l_cust_code    vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code    vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type    vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no     vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_cardstat     vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan   vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code vmscms.cms_appl_pan.cap_prfl_code%TYPE;
    l_call_seq     vmscms.cms_calllog_details.ccd_call_seq%TYPE;
    l_curr_id_type vmscms.cms_cust_mast.ccm_id_type%TYPE;
    l_txn_code     vmscms.transactionlog.txn_code%TYPE;

  BEGIN
    l_start_time := dbms_utility.get_time;

    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_cust_code,
                                   l_prod_code,
                                   l_card_type,
                                   l_proxy_no,
                                   l_cardstat,
                                   l_acct_no,
                                   l_masked_pan,
                                   l_profile_code);

    l_plain_pan := vmscms.fn_dmaps_main(l_encr_pan);
    g_debug.display('l_encr_pan' || l_encr_pan);
    g_debug.display('l_plain_pan' || l_plain_pan);
    g_debug.display('l_acct_no' || l_acct_no);

    --fetching the rrn
    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;
    g_debug.display('l_rrn' || l_rrn);

    --getting the date
    l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-date'),
                                  6,
                                  11);
  --  l_date := substr('Fri, 08 mar 2016 08:49:37 GMT', 6, 11);
    l_date := to_char(to_date(l_date,
                              'dd-mm-yyyy'),
                      'yyyymmdd');
    --getting the time
    l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                  'x-incfs-date')),
                                  18,
                                  8);
  --  l_time := '08:49:37';
    l_time := REPLACE(l_time,
                      ':',
                      '');

    g_debug.display('l_date' || l_date);
    g_debug.display('l_time' || l_time);

 /*   SELECT cbp_param_value
      INTO l_curr_code
      FROM vmscms.cms_prod_mast, vmscms.cms_bin_param
     WHERE cpm_inst_code = cbp_inst_code
       AND cpm_profile_code = cbp_profile_code
       AND cpm_prod_code = l_prod_code
       AND cpm_inst_code = 1
       AND cbp_param_name = 'Currency'; */
       
       
     -- Addded for VMS- 1008 
     --- Currency code taken from product category instead of Prod Mast  
      SELECT bin.CBP_PARAM_VALUE
      INTO l_curr_code
      FROM vmscms.CMS_BIN_PARAM bin,
        vmscms.CMS_PROD_CATTYPE prodcat
      WHERE bin.CBP_PROFILE_CODE = prodcat.CPC_PROFILE_CODE
      AND prodcat.CPC_PROD_CODE  = l_prod_code
      AND prodcat.CPC_CARD_TYPE  = l_card_type
      AND bin.CBP_INST_CODE      = 1
      AND prodcat.CPC_INST_CODE  = 1
      AND bin.CBP_PARAM_NAME     = 'Currency';

    IF p_action_in IS NULL THEN
       l_field_name := 'ACTION ID';
       l_flag       := 1;
    END IF;

    IF upper(p_action_in) NOT IN ('UPDATEIDENTIFICATION',
                                  'UPDATEOCCUPATION',
                                  'UPDATETAXINFO',
                                  'UPDATETHIRDPARTYINFO')
       THEN
       p_status_out := vmscms.gpp_const.c_invalid_data_status;
       g_err_invalid_data.raise(l_api_name,
                                ',0029,',
                                'INVALID DATA FOR ACTION');
       p_err_msg_out := g_err_invalid_data.get_current_error;
       vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                    p_customer_id_in,
                                                    l_hash_pan,
                                                    l_encr_pan,
                                                    'F', --vmscms.gpp_const.c_failure_flag,
                                                    p_err_msg_out,
                                                    vmscms.gpp_const.c_failure_res_id,
                                                    NULL,
                                                    l_timetaken); --Remarks
        RETURN;
    END IF;


    IF upper(p_action_in) = 'UPDATEIDENTIFICATION'
    THEN
      CASE
        WHEN p_id_type_in IS NULL THEN
          l_field_name := 'IDENTIFICATION TYPE';
          l_flag       := 1;
        WHEN p_number_in IS NULL THEN
          l_field_name := 'IDENTIFICATION NUMBER';
          l_flag       := 1;
        ELSE
          NULL;
      END CASE;

	 SELECT COUNT(1)
	 INTO l_cnt
	 FROM vmscms.CMS_IDTYPE_MAST
	 WHERE CIM_INST_CODE = 1
	 AND CIM_IDTYPE_CODE = upper(p_id_type_in);

      IF l_cnt = 0
      THEN
        p_status_out := vmscms.gpp_const.c_invalid_data_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0029,',
                                 'INVALID DATA FOR ID TYPE');
        p_err_msg_out := g_err_invalid_data.get_current_error;
        vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                     p_customer_id_in,
                                                     l_hash_pan,
                                                     l_encr_pan,
                                                     'F', --vmscms.gpp_const.c_failure_flag,
                                                     p_err_msg_out,
                                                     vmscms.gpp_const.c_failure_res_id,
                                                     NULL,
                                                     l_timetaken); --Remarks
      RETURN;
    END IF;

      SELECT ccm_id_type
        INTO l_curr_id_type
        FROM cms_cust_mast
       WHERE ccm_cust_code = l_cust_code
         AND ccm_inst_code = 1;

      IF l_curr_id_type <> upper(p_id_type_in)
      THEN
        p_status_out  := vmscms.gpp_const.c_invalid_id_update;
        p_err_msg_out := vmscms.gpp_const.c_invalid_id_update_errmsg;
        g_err_nodata.raise(l_api_name,
                           vmscms.gpp_const.c_invalid_id_update);
        RETURN;
      END IF;

      IF upper(p_id_type_in) NOT IN ('SSN',
                                     'SIN')
         AND (p_issuedby_in IS NULL OR p_issuance_date_in IS NULL OR
              p_expiration_date_in IS NULL)
      THEN
        p_status_out := vmscms.gpp_const.c_invalid_data_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0029,',
                                 'Issued by, Issuance Date and Expiration Date is Mandatory');
        p_err_msg_out := g_err_invalid_data.get_current_error;
        vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                     p_customer_id_in,
                                                     l_hash_pan,
                                                     l_encr_pan,
                                                     'F', --vmscms.gpp_const.c_failure_flag,
                                                     p_err_msg_out,
                                                     vmscms.gpp_const.c_failure_res_id,
                                                     NULL,
                                                     l_timetaken); --Remarks
        RETURN;
      END IF;

    END IF;

    IF length(p_countryin) > 2
      THEN
        p_status_out := vmscms.gpp_const.c_invalid_data_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0029,',
                                 'INVALID COUNTRY');
        p_err_msg_out := g_err_invalid_data.get_current_error;
        vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                     p_customer_id_in,
                                                     l_hash_pan,
                                                     l_encr_pan,
                                                     'F', --vmscms.gpp_const.c_failure_flag,
                                                     p_err_msg_out,
                                                     vmscms.gpp_const.c_failure_res_id,
                                                     NULL,
                                                     l_timetaken); --Remarks
      RETURN;
    END IF;

    IF upper(p_action_in) = 'UPDATEOCCUPATION' THEN
       IF p_occupation_type_in IS NULL AND p_occupation_in IS NULL THEN
          p_status_out := vmscms.gpp_const.c_mandatory_status;
          g_err_mandatory.raise(l_api_name,
                                ',0002,',
                                'Occupation type or Occupation' || ' is mandatory when action is UPDATEOCCUPATION');
          p_err_msg_out := g_err_mandatory.get_current_error;
          vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                        p_customer_id_in,
                                                       l_hash_pan,
                                                       l_encr_pan,
                                                       'F', --vmscms.gpp_const.c_failure_flag,
                                                       p_err_msg_out,
                                                       vmscms.gpp_const.c_failure_res_id,
                                                       NULL,
                                                       l_timetaken);
          RETURN;
       END IF;

       IF p_occupation_type_in = '00' AND p_occupation_in IS NULL THEN
            l_field_name := 'OCCUPATION';
            l_flag       := 1;
       END IF;

       BEGIN
           SELECT count(*)
             INTO l_occ_count
             FROM vmscms.vms_occupation_mast
            WHERE vom_occu_code = p_occupation_type_in;

           IF l_occ_count = 0 THEN
              p_status_out := vmscms.gpp_const.c_invalid_data_status;
              g_err_invalid_data.raise(l_api_name,
                           ',0029,',
                           'INVALID OCCUPATION CODE');
              p_err_msg_out := g_err_invalid_data.get_current_error;
              vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                     p_customer_id_in,
                                     l_hash_pan,
                                     l_encr_pan,
                                     'F', --vmscms.gpp_const.c_failure_flag,
                                     p_err_msg_out,
                                     vmscms.gpp_const.c_failure_res_id,
                                     NULL,
                                     l_timetaken); --Remarks
              RETURN;
           END IF;
       END;
    END IF;



    IF upper(p_action_in) = 'UPDATETAXINFO' THEN
       IF p_istax_res_can_in IS NULL AND p_taxpin_in IS NULL AND
          p_no_tax_reason_id_in  IS NULL AND  p_no_tax_reason_desc_in IS NULL AND
          p_tax_juris_resident_in IS NULL THEN
          p_status_out := vmscms.gpp_const.c_mandatory_status;
          g_err_mandatory.raise(l_api_name,
                                ',0002,',
                                'Any one field should be present when action is UPDATETAXINFO');
          p_err_msg_out := g_err_mandatory.get_current_error;
          vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                        p_customer_id_in,
                                                       l_hash_pan,
                                                       l_encr_pan,
                                                       'F', --vmscms.gpp_const.c_failure_flag,
                                                       p_err_msg_out,
                                                       vmscms.gpp_const.c_failure_res_id,
                                                       NULL,
                                                       l_timetaken);
          RETURN;
       END IF;




       IF upper(p_istax_res_can_in) NOT IN ('TRUE',
                                            'FALSE')
       THEN
          p_status_out := vmscms.gpp_const.c_invalid_data_status;
          g_err_invalid_data.raise(l_api_name,
                                   ',0029,',
                                   'INVALID IS TAX RESIDENT OF CANADA');
          p_err_msg_out := g_err_invalid_data.get_current_error;
          vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                       p_customer_id_in,
                                                       l_hash_pan,
                                                       l_encr_pan,
                                                       'F', --vmscms.gpp_const.c_failure_flag,
                                                       p_err_msg_out,
                                                       vmscms.gpp_const.c_failure_res_id,
                                                       NULL,
                                                       l_timetaken); --Remarks
          RETURN;
       END IF;

       IF upper(p_istax_res_can_in) = 'FALSE'
       THEN
          IF  p_taxpin_in IS  NULL AND p_no_tax_reason_id_in IS NULL
          THEN
              p_status_out := vmscms.gpp_const.c_invalid_data_status;
              g_err_invalid_data.raise(l_api_name,
                                       ',0029,',
                                       'Either TAX ID or NO TAX REASON ID is Mandatory');
              p_err_msg_out := g_err_invalid_data.get_current_error;
              vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                           p_customer_id_in,
                                                           l_hash_pan,
                                                           l_encr_pan,
                                                           'F', --vmscms.gpp_const.c_failure_flag,
                                                           p_err_msg_out,
                                                           vmscms.gpp_const.c_failure_res_id,
                                                           NULL,
                                                           l_timetaken); --Remarks
              RETURN;
          ELSIF p_taxpin_in IS  NULL AND p_no_tax_reason_id_in IS NOT NULL
          THEN
              IF p_no_tax_reason_id_in NOT IN ('1','2','3')
              THEN
                  p_status_out := vmscms.gpp_const.c_invalid_data_status;
                  g_err_invalid_data.raise(l_api_name,
                                           ',0029,',
                                           'INVALID NO TAX REASON ID');
                  p_err_msg_out := g_err_invalid_data.get_current_error;
                  vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                               p_customer_id_in,
                                                               l_hash_pan,
                                                               l_encr_pan,
                                                               'F', --vmscms.gpp_const.c_failure_flag,
                                                               p_err_msg_out,
                                                               vmscms.gpp_const.c_failure_res_id,
                                                               NULL,
                                                               l_timetaken); --Remarks
                  RETURN;
              ELSIF p_no_tax_reason_id_in = '3'
              THEN
                 IF p_no_tax_reason_desc_in IS NULL
                 THEN
                      l_field_name := 'NO TAX REASON DESC';
                      l_flag := 1;
                 END IF;
              END IF;
          END IF;
          IF  p_tax_juris_resident_in IS NULL
          THEN
              l_field_name := 'TAX JURISDICTION RESIDENCE';
              l_flag := 1;
          END IF;
       END IF;
    END IF;

    IF upper(p_action_in) = 'UPDATETHIRDPARTYINFO'
    THEN
      IF p_isthird_party_benft_in IS NULL THEN
           l_field_name := 'Is Third Party Benefit';
           l_flag       := 1;
      END IF;

      IF upper(p_isthird_party_benft_in) NOT IN ('TRUE',
                                                 'FALSE')
      THEN
          p_status_out := vmscms.gpp_const.c_invalid_data_status;
          g_err_invalid_data.raise(l_api_name,
                                   ',0029,',
                                   'INVALID IS THIRD PARTY BENEFIT');
          p_err_msg_out := g_err_invalid_data.get_current_error;
          vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                       p_customer_id_in,
                                                       l_hash_pan,
                                                       l_encr_pan,
                                                       'F', --vmscms.gpp_const.c_failure_flag,
                                                       p_err_msg_out,
                                                       vmscms.gpp_const.c_failure_res_id,
                                                       NULL,
                                                       l_timetaken); --Remarks
          RETURN;
      END IF;

      IF p_isthird_party_benft_in = 'TRUE'
        THEN
          CASE
            WHEN p_third_party_type_in IS NULL THEN
              l_field_name := 'THIRD PARTY TYPE';
              l_flag       := 1;
            WHEN p_addrone_in IS NULL THEN
              l_field_name := 'ADDRESS ONE';
              l_flag       := 1;
            WHEN p_city_in IS NULL THEN
              l_field_name := 'CITY';
              l_flag       := 1;
            WHEN p_state_in IS NULL THEN
              l_field_name := 'STATE';
              l_flag       := 1;
            WHEN p_postalcode_in IS NULL THEN
              l_field_name := 'POSTAL CODE';
              l_flag       := 1;
            WHEN p_countrycode_in IS NULL THEN
              l_field_name := 'COUNTRY CODE';
              l_flag       := 1;
            WHEN p_nature_of_relation_in IS NULL THEN
              l_field_name := 'NATURE OF RELATIONSHIP';
              l_flag       := 1;
            WHEN p_nature_of_business_in IS NULL THEN
              l_field_name := 'NATURE OF BUSINESS';
              l_flag       := 1;
            ELSE
              NULL;
          END CASE;
      END IF;

      IF upper(p_third_party_type_in) NOT IN ('INDIVIDUAL',
                                              'CORPORATION')
        THEN
          p_status_out := vmscms.gpp_const.c_invalid_data_status;
          g_err_invalid_data.raise(l_api_name,
                                   ',0029,',
                                   'INVALID THIRD PARTY TYPE');
          p_err_msg_out := g_err_invalid_data.get_current_error;
          vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                       p_customer_id_in,
                                                       l_hash_pan,
                                                       l_encr_pan,
                                                       'F', --vmscms.gpp_const.c_failure_flag,
                                                       p_err_msg_out,
                                                       vmscms.gpp_const.c_failure_res_id,
                                                       NULL,
                                                       l_timetaken); --Remarks
        RETURN;
      END IF;

      IF upper(p_third_party_type_in) = 'INDIVIDUAL'
      THEN
       CASE
          WHEN p_firstname_in IS NULL THEN
            l_field_name := 'FIRST NAME';
            l_flag       := 1;
          WHEN p_lastname_in IS NULL THEN
            l_field_name := 'LAST NAME';
            l_flag       := 1;
          WHEN p_dob_in IS NULL THEN
            l_field_name := 'DATE OF BIRTH';
            l_flag       := 1;
          WHEN p_occupation_code_in IS NULL THEN
            l_field_name := 'OCCUPATION CODE';
            l_flag       := 1;
          ELSE
              NULL;
        END CASE;
      END IF;

      IF upper(p_third_party_type_in) = 'CORPORATION'
      THEN
        CASE
           WHEN p_corporationaname_in IS NULL THEN
             l_field_name := 'CORPORATION NAME';
             l_flag       := 1;
           WHEN p_in_corporation_no_in IS NULL THEN
             l_field_name := 'INCORPORATION NUMBER';
             l_flag       := 1;
           ELSE
              NULL;
        END CASE;
      END IF;

      IF upper(p_third_party_type_in) = 'INDIVIDUAL'  AND p_occupation_code_in = '00' THEN
         IF p_occupation_desc_in IS NULL THEN
            l_field_name := 'OCCUPATION DESCRIPTION';
            l_flag       := 1;
         END IF;
      END IF;


	  IF upper(p_third_party_type_in) = 'INDIVIDUAL' THEN
       BEGIN
           SELECT count(*)
             INTO l_occ_count
             FROM vmscms.vms_occupation_mast
            WHERE vom_occu_code = p_occupation_code_in;

           IF l_occ_count = 0 THEN
              p_status_out := vmscms.gpp_const.c_invalid_data_status;
              g_err_invalid_data.raise(l_api_name,
                           ',0029,',
                           'INVALID OCCUPATION CODE IN THIRD PARTY DETAILS');
              p_err_msg_out := g_err_invalid_data.get_current_error;
              vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                     p_customer_id_in,
                                     l_hash_pan,
                                     l_encr_pan,
                                     'F', --vmscms.gpp_const.c_failure_flag,
                                     p_err_msg_out,
                                     vmscms.gpp_const.c_failure_res_id,
                                     NULL,
                                     l_timetaken); --Remarks
              RETURN;
           END IF;
       END;
	  END IF;


      IF upper(p_third_party_type_in) = 'INDIVIDUAL'  AND
         to_char(to_date(p_dob_in,
                       'YYYY-MM-DD'),
               'YYYYMMDD') >= to_char(to_date(SYSDATE,
                                              'DD/MM/RRRR'),
                                      'YYYYMMDD')
          THEN

            p_status_out := vmscms.gpp_const.c_invalid_dob_status;
            g_err_invalid_data.raise(l_api_name,
                                     ',0040,',
                                     'DOB CANNOT BE FUTURE DATE');
            p_err_msg_out := g_err_invalid_data.get_current_error;
            vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                         p_customer_id_in,
                                                         l_hash_pan,
                                                         l_encr_pan,
                                                         'F', --vmscms.gpp_const.c_failure_flag,
                                                         p_err_msg_out,
                                                         vmscms.gpp_const.c_failure_res_id,
                                                         NULL,
                                                         l_timetaken); --Remarks
            RETURN;
      END IF;

      IF p_countrycode_in IN ('US','CA') THEN
         IF length(p_state_in) > 2 THEN
            p_status_out := vmscms.gpp_const.c_invalid_data_status;
            g_err_invalid_data.raise(l_api_name,
                                     ',0029,',
                                     'INVALID STATE');
            p_err_msg_out := g_err_invalid_data.get_current_error;
            vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                         p_customer_id_in,
                                                         l_hash_pan,
                                                         l_encr_pan,
                                                         'F', --vmscms.gpp_const.c_failure_flag,
                                                         p_err_msg_out,
                                                         vmscms.gpp_const.c_failure_res_id,
                                                         NULL,
                                                         l_timetaken); --Remarks
            RETURN;
          END IF;
       END IF;
    END IF;

    IF l_flag = 1
    THEN
      p_status_out := vmscms.gpp_const.c_mandatory_status;
      g_err_mandatory.raise(l_api_name,
                            ',0002,',
                            l_field_name || ' is mandatory');
      p_err_msg_out := g_err_mandatory.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
      RETURN;
     END IF;

    BEGIN

        vmscms.gpp_sp_update_identification(p_action_in,
                                            1, --prm_instcode
                                            '0200', --prm_msg_type
                                            l_plain_pan, --prm_pan_code
                                            '000', --prm_mbrnumb
                                            l_acct_no, --prm_acct_no
                                            l_rrn, --prm_rrn
                                            NULL, --prm_stan
                                            '37', --031716
                                            0, --prm_txn_mode
                                            '03', --prm_delivery_channel
                                            l_date, --prm_trandate
                                            l_time, --prm_trantime
                                            l_curr_code, --prm_currcode
                                            NULL, --prm_ins_user
                                            (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                         'x-incfs-username')), --prm_username
                                            (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                         'x-incfs-sessionid')), --prm_call_id
                                            (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                         'x-incfs-ip')), --prm_ipaddress
                                            l_encr_pan,
                                            l_hash_pan,
                                            -- identification info
                                            p_id_type_in, --PRM_ID_TYPE
                                            p_number_in, -- prm_ssn
                                            p_issuedby_in,
                                            to_char(to_date(p_issuance_date_in,
                                                            'YYYY-MM-DD'),
                                                    'MM/DD/YYYY'),
                                            to_char(to_date(p_expiration_date_in,
                                                            'YYYY-MM-DD'),
                                                    'MM/DD/YYYY'),
                                            p_province_in,
                                            p_countryin,
                                            to_char(to_date(p_verification_date_in,
                                                            'YYYY-MM-DD'),
                                                    'MM/DD/YYYY'),
                                            --occupation info
                                            p_occupation_type_in,
                                            p_occupation_in,
                                            --tax info
                                            p_istax_res_can_in,
                                            p_taxpin_in,
                                            p_no_tax_reason_id_in,
                                            p_no_tax_reason_desc_in,
                                            p_tax_juris_resident_in,
                                            --thirdparty info
                                            p_isthird_party_benft_in,
                                            p_third_party_type_in,
                                            p_firstname_in,
                                            p_lastname_in,
                                            p_corporationaname_in,
                                            to_char(to_date(p_dob_in,
                                                      'YYYY-MM-DD'),
                                              'MM/DD/YYYY'),
                                            p_addrone_in,
                                            p_addrtwo_in,
                                            p_city_in,
                                            p_state_in,
                                            p_postalcode_in,
                                            p_countrycode_in,
                                            p_occupation_code_in,
                                            p_occupation_desc_in,
                                            p_in_corporation_no_in,
                                            p_nature_of_relation_in,
                                            p_nature_of_business_in,
                                            0, --prm_rvsl_code
                                            p_status_out, --prm_resp_code
                                            p_err_msg_out --prm_resp_msg
                                            );

        g_debug.display('p_status_out' || p_status_out);
        g_debug.display('p_err_msg_out' || p_err_msg_out);

      EXCEPTION
        WHEN OTHERS THEN
          p_status_out  := p_status_out;
          p_err_msg_out := p_err_msg_out;
          RETURN;
      END;

    UPDATE vmscms.TRANSACTIONLOG
       SET correlation_id =
            (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                         'x-incfs-correlationid')),
           fsapi_username =
            (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                         'x-incfs-username')),
           partner_id    =
            (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                         'x-incfs-partnerid')),
            ipaddress     = (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                           'x-incfs-ip'))
      WHERE rrn = l_rrn;
 --Added for VMS-5733/FSP-991
     IF SQL%ROWCOUNT = 0 THEN 
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST
         SET correlation_id =
            (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                         'x-incfs-correlationid')),
           fsapi_username =
            (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                         'x-incfs-username')),
           partner_id    =
            (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                         'x-incfs-partnerid')),
            ipaddress     = (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                           'x-incfs-ip'))
      WHERE rrn = l_rrn;
  end if;

    SELECT MAX(ccd_call_seq)
      INTO l_call_seq
      FROM cms_calllog_details
     WHERE ccd_acct_no = l_acct_no
       AND ccd_inst_code = 1
       AND ccd_rrn = l_rrn
       AND ccd_call_id = (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-sessionid'));
    UPDATE vmscms.cms_calllog_details
       SET ccd_fsapi_username =
           (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                        'x-incfs-username'))
     WHERE ccd_acct_no = l_acct_no
       AND ccd_inst_code = 1
       AND ccd_rrn = l_rrn
       AND ccd_call_id = (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-sessionid'))
       AND ccd_call_seq = l_call_seq;

    IF p_status_out <> '00'
       AND p_err_msg_out <> 'OK'
    THEN
      p_status_out  := p_status_out;
      p_err_msg_out := p_err_msg_out;
      RETURN;
    ELSE
      p_status_out  := vmscms.gpp_const.c_success_status;
      p_err_msg_out := 'SUCCESS';
    END IF;
    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

  EXCEPTION
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN OTHERS THEN
      p_status_out  := vmscms.gpp_const.c_update_account_status;
      p_err_msg_out := substr(SQLERRM,
                              1,
                              100);
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_update_account_status);
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

  END update_identification_info;

    PROCEDURE init IS
  BEGIN
    -- initialize all errors here
    g_err_nodata       := fsfw.fserror_t('E-NO-DATA',
                                         '$1 $2');
    g_err_mandatory    := fsfw.fserror_t('E-MANDATORY',
                                         'Mandatory Field is NULL: $1 $2 $3',
                                         'NOTIFY');
    g_err_unknown      := fsfw.fserror_t('E-UNKNOWN',
                                         'Unknown error: $1 $2',
                                         'NOTIFY');
    g_err_invalid_data := fsfw.fserror_t('E-INVALID_DATA',
                                         'RULE TYPE: $1 $2 $3');
    g_err_failure      := fsfw.fserror_t('E-FAILURE',
                                         'Procedure failed: $1 $2 $3');

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

  FUNCTION get_gpp_context(p_name_in IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                       p_name_in));
  END get_gpp_context;

BEGIN
  -- Initialization
  init;

END GPP_IDENTIFICATION;
/
show error