create or replace PACKAGE BODY   vmscms.GPP_PRODUCTS IS

   -- PL/SQL Package using FS Framework
   -- Author  : SINDHU
   -- Created : 12-08-2015 16:10:26

   -- Private type declarations
   -- TEST 1

   -- Private constant declarations

   -- Private variable declarations

   -- global variables for the FS framework
   g_config fsfw.fstype.parms_typ;
   g_debug  fsfw.fsdebug_t;

   --declare all FS errors here
   g_err_nodata  fsfw.fserror_t;
   g_err_unknown fsfw.fserror_t;

   -- Function and procedure implementations

   --Get products API
   --status: 0 - success, 1 - failure
   PROCEDURE get_products
   (
      p_status_out   OUT VARCHAR2,
      p_err_msg_out  OUT VARCHAR2,
      c_products_out OUT SYS_REFCURSOR
   ) AS
      l_api_name   VARCHAR2(20) := 'GET PRODUCTS';
      l_start_time NUMBER;
      l_end_time   NUMBER;
      l_timetaken  NUMBER;
      
/****************************************************************************    
	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002
	 
	 * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 08-Sep-2021
         * Modified Reason    : VMS-5069 - CCA GetProduct API calls when 
	 				670+ packs are assigned to Product Category.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 08-Sep-2021
	 
****************************************************************************/
      
   BEGIN
      l_start_time := dbms_utility.get_time;
      dbms_output.put_line('l_start_time' || l_start_time);
      --Array for products
      OPEN c_products_out FOR
        SELECT pmaster.cpm_prod_code   product_id,
			   pmaster.cpm_prod_desc   product_name,
			   pmaster.cpm_prod_desc   product_desc,
			   pmaster.cpm_prod_code   product_code,
			   ptype.cpc_card_type     type_id,
			   ptype.cpc_cardtype_desc type_name,
			   ptype.cpc_cardtype_desc type_desc,
			   (SELECT gcm_switch_cntry_code
				FROM vmscms.gen_cntry_mast
				WHERE gcm_curr_code =(SELECT cbp_param_value
									  FROM vmscms.cms_bin_param
									  WHERE cbp_profile_code = ptype.cpc_profile_code
									  AND cbp_param_name   = 'Currency'
			   ) and gcm_inst_code = 1) issuedCountry,
			   ptype.cpc_issu_bank  issuedBank,
               ptype.cpc_dcms_id  dcmsId,
              (SELECT RTRIM(XMLCAST(XMLAGG(XMLELEMENT(e,cpc_card_details|| '||')) as clob),'||') 
	              --- LISTAGG(cpc_card_details,'||')
                      ---   WITHIN GROUP (ORDER BY cpc_card_details)
            		FROM vmscms.cms_prodcat_cardpack A,vmscms.cms_prod_cardpack B
            		WHERE A.cpc_prod_code =B.cpc_prod_code
                    AND A.cpc_card_id =B.cpc_card_id
                    AND ptype.cpc_prod_code =a.cpc_prod_code
                    AND ptype.cpc_card_type = A.cpc_catg_code
	            	GROUP BY (A.cpc_prod_code,A.cpc_catg_code)) packageIds
		FROM vmscms.cms_prod_mast pmaster, vmscms.cms_prod_cattype ptype
		WHERE pmaster.cpm_prod_code = ptype.cpc_prod_code
		ORDER BY product_id, type_id;

      --time taken
      l_end_time := dbms_utility.get_time;
      g_debug.display('l_end_time' || l_end_time);
      l_timetaken := (l_end_time - l_start_time);
      g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
      g_debug.display('Elapsed Time: ' ||
                      (l_end_time - l_start_time) / 100 || ' secs');

      p_status_out := vmscms.gpp_const.c_success_status;
      /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                   NULL, --customer id
                                                   NULL, --hash pan
                                                   NULL, --encrypted pan
                                                   'C', --vmscms.gpp_const.c_success_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_success_res_id,
                                                   NULL,
                                                   l_timetaken);*/

   EXCEPTION
      WHEN no_data_found THEN
         p_status_out := vmscms.gpp_const.c_ora_error_status;
         g_err_nodata.raise(l_api_name,
                            vmscms.gpp_const.c_ora_error_status);
         p_err_msg_out := g_err_nodata.get_current_error;
         vmscms.gpp_transaction.audit_transaction_log(l_api_name,
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
         g_err_unknown.raise(l_api_name || ' FAILED',
                             vmscms.gpp_const.c_ora_error_status);
         p_err_msg_out := g_err_unknown.get_current_error;
         vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      'F',
                                                      p_err_msg_out,
                                                      vmscms.gpp_const.c_failure_res_id,
                                                      NULL,
                                                      l_timetaken);
   END get_products;

   -- the init procedure is private and should ALWAYS exist

   PROCEDURE init IS
   BEGIN
      -- initialize all errors here
      g_err_nodata  := fsfw.fserror_t('E-NO-DATA', '$1 $2');
      g_err_unknown := fsfw.fserror_t('E-UNKNOWN',
                                      'Unknown error: $1 $2',
                                      'NOTIFY');
      -- load configuration elements
      g_config := fsfw.fsconfig.get_configuration($$PLSQL_UNIT);
      IF g_config.exists(fsfw.fsconst.c_debug)
      THEN
         g_debug := fsfw.fsdebug_t($$PLSQL_UNIT,
                                   g_config(fsfw.fsconst.c_debug));
      ELSE
         g_debug := fsfw.fsdebug_t($$PLSQL_UNIT, '');
      END IF;
   END init;

   -- the get_cpp_context function returns the value of the specific
   -- context value set in the application context for the GPP application

   FUNCTION get_gpp_context(p_name_in IN VARCHAR2) RETURN VARCHAR2 IS
   BEGIN
      RETURN(sys_context(fsfw.fsconst.c_fsapi_gpp_context, p_name_in));
   END get_gpp_context;

BEGIN
   -- Initialization
   init;
END gpp_products;
/
show error