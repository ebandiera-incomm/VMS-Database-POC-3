create or replace
PROCEDURE       vmscms.Sp_Create_Bulk_Appl(p_instcode  IN	NUMBER	,
                                                p_assocode	IN	NUMBER	,
                                                p_insttype	IN	NUMBER	,
                                                p_applno	IN	VARCHAR2,
                                                p_appldate	IN	DATE,
                                                p_regdate	IN	DATE	,
                                                p_custcode	IN	NUMBER	,
                                                p_applbran	IN	VARCHAR2,
                                                p_prodcode	IN	VARCHAR2,
                                                p_cardtype	IN	NUMBER	,
                                                p_custcatg	IN	NUMBER	,
                                                p_activedate	IN	DATE	,
                                                p_exprydate	IN	DATE	,
                                                p_dispname	IN	VARCHAR2,
                                                p_limtamt	IN	NUMBER	,
                                                p_addonissu	IN	CHAR	,
                                                p_usagelimt	IN	NUMBER	,
                                                p_totacct	IN	NUMBER	,
                                                p_addonstat	IN	CHAR	,
                                                p_addonlink	IN	NUMBER	,
                                                p_billaddr	IN	NUMBER	,
                                                p_chnlcode	IN	NUMBER	,
                                                p_appluser	IN	NUMBER	,
                                                p_lupduser	IN	NUMBER	,
                                                p_ikit_flag	IN	CMS_APPL_MAST.cam_ikit_flag%type,
                                                p_filename     	IN      VARCHAR2,
                                                p_startercard   IN      VARCHAR2,  -- Added By Sivapragasam on Feb 20 2012 for Starter card
                                                p_applcode	OUT	NUMBER	,
                                                p_errmsg	OUT	VARCHAR2)
AS
/*************************************************
     * Created Date     :  10-Dec-2011
     * Created By       :  Sivapragasam
     * PURPOSE          :  For Bulk upload
     * Modified By      :  Sivapragasam
     * Modified Date    :  20-Feb-2012
     * Modified Reason  :  startercard
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  27_Feb-2012
     * Build Number     : RI0004
	 
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

 *************************************************/
v_trueaddonlink	NUMBER (20);

v_cam_bill_addr	CMS_APPL_PAN.cap_bill_addr%TYPE;
v_encrypt_enable cms_prod_cattype.cpc_encrypt_enable%type;
v_encr_disp_name cms_appl_mast.cam_disp_name%type;

BEGIN		--Main Begin Block Starts Here



  
  BEGIN
  
   SELECT	TO_CHAR(SYSDATE,'yyyymm')
                ||LPAD(seq_appl_code.NEXTVAL,8,0)
            INTO	p_applcode
            FROM	dual ;
  EXCEPTION
            WHEN OTHERS THEN
                p_errmsg := 'Error while Generating Appl code '||SQLERRM;
                RETURN;
   END;
    
    IF p_addonstat = 'P' AND p_addonlink = 0 THEN
       
            v_trueaddonlink := p_applcode;
        
    ELSIF p_addonstat IN( 'A','B' ) AND p_addonlink IS NOT NULL THEN
      
            v_trueaddonlink := p_addonlink ;
			
    END IF;

    IF p_addonstat = 'A' THEN
        SELECT cam_bill_addr
        INTO	v_cam_bill_addr
        FROM	CMS_APPL_MAST
        WHERE	cam_appl_code = p_addonlink;
    ELSE
        v_cam_bill_addr := p_billaddr;
    END IF;
	
	  BEGIN
	   SELECT cpc_encrypt_enable 
	   INTO v_encrypt_enable 
	   FROM cms_prod_cattype 
	   WHERE cpc_inst_code = p_instcode
	   AND cpc_prod_code = p_prodcode
	   AND cpc_card_type = p_cardtype;
   
   EXCEPTION
   WHEN NO_DATA_FOUND
      THEN
         p_errmsg := ' no data found for prod code: ' || p_prodcode;
         RETURN;
      WHEN OTHERS
      THEN
         p_errmsg := 'when others: ' || SQLERRM;
         RETURN;
   END;
   
   IF v_encrypt_enable = 'Y' THEN
       v_encr_disp_name := fn_emaps_main(p_dispname);
   ELSE
       v_encr_disp_name :=  p_dispname;
   END IF;	 
	
    BEGIN
        INSERT INTO CMS_APPL_MAST
                  (	CAM_INST_CODE	,
                  CAM_ASSO_CODE	,
                  CAM_INST_TYPE	,
                  CAM_APPL_CODE      ,
                  CAM_APPL_NO	,
                  CAM_APPL_DATE      ,
                  CAM_REG_DATE	,
                  CAM_CUST_CODE	,
                  CAM_APPL_BRAN	,
                  CAM_PROD_CODE	,
                  CAM_CARD_TYPE	,
                  CAM_CUST_CATG	,
                  CAM_ACTIVE_DATE	,
                  CAM_EXPRY_DATE	,
                  CAM_DISP_NAME	,
                  CAM_LIMIT_AMT	,--to be removed once limits structure is defined
                  CAM_USE_LIMIT	,--to be removed once limits structure is defined
                  CAM_ADDON_ISSU	,
                  CAM_TOT_ACCT	,
                  CAM_ADDON_STAT	,
                  CAM_ADDON_LINK	,
                  CAM_BILL_ADDR	,
                  CAM_CHNL_CODE	,
                  CAM_APPL_USER	,
                  CAM_FILE_NAME	,
                  CAM_LUPD_USER ,
                  CAM_IKIT_FLAG,
                  CAM_STARTER_CARD)        -- Added By Sivapragasam on Feb 20 2012 for Starter card
                  VALUES(	p_instcode	,
                  p_assocode	,
                  p_insttype	,
                  p_applcode	,
                  p_applno		,
                  p_appldate	,
                  p_regdate		,
                  p_custcode	,
                  p_applbran	,
                  p_prodcode	,
                  p_cardtype	,
                  p_custcatg	,
                  p_activedate	,
                  LAST_DAY(p_exprydate),
                  v_encr_disp_name	,
                  p_limtamt		,
                  p_usagelimt	,
                  p_addonissu	,
                  p_totacct		,
                  p_addonstat	,
                  v_trueaddonlink	,
                  v_cam_bill_addr	,
                  p_chnlcode	,
                  p_appluser	,
                  p_filename	,
                  p_lupduser,
                  p_ikit_flag,
                  p_startercard);    -- Added By Sivapragasam on Feb 20 2012 for Starter card
    EXCEPTION
        WHEN OTHERS THEN
            p_errmsg := 'Error while inserting CMS_APPL_MAST '||SQLERRM;
            RETURN;
    END;
    p_errmsg := 'OK';
EXCEPTION
    WHEN OTHERS THEN
        p_errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;
/
show error