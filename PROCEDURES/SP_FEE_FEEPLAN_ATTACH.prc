CREATE OR REPLACE PROCEDURE        VMSCMS.SP_FEE_FEEPLAN_ATTACH (
                        p_instcode   IN       NUMBER,
                        p_feeplan        IN       NUMBER,
                        p_fee            IN       NUMBER,
                        p_user            IN       NUMBER,
                        p_errmsg     OUT      VARCHAR)AS

v_count          NUMBER;
v_freq           cms_fee_types.cft_fee_freq%type;
v_chkflag        VARCHAR (10);
v_tran_code      cms_fee_mast.cfm_tran_code%type;
v_del_chn        cms_fee_mast.cfm_delivery_channel%type;
v_tran_type      cms_fee_mast.cfm_tran_type%type;
v_tran_mode      cms_fee_mast.cfm_tran_mode%type;
v_int_ind        cms_fee_mast.cfm_intl_indicator%type;
v_status         cms_fee_mast.cfm_approve_status%type;
v_pin_sign       cms_fee_mast.cfm_pin_sign%type;
v_rev_flag       cms_fee_mast.cfm_normal_rvsl%type;
v_merc_code      cms_fee_mast.cfm_merc_code%type;     
e_exp            EXCEPTION;
v_fee_type       cms_fee_types.cft_fee_type%type;
/*************************************************
     * Created By     :  Ramkumar
     * Created Date   :  20-June-2012
     * Modified by    : Deepa T
     * Date           : 25-Sep-2012 
         * Purpose  :   To attach the Fees with Particular MCCode and ALL in the same FeePlan
    * Reviewer         : Saravanakumar.
      * Reviewed Date    : 15-Oct-2012
      * Build Number     :  CMS3.5.1_RI0020_B0001
     * Modified By      : Abdul Hameed M.A 
     * Modified Date    : 30-APR-2015
     * Modified for     : Logging user details in the table
     * Reviewer         : Spankaj
     * Release Number   : VMSGPRHOSTCSD_3.0.1_B003

 *************************************************/

