CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Appl_pcms (
   instcode      IN       NUMBER,
   assocode      IN       NUMBER,
   insttype      IN       NUMBER,
   applno        IN       VARCHAR2,
   appldate      IN       DATE,
   regdate       IN       DATE,
   custcode      IN       NUMBER,
   applbran      IN       VARCHAR2,
   prodcode      IN       VARCHAR2,
   cardtype      IN       NUMBER,
   custcatg      IN       NUMBER,
   activedate    IN       DATE,
   exprydate     IN       DATE,
   dispname      IN       VARCHAR2,
   limtamt       IN       NUMBER,
   addonissu     IN       CHAR,
   usagelimt     IN       NUMBER,
   totacct       IN       NUMBER,
   addonstat     IN       CHAR,
   addonlink     IN       NUMBER,
   billaddr      IN       NUMBER,
   chnlcode      IN       NUMBER,
   request_id    IN       VARCHAR2,
   payment_ref   IN       VARCHAR2,
   appluser      IN       NUMBER,
   lupduser      IN       NUMBER,
   prm_initial_topup_amount		 IN NUMBER,
   applcode      OUT      NUMBER,
   errmsg        OUT      VARCHAR2
)
AS
    /****************************************************************
     * VERSION               : 1.0
     * DATE OF CREATION      :
     * CREATED BY            :
     * PURPOSE               : Log error messages for process failures
     * MODIFICATION REASON   :
     *
     *
     * LAST MODIFICATION DONE BY : Chandrashekar Gurram.
     * LAST MODIFICATION DATE    : 18/Feb/2006
	 
     
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
   *********************************************************************/

   trueaddonlink     NUMBER (20);
 

   v_appl_stat       CMS_APPL_MAST.cam_appl_stat%TYPE;
   v_pay_ref         CMS_APPL_MAST.cam_payment_ref%TYPE;
   v_host_proc		 CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
   v_encrypt_enable  cms_prod_cattype.cpc_encrypt_enable%TYPE;
   v_encr_disp_name  cms_appl_mast.cam_disp_name%type;
BEGIN                                           --Main Begin Block Starts Here
   --
   --
   -- SN Shekar 18.Feb.06, error handler modified for pcms
 

 
 BEGIN
 
  SELECT    TO_CHAR (SYSDATE, 'yyyymm')

             || LPAD (seq_appl_code.NEXTVAL, 8, 0)
        INTO applcode
        FROM DUAL;
		
  EXCEPTION
            WHEN OTHERS THEN
                errmsg := 'Error while Generating Applcode'||SQLERRM;
                RETURN;
   END;

   IF addonstat = 'P' AND addonlink = 0
   THEN                                                                 --IF 2
      trueaddonlink := applcode;
   ELSIF addonstat IN ('A', 'B') AND addonlink IS NOT NULL
   THEN                                                                 --IF 2 
     trueaddonlink := addonlink;
  
   END IF;                                                       --End of IF 2

    

   v_appl_stat := 'A';
  
    BEGIN
	   SELECT cpc_encrypt_enable 
	   INTO v_encrypt_enable 
	   FROM cms_prod_cattype 
	   WHERE cpc_inst_code = instcode
	   AND cpc_prod_code = prodcode
	   AND cpc_card_type = cardtype;
   
   EXCEPTION
   WHEN NO_DATA_FOUND
      THEN
         errmsg := ' no data found for prod code: ' || prodcode;
         RETURN;
      WHEN OTHERS
      THEN
         errmsg := 'when others: ' || SQLERRM;
         RETURN;
   END;
   
   IF v_encrypt_enable = 'Y' THEN
       v_encr_disp_name := fn_emaps_main(dispname);
   ELSE
       v_encr_disp_name :=  dispname;
   END IF;	   


   INSERT INTO CMS_APPL_MAST
               (cam_inst_code, cam_asso_code, cam_inst_type, cam_appl_code,
                cam_appl_no, cam_appl_date, cam_reg_date, cam_cust_code,
                cam_appl_bran, cam_prod_code, cam_card_type, cam_cust_catg,
                cam_active_date, cam_expry_date, cam_disp_name,
                cam_limit_amt,
                              --to be removed once limits structure is defined
                              cam_use_limit,
                              --to be removed once limits structure is defined
                                            cam_addon_issu, cam_tot_acct,
                cam_addon_stat, cam_addon_link, cam_bill_addr, cam_chnl_code,
                cam_request_id, cam_payment_ref, cam_appl_stat,
                cam_appl_user, cam_initial_topup_amount , cam_lupd_user,CAM_INS_DATE, CAM_INS_USER 
               )
        VALUES (instcode, assocode, insttype, applcode,
                applno, appldate, regdate, custcode,
                applbran, prodcode, cardtype, custcatg,
                activedate, LAST_DAY (exprydate), v_encr_disp_name,
                limtamt, usagelimt, addonissu, totacct,
                addonstat, trueaddonlink, billaddr, chnlcode,
                request_id, payment_ref, v_appl_stat,
                appluser,prm_initial_topup_amount, lupduser,sysdate,lupduser
               );

  
   errmsg := 'OK';
--ELSE   --else of IF 1
-- errmsg := 'sp_create_appl expected a not null parameter';
--END IF;   --End  of IF 1
EXCEPTION                                               --Main block Exception
   WHEN OTHERS
   THEN
   	 
      errmsg := 'Main Exception ' || SQLCODE || '---' || SQLERRM ;
END;                                              --Main Begin Block Ends Here
/
show error