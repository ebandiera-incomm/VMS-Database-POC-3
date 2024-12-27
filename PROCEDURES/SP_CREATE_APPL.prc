create or replace
PROCEDURE     VMSCMS.sp_create_appl (
   prm_instcode               IN       NUMBER,
   prm_assocode               IN       NUMBER,
   prm_insttype               IN       NUMBER,
   prm_applno                 IN       VARCHAR2,
   prm_appldate               IN       DATE,
   prm_regdate                IN       DATE,
   prm_custcode               IN       NUMBER,
   prm_applbran               IN       VARCHAR2,
   prm_prodcode               IN       VARCHAR2,
   prm_cardtype               IN       NUMBER,
   prm_custcatg               IN       NUMBER,
   prm_activedate             IN       DATE,
   prm_exprydate              IN       DATE,
   prm_dispname               IN       VARCHAR2,
   prm_limtamt                IN       NUMBER,
   prm_addonissu              IN       CHAR,
   prm_usagelimt              IN       NUMBER,
   prm_totacct                IN       NUMBER,
   prm_addonstat              IN       CHAR,
   prm_addonlink              IN       NUMBER,
   prm_billaddr               IN       NUMBER,
   prm_chnlcode               IN       NUMBER,
   prm_request_id             IN       VARCHAR2,
   prm_payment_ref            IN       VARCHAR2,
   prm_appluser               IN       NUMBER,
   prm_lupduser               IN       NUMBER,
   prm_appl_stat              IN       VARCHAR2,
   prm_initial_topup_amount   IN       NUMBER,
   prm_ikit_flag              IN       VARCHAR2,
   prm_genappl_data           IN       type_appl_rec_array,
   prm_applcode               OUT      NUMBER,
   prm_errmsg                 OUT      VARCHAR2
)
AS
   trueaddonlink       NUMBER (20);
   v_appl_stat         cms_appl_mast.cam_appl_stat%TYPE;
   v_pay_ref           cms_appl_mast.cam_payment_ref%TYPE;
   v_host_proc         cms_inst_param.cip_param_value%TYPE;
   v_applrec_outdata   type_appl_rec_array;
   v_appldata_errmsg   VARCHAR2 (300);
   v_encrypt_enable    cms_prod_cattype.cpc_encrypt_enable%type;
   v_encr_disp_name    cms_appl_mast.cam_disp_name%type;
   
/*********************************************************   
   	 * Modified By      :  Sreeja D
     * Modified Date    :  05-Feb-2018
     * Modified Reason  :  VMS-162
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  05_Feb-2018
     * Build Number     :  FEB_VMSGPRHOST_18.1_RELEASE - B0008
     
     * Modified By      :  Ubaidur Rahman.H
     * Modified Date    :  16-Dec-2020
     * Modified Reason  :  VMS-2880 - Applcode generation logic needs to be changed - 
     				to be changed with current year and month instead of
				 catg code value.
     * Reviewer         :  Puvanesh/Saravanakumar
     * Build Number     :  VMSGPRHOST_R40_RELEASE

 **********************************************************/
BEGIN


  
  BEGIN
  
  SELECT    TO_CHAR (SYSDATE, 'yyyymm')
             || LPAD (seq_appl_code.NEXTVAL, 8, 0)
        INTO prm_applcode
        FROM DUAL;

 EXCEPTION
            WHEN OTHERS THEN
                prm_errmsg := 'Error while Generating Applcode'||SQLERRM;
                RETURN;
   END;
   
   IF prm_addonstat = 'P' AND prm_addonlink = 0
   THEN
      trueaddonlink := prm_applcode;
   ELSIF prm_addonstat IN ('A', 'B') AND prm_addonlink IS NOT NULL
   THEN
      trueaddonlink := prm_addonlink;
   END IF;


   sp_set_gen_appldata (prm_genappl_data, v_applrec_outdata,
                        v_appldata_errmsg);

   IF v_appldata_errmsg <> 'OK'
   THEN
      prm_errmsg := 'Error in set gen parameters   ' || v_appldata_errmsg;
      RETURN;
   END IF;

   BEGIN
	   SELECT cpc_encrypt_enable 
	   INTO v_encrypt_enable 
	   FROM cms_prod_cattype 
	   WHERE cpc_inst_code = prm_instcode
	   AND cpc_prod_code = prm_prodcode
	   AND cpc_card_type = prm_cardtype;
   
   EXCEPTION
   WHEN NO_DATA_FOUND
      THEN
         prm_errmsg := ' no data found for prod code: ' || prm_prodcode;
         RETURN;
      WHEN OTHERS
      THEN
         prm_errmsg := 'when others: ' || SQLERRM;
         RETURN;
   END;
   
   IF v_encrypt_enable = 'Y' THEN
       v_encr_disp_name := fn_emaps_main(prm_dispname);
   ELSE
       v_encr_disp_name :=  prm_dispname;
   END IF;	   


   INSERT INTO cms_appl_mast
               (cam_inst_code, cam_asso_code, cam_inst_type, cam_appl_code,
                cam_appl_no, cam_appl_date, cam_reg_date, cam_cust_code,
                cam_appl_bran, cam_prod_code, cam_card_type, cam_cust_catg,
                cam_active_date, cam_expry_date, cam_disp_name,
                cam_limit_amt, cam_use_limit, cam_addon_issu, cam_tot_acct,
                cam_addon_stat, cam_addon_link, cam_bill_addr, cam_chnl_code,
                cam_request_id, cam_payment_ref, cam_appl_stat,
                cam_appl_user, cam_initial_topup_amount, cam_lupd_user,
                cam_ins_date, cam_ins_user, cam_ikit_flag, cam_appl_param1,
                cam_appl_param2, cam_appl_param3,
                cam_appl_param4, cam_appl_param5,
                cam_appl_param6, cam_appl_param7,
                cam_appl_param8, cam_appl_param9,
                cam_appl_param10
               )
        VALUES (prm_instcode, prm_assocode, prm_insttype, prm_applcode,
                prm_applno, prm_appldate, prm_regdate, prm_custcode,
                prm_applbran, prm_prodcode, prm_cardtype, prm_custcatg,
                prm_activedate, LAST_DAY (prm_exprydate), v_encr_disp_name,
                prm_limtamt, prm_usagelimt, prm_addonissu, prm_totacct,
                prm_addonstat, trueaddonlink, prm_billaddr, prm_chnlcode,
                prm_request_id, prm_payment_ref, prm_appl_stat,
                prm_appluser, prm_initial_topup_amount, prm_lupduser,
                SYSDATE, prm_lupduser, prm_ikit_flag, v_applrec_outdata (1),
                v_applrec_outdata (2), v_applrec_outdata (3),
                v_applrec_outdata (4), v_applrec_outdata (5),
                v_applrec_outdata (6), v_applrec_outdata (7),
                v_applrec_outdata (8), v_applrec_outdata (9),
                v_applrec_outdata (10)
               );


   prm_errmsg := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
     
      prm_errmsg := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
END;
/
SHOW ERROR