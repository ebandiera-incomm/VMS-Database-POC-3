CREATE OR REPLACE PROCEDURE VMSCMS.lp_calc_on_pccc(calcdate IN DATE,lperr1  OUT VARCHAR2)
AS
CURSOR lp1c1 IS
--Pick up the rows from the 3rd level of fees where the calculation date lies between from and to date for the fee
 SELECT cpf_prod_code,
  cpf_card_type,
  cpf_cust_catg,
  cpf_fee_code
 FROM CMS_PRODCCC_FEES
 WHERE cpf_inst_code = instcode
 AND calcdate >= cpf_valid_from
 AND calcdate <= cpf_valid_to
 ORDER BY cpf_prod_code,
  cpf_card_type,
  cpf_cust_catg,
  cpf_fee_code;
BEGIN  --begin lp1
dbms_output.put_line('lp_calc_pccc level5');
  lperr1 := 'OK';
  FOR x IN lp1c1
  LOOP
 IF lperr1 != 'OK' THEN
  EXIT;
 END IF;
 SELECT  cfm_fee_amt,
  cft_fee_freq
 INTO v_cfm_fee_amt,
  v_cfm_fee_freq
 FROM CMS_FEE_MAST,
  CMS_FEE_TYPES
 WHERE cft_inst_code = cfm_inst_code
 AND  cft_feetype_code = cfm_feetype_code
 AND  cfm_inst_code = instcode
 AND  cfm_fee_code = x.cpf_fee_code;
 dbms_output.put_line('lp_calc_pccc level6 frequency '||v_cfm_fee_freq);
/* Changed by PANKAJ on 26.07.2005 With above query
 SELECT  cfm_fee_amt
 INTO v_cfm_fee_amt
 FROM cms_fee_mast
 WHERE cfm_inst_code = instcode
 AND cfm_fee_code = x.cpf_fee_code;
*/
 BEGIN     --begin lp1.1
  SELECT cpw_waiv_prcnt
  INTO v_cpw_waiv_prcnt
  FROM CMS_PRODCCC_WAIV
  WHERE cpw_inst_code = instcode
  AND cpw_prod_code = x.cpf_prod_code
  AND cpw_card_type = x.cpf_card_type
  AND cpw_cust_catg = x.cpf_cust_catg
  AND cpw_fee_code = x.cpf_fee_code
  AND calcdate >= cpw_valid_from AND calcdate <= cpw_valid_to;
  waivamt := ( v_cpw_waiv_prcnt / 100 ) * v_cfm_fee_amt;
  lperr1 := 'OK';
 EXCEPTION --excp of --begin lp1.1
  WHEN NO_DATA_FOUND THEN
   waivamt  := 0;
  WHEN OTHERS THEN
   lperr1 := 'Excp Lp1.1 -- '||SQLERRM;
 END; --end of --begin lp1.1
 IF lperr1 = 'OK' THEN
  feeamt := v_cfm_fee_amt - waivamt;
 END IF;
 --this is the fee amount for the PCCC level, now attach this amount to all the cards falling under the present PCCC level
 IF lperr1 = 'OK' THEN
  IF v_cfm_fee_freq = 'O' THEN
   lp_attchfee_for_once(x.cpf_prod_code,x.cpf_card_type,x.cpf_cust_catg,x.cpf_fee_code,calcdate,mesg);
   IF mesg != 'OK' THEN
    lperr1 := 'From lp_attachfee_for_once -'||mesg;
   END IF;
  ELSIF v_cfm_fee_freq = 'A' THEN
     dbms_output.put_line('b4 lp_attchfee_for_annual');
   lp_attchfee_for_annual(x.cpf_prod_code,x.cpf_card_type,x.cpf_cust_catg,x.cpf_fee_code,calcdate,mesg);
   dbms_output.put_line('after lp_attchfee_for_annual' || mesg);
   IF mesg != 'OK' THEN
    lperr1 := 'From lp_attchfee_for_annual - '||mesg;
   END IF;
  END IF;
 END IF;
/* CHANGED BY PANkAJ WITH ABOVE CNSTRUCT ON 26.07.2005
 IF lperr1 = 'OK' THEN
  lp_attchfee_for_once(x.cpf_prod_code,x.cpf_card_type,x.cpf_cust_catg,x.cpf_fee_code,calcdate,mesg)  ;
  IF mesg != 'OK' THEN
   lperr1 := 'From lp_attachfee_for_once -'||mesg;
  END IF;
 END IF;
 IF lperr1 = 'OK' THEN
  lp_attchfee_for_annual(x.cpf_prod_code,x.cpf_card_type,x.cpf_cust_catg,x.cpf_fee_code,calcdate,mesg)  ;
  IF mesg != 'OK' THEN
   lperr1 := 'From lp_attchfee_for_annual - '||mesg;
  END IF;
 END IF;
*/
 EXIT WHEN lp1c1%NOTFOUND;
END LOOP;
EXCEPTION --main excp in lp1
 WHEN STOP_PROC THEN
  RAISE;
 WHEN OTHERS THEN
  lperr1 := 'Main Excp lp1 --'||SQLERRM;
END;  --end lp1
/


