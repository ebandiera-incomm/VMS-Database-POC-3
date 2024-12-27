create or replace PACKAGE BODY                    VMSCMS.GPP_RULES AS

  -- global variables for the FS framework
  g_config fsfw.fstype.parms_typ;
  g_debug  fsfw.fsdebug_t;
  --declare all FS errors here
  g_err_unknown      fsfw.fserror_t;
  g_err_nodata       fsfw.fserror_t;
  g_err_mandatory    fsfw.fserror_t;
  g_err_invalid_data fsfw.fserror_t;
  g_err_failure      fsfw.fserror_t;


 PROCEDURE create_rule(p_rulename_in       IN VARCHAR2,
                        p_ruletype_in       IN VARCHAR2,
                        p_id_in             IN VARCHAR2,
           			    p_name_in           IN VARCHAR2,
                        p_reason_in         IN VARCHAR2,
                        p_description_in    IN VARCHAR2,
						p_prodbin_in		IN VARCHAR2, -- added for vms-6337 on 14-Sep-2022 By Bhavani
						p_prodcatg_in		IN VARCHAR2,   -- added for vms-6337 on 14-Sep-2022 By Bhavani
                        p_status_out        OUT VARCHAR2,
                        p_err_msg_out       OUT VARCHAR2,
                        c_ruleinfo_out      OUT SYS_REFCURSOR,
                        c_relatedrules_out  OUT SYS_REFCURSOR) AS

    l_field_name VARCHAR2(50);
    l_api_name   VARCHAR2(30) := 'CREATE_RULE';
    l_flag       PLS_INTEGER := 0;
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;
    l_active     VARCHAR2(2) := 'A';
    l_count_rule NUMBER;
    l_ruletype   VARCHAR2(50);
	l_rule_value vmscms.VMS_MERCHANT_RULE.vmr_rule_value%type;
	l_ruleid 	 vmscms.VMS_MERCHANT_RULE.vmr_rule_id%type;
	l_prod_code  vmscms.CMS_PROD_BIN.CPB_PROD_CODE%type;  -- added for vms-6337 on 14-Sep-2022 By Bhavani
    l_card_type  vmscms.cms_prod_cattype.cpc_card_type%type;  -- added for vms-6337 on 14-Sep-2022 By Bhavani