BEGIN
    p_errmsg := 'OK';

    BEGIN
        SELECT cft_fee_freq,cft_fee_type
        INTO v_freq,v_fee_type
        FROM cms_fee_types
        WHERE cft_feetype_code = (SELECT cfm_feetype_code FROM cms_fee_mast  WHERE cfm_fee_code = p_fee);
    EXCEPTION
        WHEN NO_DATA_FOUND   THEN
            p_errmsg := 'Data not available in cms_fee_types for feecode' || p_fee;
            RAISE e_exp;
        WHEN OTHERS  THEN
            p_errmsg :=  'Error while selecting from cms_fee_types' || SUBSTR (SQLERRM, 1, 200);
             RAISE e_exp;
    END;

 
    SELECT COUNT (*)
    INTO v_count
    FROM cms_fee_feeplan
    WHERE cff_fee_plan = p_feeplan;
 
    IF v_count = 0   THEN
        v_chkflag:='OK';
    ELSE
        if v_freq ='R' then
          
          BEGIN
            SELECT CFM_TRAN_CODE into v_tran_code FROM CMS_FEE_MAST 
            WHERE cfm_fee_code =p_fee;
          EXCEPTION
           WHEN NO_DATA_FOUND   THEN
            p_errmsg :=    'Data not available in CMS_FEE_MAST for CFM_TRAN_CODE block1' || p_fee;
             RAISE e_exp;
           WHEN OTHERS   THEN
            p_errmsg :=    'Error while selecting from CMS_FEE_MAST block1' || SUBSTR (SQLERRM, 1, 200);
             RAISE e_exp;
          END;
          
            SELECT COUNT (*)
            INTO v_count
            FROM cms_fee_mast
            WHERE cfm_fee_code IN ( SELECT cff_fee_code FROM cms_fee_feeplan WHERE cff_fee_plan = p_feeplan)
            AND cfM_feetype_code = (SELECT cfm_feetype_code FROM cms_fee_mast  WHERE cfm_fee_code = p_fee)
            AND CFM_TRAN_CODE=v_tran_code;
            
        elsif v_freq ='T' then
           
           BEGIN
            select CFM_DELIVERY_CHANNEL,CFM_TRAN_TYPE,CFM_TRAN_CODE,CFM_TRAN_MODE,CFM_INTL_INDICATOR,CFM_APPROVE_STATUS, CFM_PIN_SIGN,CFM_NORMAL_RVSL,CFM_MERC_CODE
            into v_del_chn ,v_tran_type, v_tran_code, v_tran_mode, v_int_ind, v_status, v_pin_sign,v_rev_flag,v_merc_code from cms_fee_mast 
            where CFM_FEE_CODE=p_fee;
           EXCEPTION
            WHEN NO_DATA_FOUND   THEN
             p_errmsg :=    'Data not available in CMS_FEE_MAST for block2'|| p_fee;
              RAISE e_exp;
            WHEN OTHERS   THEN
             p_errmsg :=    'Error while selecting from CMS_FEE_MAST for block2' || SUBSTR (SQLERRM, 1, 200);
              RAISE e_exp;
           END;
           --Modified by Ramkumar.Mk on 24 Aug 2012, check the Novmal reversal
            select count(1) INTO v_count from cms_fee_mast where
            (nvl(CFM_DELIVERY_CHANNEL, ' ')=nvl(v_del_chn, ' ') or nvl(CFM_DELIVERY_CHANNEL, ' ')='A' or nvl(v_del_chn, ' ')='A')
            and (nvl(CFM_TRAN_TYPE, ' ')=nvl(v_tran_type, ' ') or nvl(CFM_TRAN_TYPE, ' ')='A'  or nvl(v_tran_type, ' ')='A')
            and (nvl(CFM_TRAN_CODE, ' ')=nvl(v_tran_code, ' ') or nvl(CFM_TRAN_CODE, ' ')='A' or nvl(v_tran_code, ' ')='A')
            --and (nvl(CFM_TRAN_MODE, ' ')=nvl(v_tran_mode, ' ') or nvl(CFM_TRAN_MODE, ' ')='A' or nvl(v_tran_mode, ' ')='A')
            and (nvl(CFM_INTL_INDICATOR, ' ')=nvl(v_int_ind, ' ') or nvl(CFM_INTL_INDICATOR, ' ')='A' or nvl(v_int_ind, ' ')='A')
            and (nvl(CFM_APPROVE_STATUS, ' ')=nvl(v_status, ' ') or nvl(CFM_APPROVE_STATUS, ' ')='A' or nvl(v_status, ' ')='A')
            and (nvl(CFM_PIN_SIGN, ' ')=nvl(v_pin_sign, ' ') or nvl(CFM_PIN_SIGN, ' ')='A' or nvl(v_pin_sign, ' ')='A')
            and (CFM_NORMAL_RVSL=v_rev_flag or CFM_NORMAL_RVSL is null)
            and (CFM_NORMAL_RVSL='R' OR ((CFM_NORMAL_RVSL='N' or CFM_NORMAL_RVSL is null )AND  (nvl(CFM_TRAN_MODE, ' ')=nvl(v_tran_mode, ' ') or nvl(CFM_TRAN_MODE, ' ')='A' or nvl(v_tran_mode, ' ')='A')))
            --Added by Ramkumar.MK on 17 Sep 2012, Added the condition for Merchant Category
            --and (nvl(CFM_MERC_CODE, ' ')=nvl(v_merc_code, ' ') or nvl(cfm_merc_code, ' ')='A' or nvl(v_merc_code, ' ')='A') 
            and nvl(CFM_MERC_CODE, ' ')=nvl(v_merc_code, ' ') --Modified by Deepa on 25-Sep-2012 to attach the Fees with Particular MCCode and ALL in the same FeePlan
            and CFM_FEE_CODE in  (SELECT cff_fee_code FROM cms_fee_feeplan WHERE cff_fee_plan = p_feeplan);
            
         else
            select count(1)  INTO v_count FROM cms_fee_types
            WHERE cft_feetype_code in
            (SELECT cfm_feetype_code FROM cms_fee_mast  WHERE cfm_fee_code in
            (select cff_fee_code  FROM cms_fee_feeplan WHERE cff_fee_plan = p_feeplan))
            and decode(v_freq,'M',decode(cft_fee_type,v_fee_type,'OK'),'OK')='OK'
            and CFT_FEE_FREQ=v_freq ;       
         END IF;
     END IF;
         
        IF v_count = 0 THEN
            v_chkflag:='OK';
        ELSE
            v_chkflag:='NOT OK';
            p_errmsg:='Fee already attached';
        END IF;

       if v_chkflag = 'OK' then    
           BEGIN
            INSERT INTO cms_fee_feeplan (cff_fee_code, cff_fee_plan, cff_inst_code, cff_fee_freq,CFF_INS_USER,CFF_LUPD_USER )
            VALUES (p_fee, p_feeplan, p_instcode, v_freq, p_user,p_user );
           EXCEPTION
            WHEN OTHERS THEN
            p_errmsg :=    'Error while inserting in to cms_fee_feeplan ' || SUBSTR (SQLERRM, 1, 200);
             RAISE e_exp;
           END;
       end if;
       

EXCEPTION
  WHEN e_exp THEN
     NULL;
  WHEN OTHERS THEN
    p_errmsg := 'Error from main exception block' || SUBSTR (SQLERRM, 1, 200);
END; 
/
SHOW ERROR;