create or replace
package body vmscms.vmsfunutilities as
    procedure get_currency_code(
          p_prod_code_in in cms_prod_mast.cpm_prod_code%type,
          p_card_type_in in cms_prod_cattype.cpc_card_type%type,
          p_inst_code_in in cms_inst_mast.cim_inst_code%type,
          p_currency_code_out out cms_bin_param.cbp_param_value%type,
          p_err_msg_out out varchar2)
           AS
    BEGIN
    p_err_msg_out:='OK';
        BEGIN
        select CBP_PARAM_VALUE
         INTO p_currency_code_out
         from CMS_BIN_PARAM,CMS_PROD_CATTYPE
        WHERE CBP_PROFILE_CODE = CPC_PROFILE_CODE AND
              cpC_prod_code=p_prod_code_in AND CPC_CARD_TYPE= p_card_type_in AND
             CBP_INST_CODE = p_inst_code_in AND CBP_PARAM_NAME = 'Currency';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
         p_err_msg_out   := 'Currency code is  not specified for the Product' ||
                    p_prod_code_in;
         return;
        WHEN OTHERS THEN
         p_err_msg_out   := 'Error While selecting the Currency code' ||
                    SUBSTR(SQLERRM, 1, 200);
         return;
      end;
    exception
        when others then
            p_err_msg_out:='Error from get_currency_code procedure'||substr(sqlerrm,1,200);
    end;
PROCEDURE get_expiry_date(
    p_inst_code_in number,
    p_prod_code_in    VARCHAR2,
    p_card_type_in    NUMBER,
    p_profile_code_in VARCHAR2,
    p_expiry_date_out OUT DATE,
    p_resp_msg_out OUT VARCHAR2)
as
V_EXPRYPARAM           CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
V_VALIDITY_PERIOD      CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
v_exp_date_exemption     cms_prod_cattype.cpc_exp_date_exemption%TYPE;
v_monthend_expry_date  CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
begin
p_resp_msg_out:='OK';
     BEGIN
    SELECT cpc_exp_date_exemption
     INTO v_exp_date_exemption
     FROM CMS_PROD_CATTYPE
    WHERE CPC_INST_CODE = p_inst_code_in
    and CPC_PROD_CODE = p_prod_code_in 
    AND CPC_CARD_TYPE = p_card_type_in;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       p_resp_msg_out := 'expiry date excemption not defined for product code ' ||
        p_prod_code_in || 'card type ' || p_card_type_in;
     return;
    WHEN OTHERS THEN
     p_resp_msg_out := 'Error while selecting applcode from applmast' ||
               SUBSTR(SQLERRM, 1, 300);
     return;
end;
    for loop_cur in (select cbp_param_value,cbp_param_name from CMS_BIN_PARAM
                 where cbp_profile_code=p_profile_code_in
                 and cbp_param_name in
                 ('Validity','Validity Period','MonthEnd CardExpiry Date')) 
    loop
         if loop_cur.cbp_param_name='Validity' then
              V_EXPRYPARAM:=loop_cur.cbp_param_value;
         elsif loop_cur.cbp_param_name='Validity Period' then
              V_VALIDITY_PERIOD:=loop_cur.cbp_param_value;
         elsif loop_cur.cbp_param_name='MonthEnd CardExpiry Date' then
                v_monthend_expry_date:=loop_cur.cbp_param_value;
         end if;
    end loop;

    IF V_EXPRYPARAM IS NULL THEN
       p_resp_msg_out := 'Validity is not defined for product profile ';
       return;
    end if;
    IF V_VALIDITY_PERIOD = 'Hour' THEN
      p_expiry_date_out := sysdate + V_EXPRYPARAM / 24;
    ELSIF V_VALIDITY_PERIOD = 'Day' THEN
       p_expiry_date_out := sysdate + V_EXPRYPARAM;
    ELSIF V_VALIDITY_PERIOD = 'Week' THEN
        p_expiry_date_out := sysdate + (7 * V_EXPRYPARAM);
    ELSIF V_VALIDITY_PERIOD = 'Month' THEN
     -- if v_monthend_expry_date='Y' then
          p_expiry_date_out := LAST_DAY(ADD_MONTHS(SYSDATE, V_EXPRYPARAM));  --VMS-8532 changes to consider the month-end expiry by default.
      --else
        --  p_expiry_date_out := ADD_MONTHS(SYSDATE, V_EXPRYPARAM);
      --end if;
    ELSIF V_VALIDITY_PERIOD = 'Year' THEN
     --if v_monthend_expry_date='Y' then
          p_expiry_date_out := LAST_DAY(ADD_MONTHS(sysdate, (12 * V_EXPRYPARAM) - 1)); --VMS-8532 changes to consider the month-end expiry by default.
     --else
       --  p_expiry_date_out := ADD_MONTHS(sysdate, (12 * V_EXPRYPARAM) - 1);
      --end if;
    END IF;
    dbms_output.put_line(p_expiry_date_out);
      if v_exp_date_exemption='Y' then
            BEGIN
                        SELECT add_months(p_expiry_date_out,vem_month_value)
                        INTO p_expiry_date_out
                        FROM vms_expiry_mast
                        WHERE  vem_month_id=to_char(p_expiry_date_out,'mm')
                        and vem_prod_code=p_prod_code_in
                        and vem_prod_cattype=p_card_type_in;
                    exception
                        WHEN no_data_found THEN
                            p_expiry_date_out := p_expiry_date_out;
                        WHEN others THEN
                            p_resp_msg_out :='Error while selecting the value from vms_expiry_mast '|| SQLERRM;
                            return;
                    END;
      end if;