/****************************************************************************************
         * Modified By        : UBAIDUR RAHMAN
         * Modified Date      : 17-Jan-2019
         * Modified Reason    : VMS-357 FSAPICCA-112 -
	 			Merchant Block: Create Rule API enhancement.

         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 18-Jan-2019
         * Build Number       : R11_B0003

		 * Modified By        : BHAVANI ETHIRAJAN
         * Modified Date      : 14-Sep-2022
         * Modified Reason    : VMS-6337 Enhance Batch Job  Microservice  to Add Merchant Blocks
         * Reviewer           : Venkat S.
         * Build Number       :
*****************************************************************************************/


  BEGIN
    l_start_time := dbms_utility.get_time;


    CASE
      WHEN p_rulename_in IS NULL THEN
        l_field_name := 'RULENAME';
        l_flag       := 1;
      WHEN p_reason_in IS NULL THEN
        l_field_name := 'REASON';
        l_flag       := 1;
      WHEN p_description_in IS NULL THEN
        l_field_name := 'DESCRIPTION';
        l_flag       := 1;
	  WHEN  p_prodbin_in IS NULL AND p_prodcatg_in IS NOT NULL  THEN  -- added for vms-6337 on 14-Sep-2022 By Bhavani
		l_field_name := 'BIN';
		l_flag       := 1;
      ELSE
        NULL;
    END CASE;

    IF l_flag = 1
    THEN
      p_status_out := vmscms.gpp_const.c_mandatory_status;
      g_err_mandatory.raise(l_api_name,
                            ',0002,',
                            l_field_name || ' is mandatory');
      p_err_msg_out := g_err_mandatory.get_current_error;
      RETURN;
    END IF;

    IF upper(p_ruletype_in) <> 'MERCHANT'
    THEN
      p_status_out := vmscms.gpp_const.c_invalid_rule_type;
      g_err_invalid_data.raise(l_api_name,
                               ',0047,',
                               'RULETYPE' ||
                               ' should be ''MERCHANT');
      p_err_msg_out := g_err_invalid_data.get_current_error;
      RETURN;
    END IF;

	IF p_id_in IS NOT NULL AND p_name_in IS NOT NULL
    	THEN
		l_rule_value := p_id_in||'|'||p_name_in;
		l_ruletype := 3;

	ELSIF p_id_in IS NOT NULL
	THEN
		l_rule_value := p_id_in;
		l_ruletype := 1;

	ELSIF p_name_in IS NOT NULL
	THEN
		l_rule_value := p_name_in;
		l_ruletype := 2;
	ELSE
      p_status_out := vmscms.gpp_const.c_invalid_rule_type;
      g_err_invalid_data.raise(l_api_name,
                               ',0047,',
                               'ID_NAME' ||
                               ' either ID or NAME should be MANDATORY');
      p_err_msg_out := g_err_invalid_data.get_current_error;
      RETURN;
    END IF;

    --SN: Added for vms-6337 on 14-Sep-2022 bhavani
    IF p_prodbin_in IS NOT NULL THEN
    BEGIN
		SELECT cpb_prod_code
          INTO l_prod_code
          FROM vmscms.cms_prod_bin
		 WHERE cpb_inst_code =1
		   AND cpb_inst_bin = TO_NUMBER(p_prodbin_in);
	EXCEPTION
	  WHEN NO_DATA_FOUND THEN
		p_status_out := vmscms.gpp_const.c_invalid_rule_type;
		g_err_invalid_data.raise(l_api_name,
                               ',0047,',
                               'BIN' ||
                               ' Is INVALID, Please Enter Valid BIN');
		p_err_msg_out := g_err_invalid_data.get_current_error;
      RETURN;
	END;
    END IF;

    IF l_prod_code IS NOT NULL and p_prodcatg_in IS NOT NULL THEN
    BEGIN
     SELECT TO_NUMBER(p_prodcatg_in)
       INTO l_card_type
       FROM dual;
    EXCEPTION
     WHEN OTHERS THEN
        p_status_out := vmscms.gpp_const.c_invalid_rule_type;
		g_err_invalid_data.raise(l_api_name,
                               ',0047,',
                               'PRODCATG' ||
                               ' Is INVALID, Please Enter Valid PROD Category');
		p_err_msg_out := g_err_invalid_data.get_current_error;
      RETURN;
    END;

	BEGIN
		SELECT COUNT(*)
			INTO l_count_rule
			FROM vmscms.cms_prod_cattype
           WHERE cpc_inst_code =1
			 AND cpc_prod_code = l_prod_code
			 AND cpc_card_type = l_card_type;

		IF l_count_rule = 0 THEN
			p_status_out := vmscms.gpp_const.c_invalid_rule_type;
			g_err_invalid_data.raise(l_api_name,
                               ',0047,',
                               'PRODCATG' ||
                               ' Is INVALID, Please Enter Valid Product Category');
				p_err_msg_out := g_err_invalid_data.get_current_error;
			RETURN;
		END IF;
	END;
    END IF;

    IF l_prod_code IS NOT NULL AND p_prodcatg_in IS NOT NULL THEN
        SELECT COUNT(*)
          INTO l_count_rule
          FROM vmscms.vms_merchant_rule
         WHERE vmr_rule_type =l_ruletype
           AND vmr_rule_value = l_rule_value
           AND vmr_rule_status IN ('A','I')
           AND vmr_prod_code =l_prod_code
           AND vmr_card_type = l_card_type;

    ELSIF l_prod_code IS NOT NULL
    THEN
        SELECT COUNT(*)
          INTO l_count_rule
          FROM vmscms.vms_merchant_rule
         WHERE vmr_rule_type =l_ruletype
           AND vmr_rule_value = l_rule_value
           AND vmr_rule_status IN ('A','I')
           AND vmr_prod_code =l_prod_code  ;

    ELSE
    --EN: Added for vms-6337 on 14-Sep-2022 bhavani
        SELECT COUNT(*)
          INTO l_count_rule
          FROM vmscms.vms_merchant_rule
         WHERE vmr_rule_type =l_ruletype
           AND vmr_rule_value = l_rule_value
           AND vmr_rule_status IN ('A','I');
    END IF;

    IF l_count_rule > 0
    THEN
      p_status_out := vmscms.gpp_const.c_invalid_rule_type;
      g_err_invalid_data.raise(l_api_name,
                               ',0004,',
                               'RULEVALUE' || ' already present');
      p_err_msg_out := g_err_invalid_data.get_current_error;

      RETURN;
    END IF;

    l_ruleid:= vmscms.seq_merchant_ruleid.nextval;

    INSERT INTO vmscms.vms_merchant_rule
      (vmr_rule_id,
       vmr_rule_name,
       vmr_rule_type,
       vmr_rule_value,
       vmr_reason,
       vmr_description,
       vmr_rule_status,
       vmr_created_by,
       vmr_created_at,
       vmr_lupd_by,
       vmr_lupd_at,
       vmr_enforced_count,
	   vmr_prod_code, -- added for vms-6337 on 14-Sep-2022 By Bhavani
	   vmr_card_type) -- added for vms-6337 on 14-Sep-2022 By Bhavani
    VALUES
      (l_ruleid,
       p_rulename_in,
       l_ruletype,
       l_rule_value,
       p_reason_in,
       p_description_in,
       l_active,
       sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                   'x-incfs-username'),
       SYSDATE,
       sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                   'x-incfs-username'),
       SYSDATE,
       0,
	   l_prod_code,  -- added for vms-6337 on 14-Sep-2022 By Bhavani
	   l_card_type); -- added for vms-6337 on 14-Sep-2022 By Bhavani


       OPEN c_ruleinfo_out FOR
      SELECT vmr_rule_id ruleid,
             vmr_rule_name rulename,
             'MERCHANT' ruletype,
             CASE WHEN vmr_rule_type = 1 THEN vmr_rule_value
                      WHEN vmr_rule_type = 3 THEN substr(vmr_rule_value,1,instr(vmr_rule_value,'|')-1) end id,
                 CASE WHEN vmr_rule_type = 2 THEN vmr_rule_value
                      WHEN vmr_rule_type = 3 THEN substr(vmr_rule_value,instr(vmr_rule_value,'|')+1) end name,
             vmr_reason reason,
             vmr_description description,
             DECODE(vmr_rule_status,
                    'A',
                    'ACTIVE',
                    'I',
                    'INACTIVE') status,
             vmr_created_by createduser,
             vmr_lupd_by lastmodifieduser,
             to_char(vmr_created_at, 'YYYY-MM-DD HH24:MI:SS') createddate,
             to_char(vmr_lupd_at, 'YYYY-MM-DD HH24:MI:SS') lastmodifieddate,
             vmr_enforced_count enforcedcount,
             TO_NUMBER(p_prodbin_in) BIN,  -- added for vms-6337 on 14-Sep-2022 By Bhavani
             vmr_card_type PRODUCTCATEGORY  -- added for vms-6337 on 14-Sep-2022 By Bhavani
        FROM vmscms.vms_merchant_rule
       WHERE vmr_rule_id = l_ruleid;

       OPEN c_relatedrules_out FOR
      SELECT vmr_rule_id ruleid,
             vmr_rule_name rulename,
             'MERCHANT' ruletype,
                 CASE WHEN vmr_rule_type = 1 THEN vmr_rule_value
                      WHEN vmr_rule_type = 3 THEN substr(vmr_rule_value,1,instr(vmr_rule_value,'|')-1)  end id,
                 CASE WHEN vmr_rule_type = 2 THEN vmr_rule_value
                      WHEN vmr_rule_type = 3 THEN substr(vmr_rule_value,instr(vmr_rule_value,'|')+1)  end name,
             vmr_reason reason,
             vmr_description description,
             DECODE(vmr_rule_status,
                    'A',
                    'ACTIVE',
                    'I',
                    'INACTIVE') status,
             vmr_created_by createduser,
             vmr_lupd_by lastmodifieduser,
             to_char(vmr_created_at, 'YYYY-MM-DD HH24:MI:SS') createddate,
             to_char(vmr_lupd_at, 'YYYY-MM-DD HH24:MI:SS') lastmodifieddate,
             vmr_enforced_count enforcedcount,
             (select cpb_inst_bin from vmscms.cms_prod_bin where CPB_PROD_CODE= vmr_prod_code) BIN,   -- added for vms-6337 on 14-Sep-2022 By Bhavani
             vmr_card_type PRODUCTCATEGORY  -- added for vms-6337 on 14-Sep-2022 By Bhavani
        FROM vmscms.vms_merchant_rule
       WHERE ((l_ruletype = 2 and p_name_in= substr(vmr_rule_value,instr(vmr_rule_value,'|')+1) and vmr_rule_type=3))
          OR (l_ruletype  = 1 and p_id_in= substr(vmr_rule_value,1,instr(vmr_rule_value,'|')-1) and vmr_rule_type=3)
          OR (l_ruletype  = 3 and ((p_id_in = vmr_rule_value and vmr_rule_type=1) or
                                   (p_name_in=vmr_rule_value and vmr_rule_type=2) or
                                   (((p_id_in= substr(vmr_rule_value,1,instr(vmr_rule_value,'|')-1))or
                                    (p_name_in= substr(vmr_rule_value,instr(vmr_rule_value,'|')+1))) and vmr_rule_type=3)))
         AND vmr_rule_status IN ('A','I')
         AND vmr_rule_id <> l_ruleid;

    p_err_msg_out := vmscms.gpp_const.c_success_msg;
    l_end_time    := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out := vmscms.gpp_const.c_success_status;

  EXCEPTION
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;

  END create_rule;

  PROCEDURE update_merchant_rule(p_ruleid_in   IN VARCHAR2,
                                 p_action_in   IN VARCHAR2,
                                 p_status_out  OUT VARCHAR2,
                                 p_err_msg_out OUT VARCHAR2) AS

    l_field_name     VARCHAR2(50);
    l_api_name       VARCHAR2(30) := 'UPDATE_MERCHANT_RULE';
    l_flag           PLS_INTEGER := 0;
    l_start_time     NUMBER;
    l_end_time       NUMBER;
    l_timetaken      NUMBER;
    l_rule_status    vmscms.vms_merchant_rule.vmr_rule_status%TYPE;
    l_enforced_count vmscms.vms_merchant_rule.vmr_enforced_count%TYPE;

  BEGIN
    CASE
      WHEN p_ruleid_in IS NULL THEN
        l_field_name := 'RULEID';
        l_flag       := 1;
      WHEN p_action_in IS NULL THEN
        l_field_name := 'ACTION';
        l_flag       := 1;
      ELSE
        NULL;
    END CASE;

    IF l_flag = 1
    THEN
      p_status_out := vmscms.gpp_const.c_mandatory_status;
      g_err_mandatory.raise(l_api_name,
                            ',0002,',
                            l_field_name || ' is mandatory');
      p_err_msg_out := g_err_mandatory.get_current_error;
      RETURN;
    END IF;

    IF upper(p_action_in) NOT IN ('REACTIVATE',
                                  'DEACTIVATE',
                                  'DELETE')
    THEN
      p_status_out := vmscms.gpp_const.c_invalid_action;
      g_err_invalid_data.raise(l_api_name,
                               ',0048,',
                               'ACTION' ||
                               ' shoule be either ''REACTIVATE, DEACTIVATE or DELETE');
      p_err_msg_out := g_err_invalid_data.get_current_error;
      RETURN;
    END IF;

    BEGIN
      SELECT vmr_rule_status,
             vmr_enforced_count
        INTO l_rule_status,
             l_enforced_count
        FROM vmscms.vms_merchant_rule
       WHERE vmr_rule_id = p_ruleid_in;

    EXCEPTION
      WHEN no_data_found THEN
        p_status_out := vmscms.gpp_const.c_ora_error_status;
        g_err_nodata.raise(l_api_name,
                           vmscms.gpp_const.c_ora_error_status);
        p_err_msg_out := g_err_nodata.get_current_error;
        RETURN;
      WHEN OTHERS THEN
        p_status_out := vmscms.gpp_const.c_ora_error_status;
        g_err_nodata.raise(l_api_name,
                           vmscms.gpp_const.c_ora_error_status);
        p_err_msg_out := g_err_nodata.get_current_error;
        RETURN;
    END;

    IF ((p_action_in = 'REACTIVATE' AND l_rule_status = 'A') OR
       (p_action_in = 'DEACTIVATE' AND l_rule_status = 'I'))
    THEN
      p_status_out := vmscms.gpp_const.c_invalid_action;
      g_err_invalid_data.raise(l_api_name,
                               ',0004,',
                               'RULEID' || ' already in given state');
      p_err_msg_out := g_err_invalid_data.get_current_error;
      RETURN;
    ELSIF (p_action_in IN ('REACTIVATE',
                           'DEACTIVATE') AND l_rule_status = 'D')
    THEN
      p_status_out := vmscms.gpp_const.c_invalid_action;
      g_err_invalid_data.raise(l_api_name,
                               ',0004,',
                               'RULEID' ||
                               ' cannot be reactivated/deactivated');
      p_err_msg_out := g_err_invalid_data.get_current_error;
      RETURN;
    END IF;

    IF p_action_in = 'DELETE'
       AND l_enforced_count != 0
    THEN
      p_status_out := vmscms.gpp_const.c_invalid_action;
      g_err_invalid_data.raise(l_api_name,
                               ',0004,',
                               'ACTION' ||
                               ' can be DELETE only when ENFORCED COUNT is 0');
      p_err_msg_out := g_err_invalid_data.get_current_error;
      RETURN;
    END IF;

    UPDATE vmscms.vms_merchant_rule
       SET vmr_rule_status = DECODE(p_action_in,
                                    'REACTIVATE',
                                    'A',
                                    'DEACTIVATE',
                                    'I',
                                    'DELETE',
                                    'D'),
           vmr_lupd_at     = SYSDATE,
           vmr_lupd_by     = sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                         'x-incfs-username')
     WHERE vmr_rule_id = p_ruleid_in;

    p_err_msg_out := vmscms.gpp_const.c_success_msg;
    l_end_time    := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out := vmscms.gpp_const.c_success_status;

  EXCEPTION
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;

  END update_merchant_rule;



  PROCEDURE get_rule        ( p_ruleid_in           IN VARCHAR2,
                              p_status_in           IN VARCHAR2,
                              p_status_out          OUT VARCHAR2,
                              p_err_msg_out         OUT VARCHAR2,
                              c_rules_out           OUT SYS_REFCURSOR,
                              c_relatedrules_out    OUT SYS_REFCURSOR) AS

    l_field_name   VARCHAR2(50);
    l_api_name     VARCHAR2(30) := 'GET_RULE';
    l_flag         PLS_INTEGER := 0;
    l_start_time   NUMBER;
    l_end_time     NUMBER;
    l_timetaken    NUMBER;
    l_id_in        vmscms.VMS_MERCHANT_RULE.vmr_rule_value%type;
    l_name_in      vmscms.VMS_MERCHANT_RULE.vmr_rule_value%type;
    l_ruletype     vmscms.VMS_MERCHANT_RULE.vmr_rule_type%type;
    l_rule_value   vmscms.VMS_MERCHANT_RULE.vmr_rule_value%type;

/****************************************************************************************
         * Modified By        : UBAIDUR RAHMAN
         * Modified Date      : 17-Jan-2019
         * Modified Reason    : VMS-623 FSAPICCA-154 -
	 			Merchant Block: Get Rule API enhancement.

         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 18-Jan-2019
         * Build Number       : R11_B0003
*****************************************************************************************/


  BEGIN
    l_start_time := dbms_utility.get_time;
    IF upper(p_status_in) NOT IN ('ALL',
                                  'ACTIVE',
                                  'INACTIVE')
    THEN
      p_status_out := vmscms.gpp_const.c_invalid_status;
      g_err_invalid_data.raise(l_api_name,
                               ',0004,',
                               'STATUS' ||
                               ' shoule be either ''ALL, ACTIVE or INACTIVE');
      p_err_msg_out := g_err_invalid_data.get_current_error;
      RETURN;
    END IF;


    OPEN c_rules_out FOR
      SELECT vmr_rule_id ruleid,
             vmr_rule_name rulename,
             'MERCHANT' ruletype,
                 CASE WHEN vmr_rule_type = 1 THEN vmr_rule_value
                      WHEN vmr_rule_type = 3 THEN substr(vmr_rule_value,0,instr(vmr_rule_value,'|')-1) end id,
                 CASE WHEN vmr_rule_type = 2 THEN vmr_rule_value
                      WHEN vmr_rule_type = 3 THEN substr(vmr_rule_value,instr(vmr_rule_value,'|')+1) end name,
             vmr_reason reason,
             vmr_description description,
             DECODE(vmr_rule_status,
                    'A',
                    'ACTIVE',
                    'I',
                    'INACTIVE') status,
             vmr_created_by createduser,
             vmr_lupd_by lastmodifieduser,
             to_char(vmr_created_at, 'YYYY-MM-DD HH24:MI:SS') createddate,
             to_char(vmr_lupd_at, 'YYYY-MM-DD HH24:MI:SS') lastmodifieddate,
             vmr_enforced_count enforcedcount
        FROM vmscms.vms_merchant_rule
       WHERE (vmr_rule_id = p_ruleid_in OR p_ruleid_in IS NULL)
         AND vmr_rule_status = DECODE(p_status_in,
                                      'ACTIVE',
                                      'A',
                                      'INACTIVE',
                                      'I',
                                      vmr_rule_status)
         AND vmr_rule_status != 'D';

    IF p_ruleid_in IS NOT NULL
    THEN


       SELECT vmr_rule_type,vmr_rule_value
         INTO l_ruletype,l_rule_value
         FROM vmscms.vms_merchant_rule
        WHERE vmr_rule_id = p_ruleid_in;


    IF l_ruletype = 1 THEN

        l_id_in := l_rule_value;

    ELSIF l_ruletype = 2 THEN

        l_name_in := l_rule_value;

    ELSE

        l_id_in := SUBSTR(l_rule_value,0,instr(l_rule_value,'|')-1);
        l_name_in:= SUBSTR(l_rule_value,instr(l_rule_value,'|')+1);

    END IF;



      OPEN c_relatedrules_out FOR
      SELECT vmr_rule_id ruleid,
             vmr_rule_name rulename,
             'MERCHANT' ruletype,
                 CASE WHEN vmr_rule_type = 1 THEN vmr_rule_value
                      WHEN vmr_rule_type = 3 THEN substr(vmr_rule_value,1,instr(vmr_rule_value,'|')-1)  end id,
                 CASE WHEN vmr_rule_type = 2 THEN vmr_rule_value
                      WHEN vmr_rule_type = 3 THEN substr(vmr_rule_value,instr(vmr_rule_value,'|')+1)  end name,
             vmr_reason reason,
             vmr_description description,
             DECODE(vmr_rule_status,
                    'A',
                    'ACTIVE',
                    'I',
                    'INACTIVE') status,
             vmr_created_by createduser,
             vmr_lupd_by lastmodifieduser,
             to_char(vmr_created_at, 'YYYY-MM-DD HH24:MI:SS') createddate,
             to_char(vmr_lupd_at, 'YYYY-MM-DD HH24:MI:SS') lastmodifieddate,
             vmr_enforced_count enforcedcount
        FROM vmscms.vms_merchant_rule
       WHERE ((l_ruletype = 2 and l_name_in= substr(vmr_rule_value,instr(vmr_rule_value,'|')+1) and vmr_rule_type=3))
          OR (l_ruletype  = 1 and l_id_in= substr(vmr_rule_value,1,instr(vmr_rule_value,'|')-1) and vmr_rule_type=3)
          OR (l_ruletype  = 3 and ((l_id_in = vmr_rule_value and vmr_rule_type=1) or
                                   (l_name_in=vmr_rule_value and vmr_rule_type=2) or
                                   (((l_id_in= substr(vmr_rule_value,1,instr(vmr_rule_value,'|')-1))or
                                    (l_name_in= substr(vmr_rule_value,instr(vmr_rule_value,'|')+1))) and vmr_rule_type=3)))
         AND vmr_rule_status IN ('A','I')
         AND vmr_rule_id <> p_ruleid_in;

     END IF;


    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');
    p_err_msg_out := vmscms.gpp_const.c_success_msg;
    p_status_out  := vmscms.gpp_const.c_success_status;

  EXCEPTION
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;

  END get_rule;

	PROCEDURE get_fraud_rule( p_customer_id_in   IN  VARCHAR2,
                              p_token_value_in   IN  VARCHAR2,
                              p_status_out       OUT VARCHAR2,
                              p_err_msg_out      OUT VARCHAR2,
                              c_fraud_rule_out   OUT SYS_REFCURSOR) AS

    l_field_name    VARCHAR2(50);
    l_api_name      VARCHAR2(30) := 'GET_FRAUD_RULE';
    l_flag          PLS_INTEGER := 0;
    l_start_time    NUMBER;
    l_end_time      NUMBER;
    l_timetaken     NUMBER;
    l_acct_no	     VMSCMS.VMS_TOKEN_INFO.VTI_ACCT_NO%TYPE;
    l_encr_pan       VMSCMS.TRANSACTIONLOG.CUSTOMER_CARD_NO_ENCR%TYPE;
    l_hash_pan       VMSCMS.TRANSACTIONLOG.CUSTOMER_CARD_NO%TYPE;
    l_correlation_id VMSCMS.VMS_TOKEN_INFO.VTI_DE62_CORRELATION_ID%TYPE;