exception
    when others then
         p_resp_msg_out := 'Error in vmsfunutilities.get_expiry_date'||
               SUBSTR(SQLERRM, 1, 300);
end;

PROCEDURE get_expiry_date (p_inst_code_in          NUMBER,
                           p_prod_code_in          VARCHAR2,
                           p_card_type_in          NUMBER,
                           p_profile_code_in       VARCHAR2,
                           p_qntity_in             NUMBER,
                           p_expiry_date_out   OUT expry_array_typ,
                           p_resp_msg_out      OUT VARCHAR2)
AS
    v_expryparam            cms_bin_param.cbp_param_value%TYPE;
    v_validity_period       cms_bin_param.cbp_param_value%TYPE;
    v_monthend_expry_date   cms_bin_param.cbp_param_value%TYPE;
    v_randm_val             NUMBER (10);
    v_expry_dt              DATE;
BEGIN
    p_resp_msg_out := 'OK';

    FOR loop_cur
        IN (SELECT cbp_param_value, cbp_param_name
              FROM cms_bin_param
             WHERE     cbp_profile_code = p_profile_code_in
                   AND cbp_param_name IN
                           ('Validity',
                            'Validity Period',
                            'MonthEnd CardExpiry Date'))
    LOOP
        IF loop_cur.cbp_param_name = 'Validity'
        THEN
            v_expryparam := loop_cur.cbp_param_value;
        ELSIF loop_cur.cbp_param_name = 'Validity Period'
        THEN
            v_validity_period := loop_cur.cbp_param_value;
        ELSIF loop_cur.cbp_param_name = 'MonthEnd CardExpiry Date'
        THEN
            v_monthend_expry_date := loop_cur.cbp_param_value;
        END IF;
    END LOOP;

    IF v_expryparam IS NULL
    THEN
        p_resp_msg_out := 'Validity is not defined for product profile ';
        RETURN;
    END IF;

    IF v_validity_period = 'Hour'
    THEN
        v_expry_dt := SYSDATE + v_expryparam / 24;
    ELSIF v_validity_period = 'Day'
    THEN
        v_expry_dt := SYSDATE + v_expryparam;
    ELSIF v_validity_period = 'Week'
    THEN
        v_expry_dt := SYSDATE + (7 * v_expryparam);
    ELSIF v_validity_period = 'Month'
    THEN
        v_expry_dt := ADD_MONTHS (SYSDATE, v_expryparam);
    ELSIF v_validity_period = 'Year'
    THEN
        v_expry_dt := ADD_MONTHS (SYSDATE, (12 * v_expryparam) - 1);
    END IF;

     BEGIN
        SELECT NVL (VSCM.VSC_SALES_CHANNEL_MONTH,0)
        INTO v_randm_val
            FROM VMSCMS.VMS_SALES_CHANNEL_MASTER VSCM
                JOIN VMSCMS.CMS_PROD_CATTYPE CPC
           ON VSCM.VSC_SALES_CHANNEL_NAME = CPC.CPC_SALES_CHANNEL
           AND CPC.CPC_INST_CODE = p_inst_code_in
           AND CPC.CPC_PROD_CODE = P_PROD_CODE_IN
           AND CPC.CPC_CARD_TYPE = P_CARD_TYPE_IN;
    EXCEPTION
        WHEN OTHERS THEN
            v_randm_val := 0;
    END;


    IF v_randm_val = 0 THEN
    BEGIN
        SELECT NVL (cim_exprydt_random, 0)
          INTO v_randm_val
          FROM cms_interchange_mast, cms_prod_mast
         WHERE cpm_inst_code = p_inst_code_in
           AND cpm_prod_code = p_prod_code_in
           AND cim_inst_code = cpm_inst_code
           AND cim_interchange_code = cpm_interchange_code;
    EXCEPTION
        WHEN OTHERS THEN
            v_randm_val := 0;
    END;
    END IF;
    
    IF v_randm_val = 0 THEN
        BEGIN
            SELECT TO_NUMBER (cip_param_value)
              INTO v_randm_val
              FROM cms_inst_param
             WHERE cip_inst_code = p_inst_code_in
               AND cip_param_key = 'EXPIRY_DATE_RANDOM';
        EXCEPTION
            WHEN OTHERS
            THEN
                v_randm_val := 60;
        END;
    END IF;

    SELECT CEIL ((v_randm_val / 12) * 365) AS days INTO v_randm_val FROM DUAL;

    SELECT /*CASE
               WHEN v_monthend_expry_date = 'Y' THEN LAST_DAY (dt)
               ELSE dt
           END*/
           LAST_DAY (dt) --VMS-8532 changes to consider the month-end expiry by default.
      BULK COLLECT INTO p_expiry_date_out
      FROM (    SELECT v_expry_dt + TRUNC (DBMS_RANDOM.VALUE (1, v_randm_val))    dt
                  FROM DUAL
            CONNECT BY LEVEL <= p_qntity_in);
EXCEPTION
    WHEN OTHERS
    THEN
        p_resp_msg_out :='Error in vmsfunutilities.get_expiry_date'|| SUBSTR (SQLERRM, 1, 300);
END;

end;
/
show error