/****************************************************************************
	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002

****************************************************************************/

  BEGIN
    l_start_time := dbms_utility.get_time;


          VMSCMS.GPP_PAN.GET_PAN_DETAILS(p_customer_id_in,
                                          l_hash_pan,
                                          l_encr_pan,
                                          l_acct_no);


    IF l_acct_no IS NULL
    THEN
              p_err_msg_out := 'Invalid Customer ID';
              RAISE no_data_found;

    END IF;


      	SELECT VTI_DE62_CORRELATION_ID
          INTO L_CORRELATION_ID
          FROM VMSCMS.VMS_TOKEN_INFO
         WHERE VTI_TOKEN = p_token_value_in
           AND VTI_ACCT_NO = l_acct_no ;



          OPEN c_fraud_rule_out FOR
        SELECT VRR_RULE_NAME ruleName,
               VRR_RULE_DESC ruleDescription,
               VRR_RULE_RESULT isPassed,
               to_char(VRR_EXECUTION_TIME,'YYYY-MM-DD HH24:MI:SS') executionTime
          FROM VMSCMS.VMS_RULECHECK_RESULTS
         WHERE VRR_TOKEN = p_token_value_in
         UNION
         SELECT VRR_RULE_NAME ruleName,
               VRR_RULE_DESC ruleDescription,
               VRR_RULE_RESULT isPassed,
               to_char(VRR_EXECUTION_TIME,'YYYY-MM-DD HH24:MI:SS') executionTime
          FROM VMSCMS.VMS_RULECHECK_RESULTS
         WHERE VRR_CORRELATION_ID = L_CORRELATION_ID;



    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');
    p_err_msg_out := vmscms.gpp_const.c_success_msg;
    p_status_out  := vmscms.gpp_const.c_success_status;

    ----Commented for VMS-1719 - CCA RRN Logging Issue.
	/*vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                 p_customer_id_in,
                                                 l_hash_pan,
                                                 l_encr_pan,
                                                 'C',
                                                 'SUCCESS',
                                                 vmscms.gpp_const.c_success_res_id,
                                                 NULL,
                                                 l_timetaken);*/

  EXCEPTION
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         VMSCMS.GPP_CONST.C_ORA_ERROR_STATUS);
      p_err_msg_out := 'INVALID CUSTOMER ID / TOKEN ';
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
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;
	  vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

  END get_fraud_rule;



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

END gpp_rules;
/