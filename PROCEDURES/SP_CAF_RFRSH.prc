CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Caf_Rfrsh           (
                    instcode        IN        NUMBER    ,
                    pancode        IN        VARCHAR2    ,
                    mbrnumb        IN        VARCHAR2    ,
                    logdate        IN        DATE        ,
                    cafaction    IN        CHAR    ,---C,A,D
                    remark        IN        VARCHAR2    ,
                    spprtfunc    IN        VARCHAR2    ,
                    lupduser    IN        NUMBER    ,--just to satisfy the the --middle tier common function parameters, not used in this proc
             pancode_ENCR        IN        RAW    ,
                    errmsg        OUT        VARCHAR2    )

AS
--change history
--1CH070303 Anup add a condition for renewal of expired cards
dum                NUMBER(1)    ;
v_mbrnumb        VARCHAR2(3)    ;
v_ccb_cvv_value    VARCHAR2(3)    ;
v_ccb_service_code VARCHAR2(3)    ;
pinofst            VARCHAR2(16)    ;
acctcnt            NUMBER        ;
v_cam_acct_no CMS_ACCT_MAST.cam_acct_no%TYPE;
v_cat_switch_type VARCHAR2(2);
--for testing only
v_cas_switch_stat VARCHAR2(1);
--for testing only

-- Rahul 29 Aug 05
v_progress NUMBER(10):=1;


v_cci_rec_typ            CMS_CAF_INFO.cci_rec_typ%TYPE                ;
v_cardtype                CMS_CAF_INFO.cci_crd_typ%TYPE                ;
v_fiid                    CMS_CAF_INFO.cci_fiid%TYPE                    ;
v_cardstat                CMS_CAF_INFO.cci_crd_stat%TYPE                ;
v_pinofst                CMS_CAF_INFO.cci_pin_ofst%TYPE                ;
v_totwdllimit            CMS_CAF_INFO.cci_ttl_wdl_lmt%TYPE            ;
v_totoffwdllimit        CMS_CAF_INFO.cci_offl_wdl_lmt%TYPE            ;
v_totccalmt                CMS_CAF_INFO.cci_ttl_cca_lmt%TYPE            ;
v_totoffccalmt            CMS_CAF_INFO.cci_offl_cca_lmt%TYPE            ;
v_totaggrlmt            CMS_CAF_INFO.cci_aggr_lmt%TYPE            ;
v_totoffaddrlmt            CMS_CAF_INFO.cci_offl_aggr_lmt%TYPE            ;
v_firstusedate            CMS_CAF_INFO.cci_first_used_dat%TYPE        ;
v_lastresetdate            CMS_CAF_INFO.cci_last_reset_dat%TYPE        ;
v_expirydate            CMS_CAF_INFO.cci_exp_dat%TYPE                ;
v_userfld1                CMS_CAF_INFO.cci_user_fld1%TYPE            ;
v_alphakey                CMS_CAF_INFO.cci_card_alpha_key%TYPE        ;
v_vendor                CMS_CAF_INFO.cci_vendor%TYPE                ;
v_cardfiid                CMS_CAF_INFO.cci_crd_fiid%TYPE                ;
v_stock                    CMS_CAF_INFO.cci_stock%TYPE                ;
v_prefix                CMS_CAF_INFO.cci_prefix%TYPE                ;
v_seg1uselmt            CMS_CAF_INFO.cci_seg1_use_lmt%TYPE        ;
v_seg1ttlwdllmt            CMS_CAF_INFO.cci_seg1_ttl_wdl_lmt%TYPE        ;
v_seg1offlwdllmt        CMS_CAF_INFO.cci_seg1_offl_wdl_lmt%TYPE        ;
v_seg1ttlccawdllmt        CMS_CAF_INFO.cci_seg1_ttl_cca_lmt%TYPE        ;
v_seg1offlccawdllmt        CMS_CAF_INFO.cci_seg1_offl_cca_lmt%TYPE    ;
v_seg1depcrlmt            CMS_CAF_INFO.cci_seg1_dep_cr_lmt%TYPE        ;
v_seg1lastused            CMS_CAF_INFO.cci_seg1_last_used%TYPE        ;
v_segttlpurlmt            CMS_CAF_INFO.cci_seg_ttl_pur_lmt%TYPE        ;
v_segofflpurlmt            CMS_CAF_INFO.cci_seg_offl_pur_lmt%TYPE        ;
v_segttlccalmt            CMS_CAF_INFO.cci_seg_ttl_cca_lmt%TYPE        ;
v_segofflccalmt            CMS_CAF_INFO.cci_seg_offl_cca_lmt%TYPE        ;
v_segttlwdllmt            CMS_CAF_INFO.cci_seg_ttl_wdl_lmt%TYPE        ;
v_segofflwdllmt            CMS_CAF_INFO.cci_seg_offl_wdl_lmt%TYPE        ;
v_usefield                CMS_CAF_INFO.cci_seg_user_fld%TYPE            ;
v_seguselmt                CMS_CAF_INFO.cci_seg_use_lmt%TYPE            ;
v_segttlrfndcrlmt        CMS_CAF_INFO.cci_seg_ttl_rfnd_cr_lmt%TYPE    ;
v_segofflrfndcrlmt        CMS_CAF_INFO.cci_seg_offl_rfnd_cr_lmt%TYPE    ;
v_segrsncde                CMS_CAF_INFO.cci_seg_rsn_cde%TYPE            ;
v_seglastused            CMS_CAF_INFO.cci_seg_last_used%TYPE        ;
v_seguserfld2            CMS_CAF_INFO.cci_seg_user_fld2%TYPE        ;
v_segbranchnum            CMS_CAF_INFO.cci_seg12_branch_num%TYPE    ;
v_segdeptnum            CMS_CAF_INFO.cci_seg12_dept_num%TYPE        ;
v_seg12pinmailer        CMS_CAF_INFO.cci_seg12_pin_mailer%TYPE        ;
v_seg12cardcarrier        CMS_CAF_INFO.cci_seg12_card_carrier%TYPE    ;
v_seg12cardholdertitle    CMS_CAF_INFO.cci_seg12_cardholder_title%TYPE    ;
v_seg12opentext1        CMS_CAF_INFO.cci_seg12_open_text1%TYPE    ;
v_firstname                CMS_CAF_INFO.cci_seg12_name_line1%TYPE    ;
v_last_name                CMS_CAF_INFO.cci_seg12_name_line2%TYPE    ;
v_addr1                    CMS_CAF_INFO.cci_seg12_addr_line1%TYPE        ;
v_addr2                    CMS_CAF_INFO.cci_seg12_addr_line2%TYPE        ;
v_city                    CMS_CAF_INFO.cci_seg12_city%TYPE            ;
v_state                    CMS_CAF_INFO.cci_seg12_state%TYPE            ;
v_zip                    CMS_CAF_INFO.cci_seg12_postal_code%TYPE    ;
v_cntrycode                CMS_CAF_INFO.cci_seg12_country_code%TYPE    ;
v_issuestat                CMS_CAF_INFO.cci_seg12_issue_stat%TYPE        ;
v_issuenum                CMS_CAF_INFO.cci_seg12_issue_num%TYPE    ;
v_cardstoissue            CMS_CAF_INFO.cci_seg12_cards_to_issue%TYPE ;
v_cardsissued            CMS_CAF_INFO.cci_seg12_cards_issued%TYPE    ;
v_cardsret                CMS_CAF_INFO.cci_seg12_cards_ret%TYPE        ;
v_securitychar            CMS_CAF_INFO.cci_seg12_sec_char%TYPE        ;
v_issuedate                CMS_CAF_INFO.cci_seg12_issue_dat%TYPE        ;
v_effdate                CMS_CAF_INFO.cci_seg12_effective_dat%TYPE    ;
v_filler                CMS_CAF_INFO.cci_seg12_filler%TYPE            ;
v_file_gen                 CMS_CAF_INFO.CCI_FILE_GEN%TYPE;--shyam 22 sep 05 for HSM
v_emailid                 CMS_CAF_INFO.cci_seg12_open_text1%TYPE; -- added by amit on 23 aug 10 
v_mobino_birthdt        CMS_CAF_INFO.cci_seg12_custom_fld%TYPE;    -- added by amit on 23 aug 10 
v_hsm_mode                 CHAR(1); -- Rahul 28 Sep 05
v_hash_pan	CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
v_encr_pan	CMS_APPL_PAN.cap_pan_code_encr%TYPE;
 

CURSOR c1 IS
SELECT    cpa_acct_id, cpa_acct_posn
FROM    CMS_PAN_ACCT
WHERE    cpa_inst_code        = instcode
AND        cpa_pan_code    = Gethash(pancode)
AND        cpa_mbr_numb    = v_mbrnumb
ORDER BY cpa_acct_posn    ;

BEGIN        --Main begin
v_file_gen:='N'; -- shyam 22 sep 05 for HSM
v_mbrnumb := mbrnumb;

--SN CREATE HASH PAN 
BEGIN
	v_hash_pan := Gethash(pancode);
EXCEPTION
WHEN OTHERS THEN
errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RETURN;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
	v_encr_pan := Fn_Emaps_Main(pancode);
EXCEPTION
WHEN OTHERS THEN
errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RETURN;
END;
--EN create encr pan

-- rahul 28 sep 05
BEGIN
  SELECT CIP_PARAM_VALUE
  INTO v_hsm_mode
  FROM CMS_INST_PARAM
  WHERE CIP_PARAM_KEY='HSM_MODE'
  AND CIP_INST_CODE = instcode;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
       v_hsm_mode:='N';
END;

IF    TRIM(mbrnumb)  IS NULL  THEN
    --v_mbrnumb := '000';
  errmsg:= 'Member number can not be null.';
  RETURN;
ELSE
    v_mbrnumb :=  mbrnumb ;
END IF;

errmsg := 'OK';
v_cci_rec_typ := cafaction;
      dbms_output.put_line('b4 query 1 for ren');
--check whether the pin was regenetrated thru the system on that day for that pan
--dbms_output.put_line('Test point 0');
--commented on 27-06-02 because pin generation for DCMS is just marking for pin regen in CAF so no need to send the pin offset

        SELECT COUNT(cpa_acct_id)
        INTO    acctcnt
        FROM    CMS_APPL_PAN a , CMS_PAN_ACCT b
        WHERE    a.cap_inst_code    =    b.cpa_inst_code
        AND        a.cap_pan_code    =    b.cpa_pan_code
        AND        a.cap_mbr_numb    =    b.cpa_mbr_numb
        AND        a.cap_inst_code    =    instcode
        AND        a.cap_pan_code    =    v_hash_pan--pancode
        AND        a.cap_mbr_numb    =    v_mbrnumb
        GROUP BY a.cap_inst_code, a.cap_pan_code, cap_mbr_numb;

        v_progress:=2; -- rahul 29 Aug 05
        -- dbms_output.put_line('after query 1');

               --begin 1 ends
          BEGIN        --begin1
        SELECT ccb_cvv_value,ccb_service_code
        INTO    v_ccb_cvv_value,v_ccb_service_code
        FROM    CMS_CAF_B24
        WHERE    ccb_inst_code = instcode;
        EXCEPTION    --excp 1
        WHEN OTHERS THEN
        errmsg := 'Excp1 -- '||SQLERRM;
        END;
--=============================================================================================================================
        BEGIN        --begin 2
        ---==================================================================================
        --this select query finds all the information reqd for this pan
--        dbms_output.put_line('Query begins');
        v_progress:=3; -- rahul 29 Aug 05

        SELECT
        RPAD(b.cpm_switch_prod,2,' ')        "card type"        ,
        RPAD(SUBSTR(h.cbm_bran_fiid,0,4),4,' ')    "FIID"            ,--substr added temp 18-04-02, branch code length to be reduced to 4 from 6.....on 21/09/2002  made use of the fiid in bran mast instead of bran code
        a.cap_card_stat                "card stat"        ,
        RPAD(pinofst,16,' ')            "pin offset"        ,
        LPAD(a.CAP_ONLINE_AGGR_LIMIT,12,'0')        "totalwdllmt"        ,--a.cap_limit_amt                "totalwdllmt"        , - Ashwini 8 Dec 2004 CR60
         LPAD(a.CAP_OFFLINE_AGGR_LIMIT,12,'0')                "totaloffwdllmt"    ,--a.cap_limit_amt                "totaloffwdllmt"    , - Ashwini 8 Dec 2004 CR60
        '000000000000'                "total cca lmt"        ,
        '000000000000'                "total off cca lmt"    ,
        LPAD(a.CAP_ONLINE_AGGR_LIMIT,12,'0')        "total aggr lmt"    ,--'000000000000'                "total aggr lmt"    ,- Ashwini 8 Dec 2004 CR60
        LPAD(a.CAP_OFFLINE_AGGR_LIMIT,12,'0')            "total offl aggr lmt"    ,--'000000000000'                "total offl aggr lmt"    ,- Ashwini 8 Dec 2004 CR60
        '760101'                "first use date"    ,
        '760101'                "last reset date"    ,
        TO_CHAR(cap_expry_date,'YYMM')        "expiry date"        ,
        ' '                    "userfld1"        ,
        '0000000000000000'            "alphakey"        ,
        --f.cbm_vendor                            , commented on 07-12-02
        j.cpc_vendor                            ,
        RPAD(SUBSTR(a.cap_appl_bran,0,4),4,' ')    "cardfiid"        ,--substr added temp 18-04-02, branch code length to be reduced to 4 from 6
        --' '                    "stock"            , commented on 21-06-02
        --f.cbm_stock                            , commented on 07-12-02
        j.cpc_stock                            ,
        c.cpb_inst_bin                "prefix"        ,
        a.cap_use_limit                "seg1uselmt"        ,
        LPAD(a.cap_atm_online_limit,12,'0')    "seg1ttlwdllmt"        , --a.cap_limit_amt                "seg1ttlwdllmt"        , -Ashwini 8 Dec 2004 CR60
        LPAD(a.cap_atm_offline_limit,12,'0')     "seg1offlwdllmt"    ,--a.cap_limit_amt                "seg1offlwdllmt"    ,-Ashwini 8 Dec 2004 CR60
        '000000000000'                "seg1ttlccawdllmt"    ,
        '000000000000'                "seg1offlccawdllmt"    ,
        ' '                    "seg1depcrlmt"    ,
        '760101'                "seg1lastused"    ,
        a.cap_use_limit                "seg_ttl_pur_lmt"    ,
        a.cap_use_limit                "seg_offl_pur_lmt"    ,
        '000000000000'                "seg_ttl_cca_lmt"    ,
        '000000000000'                "seg_offl_cca_lmt"    ,
        LPAD(a.CAP_POS_ONLINE_LIMIT,12,'0')    "seg_ttl_wdl_lmt"    , --'000000000000'                "seg_ttl_wdl_lmt"    , -Ashwini 8 Dec 2004 CR60
        LPAD(a.CAP_POS_OFFLINE_LIMIT,12,'0')    "seg_offl_wdl_lmt"    ,--'000000000000'                "seg_offl_wdl_lmt"    , -Ashwini 8 Dec 2004 CR60
        '            '                "userfield"        ,
        a.cap_use_limit                "cci_seg_use_lmt"    ,
        '000000000000'                "cci_seg_ttl_rfnd_cr_lmt",
        '000000000000'                "cci_seg_offl_rfnd_cr_lmt",
        ' '                     "cci_seg_rsn_cde ",
        '010101'                "cci_seg_last_used",
        ' '                     "cci_seg_user_fld2",
        RPAD(DECODE(trim(g.ccc_catg_sname),'DEF','*',g.ccc_catg_sname),4,' ')    "cci_seg12_branch_num",
        '  '                    "cci_seg12_dept_num" ,
        '1'                    "cci_seg12_pin_mailer",
        '1'                    "cci_seg12_card_carrier",
        0                    "cci_seg12_cardholder_title",
        --RPAD(NVL(e.cam_phone_one,' '),40,' ')    "cci_seg12_open_text1",    -- changed on 24-06-02, select the phone number directly because weare already using joins to select from the address master, --commented by amit on 23 Aug 10 
--shyamjith 18 Apr 05 name should be taken from cms_appl_pan as name is modified during reissue and stored in cms_appl_pan
--        rpad(d.ccm_first_name,30,' ')        "first name"        ,                --    if the caf action  = 'A' then replace the phone number with remark.
        RPAD(a.cap_disp_name,30,' ')        "first name"        ,                --    if the caf action  = 'A' then replace the phone number with remark.

        RPAD(e.cam_add_three,30,' ')        "last name"        ,
        RPAD(e.cam_add_one,34,' ')        "addr 1"            ,
        RPAD(e.cam_add_two,34,' ')        "addr 2"            ,
        RPAD(SUBSTR(e.cam_city_name,1,22),22,' ') "city"        ,
        RPAD(NVL(e.cam_state_switch,' '),3,' ')    "state"    ,
        RPAD(e.cam_email,40,' ') "email id",                                              -- added by amit on 23 aug 10 
        RPAD(to_char(e.cam_phone_two),15,' ') || RPAD(to_char(l.ccm_birth_date,'yyyymmdd'),35,' ') "mobile no and birth date", -- added by amit on 23 aug 10 

--     After changes for CR 117, through single page entry the postal code can be entered as a 15 char value (9 originally)
--     It will remain 9 in case of appliation entry. This will remain 9 same in caf info also --  jimmy 3rd Oct 2005
        RPAD(e.cam_pin_code,9,' ')        "pin code"        ,

        --rpad(e.cam_cntry_code,3,' ')        "country"        ,
        -- '356'                            ,
        RPAD(i.GCM_CURR_CODE,3,' ')                    ,
        '01'                    "issue stat"        ,
        '0001'                    "issue num"        ,
        '0001'                    "cards to issue"    ,
        '0001'                    "cards issued"        ,
        '0001'                    "cards ret"        ,
        ' '                    "security char"        ,
        TO_CHAR(cap_active_date,'YYMMDD')    "issue date"        ,
        TO_CHAR(cap_active_date,'YYMMDD')    "active date"        ,
        v_ccb_cvv_value                "CVV"            ,
        --v_ccb_service_code            "Service code"        , commented on 21-06-02
        --f.cbm_serv_code                ,
        k.cbp_param_value            "Service code"    ,
        ' '                    "Filler"
        INTO
        v_cardtype                ,
        v_fiid                    ,
        v_cardstat                ,
        v_pinofst                    ,
        v_totwdllimit                ,
        v_totoffwdllimit                ,
        v_totccalmt                ,
        v_totoffccalmt                ,
        v_totaggrlmt                ,
        v_totoffaddrlmt            ,
        v_firstusedate                ,
        v_lastresetdate            ,
        v_expirydate                ,
        v_userfld1                ,
        v_alphakey                ,
        v_vendor                    ,
        v_cardfiid                    ,
        v_stock                    ,
        v_prefix                    ,
        v_seg1uselmt                ,
        v_seg1ttlwdllmt            ,
        v_seg1offlwdllmt            ,
        v_seg1ttlccawdllmt            ,
        v_seg1offlccawdllmt        ,
        v_seg1depcrlmt            ,
        v_seg1lastused            ,
        v_segttlpurlmt                ,
        v_segofflpurlmt            ,
        v_segttlccalmt                ,
        v_segofflccalmt            ,
        v_segttlwdllmt                ,
        v_segofflwdllmt            ,
        v_usefield                ,
        v_seguselmt                ,
        v_segttlrfndcrlmt            ,
        v_segofflrfndcrlmt            ,
        v_segrsncde                ,
        v_seglastused                ,
        v_seguserfld2                ,
        v_segbranchnum            ,
        v_segdeptnum            ,
        v_seg12pinmailer            ,
        v_seg12cardcarrier            ,
        v_seg12cardholdertitle        ,
        --v_seg12opentext1            , --commented by amit on 23 aug 10 
        v_firstname                ,
        v_last_name                ,
        v_addr1                    ,
        v_addr2                    ,
        v_city                    ,
        v_state                    ,
        v_emailid                ,
        v_mobino_birthdt        ,
        v_zip                    ,
        v_cntrycode                ,
        v_issuestat                ,
        v_issuenum                ,
        v_cardstoissue            ,
        v_cardsissued                ,
        v_cardsret                ,
        v_securitychar                ,
        v_issuedate                ,
        v_effdate                    ,
        v_ccb_cvv_value            ,
        v_ccb_service_code        ,
        v_filler
        FROM    CMS_APPL_PAN    a,
            CMS_PROD_MAST    b,
            CMS_PROD_BIN    c,
-- shyamjith 18 04 05 since name is picked up from cms_appl_pan            cms_cust_mast    d,
            CMS_ADDR_MAST    e,
            CMS_BIN_MAST    f,
            CMS_CUST_CATG    g,
            CMS_BRAN_MAST    h,
            GEN_CNTRY_MAST  i,
            CMS_PROD_CATTYPE j,
            CMS_BIN_PARAM     k,
            CMS_CUST_MAST     l ---- added by amit on 23 aug 10 
        WHERE    a.cap_inst_code    =    b.cpm_inst_code
        AND    a.cap_pan_code    =    v_hash_pan--pancode
        AND    a.cap_mbr_numb    =    v_mbrnumb
        AND    a.cap_prod_code =     b.cpm_prod_code
        AND    a.cap_inst_code    =    c.cpb_inst_code
        AND    a.cap_prod_code    =    c.cpb_prod_code
        AND    a.cap_inst_code    =    j.cpc_inst_code
        AND    a.cap_prod_code    =    j.cpc_prod_code
        AND    a.cap_card_type =    j.cpc_card_type
--shyamjth 18 04 05 since name is picked up from cms_appl_pan            AND    a.cap_inst_code =    d.ccm_inst_code
--shyamjth 18 04 05 since name is picked up from cms_appl_pan        AND    a.cap_cust_code    =    d.ccm_cust_code
        AND    a.cap_inst_code    =    e.cam_inst_code
        --Commented on 19april04 .Since it was in delinking we are shifting address code..... change Starts ....
        -- AND    a.cap_cust_code    =    e.cam_cust_code
        --Commented on 19april04 .Since it was in delinking we are shifting address code..... change End ....
        AND    a.cap_bill_addr    =    e.cam_addr_code
        AND     a.cap_inst_code    =    f.cbm_inst_code
        AND    a.cap_inst_code    =    g.ccc_inst_code
        AND    a.cap_cust_catg    =    g.ccc_catg_code
        AND     SUBSTR(a.cap_prod_code,1,1) = f.cbm_interchange_code
        AND     SUBSTR(Fn_Dmaps_Main(a.cap_pan_code_ENCR),1,6) =  f.cbm_inst_bin
        AND    a.cap_inst_code     =    h.cbm_inst_code
        AND    a.cap_appl_bran  =    h.cbm_bran_code
        AND    e.CAM_CNTRY_CODE =    i.GCM_CNTRY_CODE
        AND    e.cam_inst_code  =  i.gcm_inst_code
        AND a.cap_inst_code     =  l.ccm_inst_code -- added by amit on 23 aug 10 
        AND a.cap_cust_code     =  l.ccm_cust_code -- added by amit on 23 aug 10 
        AND    k.cbp_inst_code      =  b.cpm_inst_code(+)                  --added to select service code from bin_param
        AND    k.cbp_profile_code    =  b.cpm_profile_code(+)  
        AND    k.cbp_param_name    =  'Service Code'  ;

        v_progress:=4; -- rahul 29 Aug 05
--      dbms_output.put_line('after query 2');

       
  
--Commented by Christopher on 26DEC03 since it overwrites the comment field in BASE24.
        /*IF cafaction != 'A' THEN
        v_seg12opentext1 := rpad(nvl(remark,' '),40,' ')    ;
        END IF;*/
        --if customer category is HNI and bin is 466706 specifically hardcoded as a special condition for HNI else the vendor and stock comes from bin master
        --Added by Christopher on 23jan04 for new bin 466731
    --IF substr(trim(v_segbranchnum), 1, 3) = 'HNI' AND substr(pancode,1,6) = '466706'   THEN
    --    IF SUBSTR(trim(v_segbranchnum), 1, 3) = 'HNI' AND (SUBSTR(pancode,1,6) = '466706' OR SUBSTR(pancode,1,6) = '466731' OR SUBSTR(pancode,1,6) = '466730' OR SUBSTR(pancode,1,6) = '421395')  THEN
      IF SUBSTR(trim(v_segbranchnum), 1, 3) = 'HNI' AND (SUBSTR(Fn_Dmaps_Main(pancode_ENCR),1,6) = '466706' OR SUBSTR(Fn_Dmaps_Main(pancode_ENCR),1,6) = '466731' OR SUBSTR(Fn_Dmaps_Main(pancode_ENCR),1,6) = '466730' OR SUBSTR(Fn_Dmaps_Main(pancode_ENCR),1,6) = '421395')  THEN
        v_vendor     := 'C'    ;
        v_stock    :=  'C'    ;
        END IF;
        --added on 27-06-02 to change the values of variables issue status, pin mailer and card carrier depending on the support functions

        IF    cafaction = 'C' AND spprtfunc = 'REPIN' THEN
            v_issuestat                      :='02'    ;
            v_seg12pinmailer      :='1'    ;
            v_seg12cardcarrier    :='3'    ;
            pinofst                                :=RPAD(' ',16,' ');
        ELSIF cafaction  = 'C' AND spprtfunc IN('HTLST','DEHOT','DBLOK','BLOCK','ADDR','LINK','DLINK','ACCCL', 'REISU','LIMIT','CHGSTA','ADDRUPD','EXPRY','CLOSE') THEN -- Added LIMIT  - Ashwini 8 Dec 2004 CR60 , shyamjith 04 apr 05 added CHGSTA, shyamjith 05 apr 05 added ADDRUPD
            v_issuestat            :='00'    ;
            v_seg12pinmailer    :='1'    ;
            v_seg12cardcarrier    :='3'    ;
            pinofst                :=RPAD('Z',16,'Z');
        ELSIF cafaction = 'C' AND spprtfunc IN('RENEW') THEN
            v_issuestat            :='01'    ;--no new card to be generated
            v_seg12pinmailer    :='0'        ;--no pinmailer
            v_seg12cardcarrier    :='1';--Both Plastic and Card Carrier
            pinofst                := RPAD('Z',16,'Z');--keep the original Pin offset
        ELSIF (cafaction = 'A' AND spprtfunc = 'NEW')  THEN
            v_issuestat            :=        '01'    ;
            v_seg12pinmailer    :=        '1'    ;
            v_seg12cardcarrier    :=        '1'    ;
            --v_file_gen            :=        'P'    ; --shyam 22 sep 05 for HSM

            IF spprtfunc = 'NEW' THEN
                pinofst    :=    RPAD(' ',16,' ');
            ELSE
                pinofst    :=    RPAD('Z',16,'Z');
            END IF;
        END IF;


        /*...Rahul Jadhav 28 Sep 05
        if hsm mode is 'Y'
        override Following parameters in cms_caf_info .
             1.issue status ,
             2.pinmailer,
             3.card carrier
             4.Pin Offset
             5.cci_file_gen Flag
        */

        IF v_hsm_mode='Y' THEN
             -- Initialize new Pin and Emboss Generation Parameters
           IF (cafaction = 'A' AND spprtfunc = 'NEW')  THEN
                 v_issuestat                     :='11'    ;
                v_seg12pinmailer    :='0'     ;
                v_seg12cardcarrier    :='3'    ;
                v_file_gen            :='P'    ; --shyam 22 sep 05 for HSM
                pinofst                :=    RPAD(' ',16,' ');
           ELSIF ( cafaction  = 'C' AND spprtfunc = 'REPIN') THEN
                 v_issuestat            :='11'    ;
                v_seg12pinmailer    :='0'    ;
                v_seg12cardcarrier    :='3'    ;
                v_file_gen            :='P'    ;
                pinofst                :=    RPAD(' ',16,' ');
           ELSIF ( cafaction  = 'C' AND spprtfunc = 'REISU') THEN
                 v_issuestat            :='11'    ;
                v_seg12pinmailer    :='0'    ;
                v_seg12cardcarrier    :='3'    ;
                v_file_gen            :='N'    ; -- This is for old card
                pinofst                :=RPAD('Z',16,'Z');
              ELSIF ( cafaction  = 'C' AND spprtfunc = 'RENEW') THEN
                 v_issuestat            :='11'    ;
                v_seg12pinmailer    :='0'    ;
                v_seg12cardcarrier    :='3'    ;
                v_file_gen            :='E'    ;
                pinofst                :=RPAD('Z',16,'Z');
           END IF;

        END IF;

--dbms_output.put_line('Info successfully found');

        v_progress:=5; -- rahul 29 Aug 05
        INSERT INTO CMS_CAF_INFO    (cci_inst_code                    ,
                                cci_log_date                    ,
                                cci_pan_code                    ,
                                cci_mbr_numb                ,
                                cci_rec_typ                                     ,
                                cci_crd_typ                                     ,
                                cci_fiid                                             ,
                                cci_crd_stat                    ,
                                cci_pin_ofst                    ,
                                cci_ttl_wdl_lmt                ,
                                cci_offl_wdl_lmt                ,
                                cci_ttl_cca_lmt                               ,
                                cci_offl_cca_lmt                ,
                                cci_aggr_lmt                    ,
                                cci_offl_aggr_lmt                ,
                                cci_first_used_dat                ,
                                cci_last_reset_dat                ,
                                cci_exp_dat                                     ,
                                cci_user_fld1                                  ,
                                cci_card_alpha_key            ,
                                cci_vendor                                      ,
                                cci_crd_fiid                    ,
                                cci_stock                                         ,
                                cci_prefix                                         ,
                                cci_seg1_use_lmt                           ,
                                cci_seg1_ttl_wdl_lmt            ,
                                cci_seg1_offl_wdl_lmt            ,
                                cci_seg1_ttl_cca_lmt            ,
                                cci_seg1_offl_cca_lmt            ,
                                cci_seg1_dep_cr_lmt            ,
                                cci_seg1_last_used            ,
                                cci_seg_ttl_pur_lmt                ,
                                cci_seg_offl_pur_lmt            ,
                                cci_seg_ttl_cca_lmt            ,
                                cci_seg_offl_cca_lmt            ,
                                cci_seg_ttl_wdl_lmt            ,
                                cci_seg_offl_wdl_lmt            ,
                                cci_seg_user_fld                ,
                                cci_seg_use_lmt                             ,
                                cci_seg_ttl_rfnd_cr_lmt            ,
                                cci_seg_offl_rfnd_cr_lmt        ,
                                cci_seg_rsn_cde                            ,
                                cci_seg_last_used                ,
                                cci_seg_user_fld2                ,
                                cci_seg12_branch_num            ,
                                cci_seg12_dept_num                     ,
                                cci_seg12_pin_mailer                    ,
                                cci_seg12_card_carrier            ,
                                cci_seg12_cardholder_title        ,
                                --cci_seg12_open_text1            , commented by amit on 23 aug 10 
                                cci_seg12_name_line1            ,
                                cci_seg12_name_line2            ,
                                cci_seg12_addr_line1            ,
                                cci_seg12_addr_line2            ,
                                cci_seg12_city                                ,
                                cci_seg12_state                ,
                                cci_seg12_postal_code            ,
                                cci_seg12_country_code        ,
                                cci_seg12_issue_stat                    ,
                                cci_seg12_issue_num            ,
                                cci_seg12_cards_to_issue        ,
                                cci_seg12_cards_issued        ,
                                cci_seg12_cards_ret            ,
                                cci_seg12_sec_char            ,
                                cci_seg12_issue_dat                      ,
                                cci_seg12_effective_dat            ,
                                cci_seg12_cvv_value                     ,
                                cci_seg12_srvc_cde                      ,
                                cci_seg12_filler                ,
                                cci_seg31_acct_cnt            ,
                                cci_file_gen,
                                cci_seg12_open_text1,   -- added by amit on 23 aug 10 
                                cci_seg12_custom_fld    -- added by amit on 23 aug 10 
                ,    cci_pan_code_encr    
                                )
        VALUES                    (instcode                    ,
                                TRUNC(SYSDATE)            ,
                                v_hash_pan        ,
                                v_mbrnumb                ,
                                v_cci_rec_typ                ,
                                v_cardtype                ,
                                v_fiid                    ,
                                v_cardstat                ,
                                pinofst                    ,
                                v_totwdllimit                    ,
                                v_totoffwdllimit                ,
                                v_totccalmt                ,
                                v_totoffccalmt                ,
                                v_totaggrlmt                ,
                                v_totoffaddrlmt            ,
                                v_firstusedate                ,
                                v_lastresetdate            ,
                                v_expirydate                ,
                                v_userfld1                ,
                                v_alphakey                ,
                                v_vendor                    ,
                                v_cardfiid                    ,
                                v_stock                    ,
                                v_prefix                    ,
                                v_seg1uselmt                ,
                                v_seg1ttlwdllmt            ,
                                v_seg1offlwdllmt            ,
                                v_seg1ttlccawdllmt            ,
                                v_seg1offlccawdllmt        ,
                                v_seg1depcrlmt            ,
                                v_seg1lastused            ,
                                v_segttlpurlmt                ,
                                v_segofflpurlmt            ,
                                v_segttlccalmt                ,
                                v_segofflccalmt            ,
                                v_segttlwdllmt                ,
                                v_segofflwdllmt            ,
                                v_usefield                ,
                                v_seguselmt                ,
                                v_segttlrfndcrlmt            ,
                                v_segofflrfndcrlmt            ,
                                v_segrsncde                ,
                                v_seglastused                ,
                                v_seguserfld2                ,
                                v_segbranchnum            ,
                                v_segdeptnum            ,
                                v_seg12pinmailer            ,
                                v_seg12cardcarrier            ,
                                v_seg12cardholdertitle        ,
                                --v_seg12opentext1            , commented by amit on 23 aug 10
                                v_firstname                ,
                                v_last_name                ,
                                v_addr1                    ,
                                v_addr2                    ,
                                v_city                    ,
                                v_state                    ,
                                v_zip                    ,
                                v_cntrycode                ,
                                v_issuestat                ,
                                v_issuenum                ,
                                v_cardstoissue            ,
                                v_cardsissued                ,
                                v_cardsret                ,
                                v_securitychar                ,
                                v_issuedate                ,
                                v_effdate                    ,
                                v_ccb_cvv_value            ,
                                v_ccb_service_code        ,
                                v_filler                    ,
                                acctcnt                    ,
                                v_file_gen,
                                v_emailid,                       -- added by amit on 23 aug 10 
                                v_mobino_birthdt              -- added by amit on 23 aug 10 
                                    ,pancode_encr        ); -- shyamjith

        v_progress:=6; -- rahul 29 Aug 05
        FOR y IN c1
        LOOP
        IF    y.cpa_acct_posn  = 1 THEN
                SELECT    b.cam_acct_no,c.cat_switch_type ,d.cas_switch_statcode
                INTO    v_cam_acct_no, v_cat_switch_type, v_cas_switch_stat
                FROM    CMS_PAN_ACCT a,CMS_ACCT_MAST b,CMS_ACCT_TYPE c, CMS_ACCT_STAT d
                WHERE a.cpa_inst_code        =    instcode
                AND   a.cpa_pan_code        =    v_hash_pan
                AND   a.cpa_mbr_numb        =    v_mbrnumb
                AND   a.cpa_acct_id         =     y.cpa_acct_id
                AND   a.cpa_inst_code        =    b.cam_inst_code
                AND   a.cpa_acct_id         =     b.cam_acct_id
                AND   b.cam_inst_code        =    c.cat_inst_code
                AND   b.cam_type_code        =    c.cat_type_code
                AND   b.cam_inst_code        =    d.cas_inst_code
                AND   b.cam_stat_code        =    d.cas_stat_code
                ;
                --for testing only
                --v_cas_switch_stat := 3;
                --for testing only

                -- Change Done By Hari For Account Status Bug Fix in Base 24 - 4th Jan 2005
                v_cas_switch_stat := '3';
                -- Change Ends

                UPDATE    CMS_CAF_INFO
                SET     cci_seg31_typ        =    RPAD(v_cat_switch_type,2,' ')    ,
                    cci_seg31_num        =    RPAD(v_cam_acct_no,19,' ')    ,
                    cci_seg31_stat        =    v_cas_switch_stat        ,
                    cci_seg31_descr        =    '          '            ,
                    cci_seg31_corp        =    ' '                ,
                    cci_seg31_user_fld2a    =    ' '
                WHERE    cci_inst_code        =    instcode
                AND    cci_pan_code        =    v_hash_pan--pancode
                AND    cci_mbr_numb        =    v_mbrnumb;
            ELSIF y.cpa_acct_posn = 2 THEN
                SELECT b.cam_acct_no,c.cat_switch_type,
                DECODE(d.cas_switch_statcode, '3', '1' , 'M', '1', 'N', '1', 'O', '1', 'P', '1', 'Q', '1', 'R', '1',
 d.cas_switch_statcode)
                -- d.cas_switch_statcode
                --d.cas_switch_stat
                INTO    v_cam_acct_no, v_cat_switch_type, v_cas_switch_stat
                --v_cas_switch_stat
                FROM    CMS_PAN_ACCT a,CMS_ACCT_MAST b,CMS_ACCT_TYPE c, CMS_ACCT_STAT d
                WHERE    a.cpa_inst_code        =     instcode
                AND    a.cpa_pan_code        =    v_hash_pan--pancode
                AND      a.cpa_mbr_numb        =    v_mbrnumb
                AND    a.cpa_acct_id         =     y.cpa_acct_id
                AND      a.cpa_inst_code    =    b.cam_inst_code
                AND   a.cpa_acct_id         =     b.cam_acct_id
                AND   b.cam_inst_code        =    c.cat_inst_code
                AND   b.cam_type_code        =    c.cat_type_code
                AND   b.cam_inst_code        =    d.cas_inst_code
                AND   b.cam_stat_code        =    d.cas_stat_code
                ;
                UPDATE CMS_CAF_INFO
                SET         cci_seg31_typ1        =    RPAD(v_cat_switch_type,2,' '),
                        cci_seg31_num1        =    RPAD(v_cam_acct_no,19,' '),
                        cci_seg31_stat1        =    v_cas_switch_stat        ,
                        cci_seg31_descr1        =      '          '                ,
                        cci_seg31_corp1        =      ' '                    ,
                        cci_seg31_user_fld2a1    =    ' '
                WHERE    cci_inst_code            =    instcode
                AND        cci_pan_code    =     v_hash_pan--pancode
                AND        cci_mbr_numb        =    v_mbrnumb;
            ELSIF y.cpa_acct_posn = 3 THEN
                SELECT b.cam_acct_no,c.cat_switch_type,
                DECODE(d.cas_switch_statcode, '3', '1' , 'M', '1', 'N', '1', 'O', '1', 'P', '1', 'Q', '1', 'R', '1',
 d.cas_switch_statcode)
                --d.cas_switch_statcode
                --d.cas_switch_stat
                INTO    v_cam_acct_no, v_cat_switch_type, v_cas_switch_stat
                -- v_cas_switch_stat
                FROM    CMS_PAN_ACCT a,CMS_ACCT_MAST b,CMS_ACCT_TYPE c, CMS_ACCT_STAT d
                WHERE a.cpa_inst_code        =    instcode
                AND   a.cpa_pan_code        =    v_hash_pan--pancode
                AND   a.cpa_mbr_numb        =    v_mbrnumb
                AND   a.cpa_acct_id         =     y.cpa_acct_id
                AND   a.cpa_inst_code        =    b.cam_inst_code
                AND   a.cpa_acct_id         =     b.cam_acct_id
                AND   b.cam_inst_code        =    c.cat_inst_code
                AND   b.cam_type_code        =    c.cat_type_code
                AND   b.cam_inst_code        =    d.cas_inst_code
                AND   b.cam_stat_code        =    d.cas_stat_code
                ;
                UPDATE CMS_CAF_INFO
                SET         cci_seg31_typ2        =    RPAD(v_cat_switch_type,2,' '),
                        cci_seg31_num2        =      RPAD(v_cam_acct_no,19,' '),
                        cci_seg31_stat2        =    v_cas_switch_stat        ,
                        cci_seg31_descr2        =      '          '                ,
                        cci_seg31_corp2        =      ' '                    ,
                        cci_seg31_user_fld2a2    =    ' '
                WHERE    cci_inst_code            =    instcode
                AND        cci_pan_code    =     v_hash_pan--pancode
                AND        cci_mbr_numb        =    v_mbrnumb;
            ELSIF y.cpa_acct_posn = 4 THEN
                SELECT b.cam_acct_no,c.cat_switch_type,
                DECODE(d.cas_switch_statcode, '3', '1' , 'M', '1', 'N', '1', 'O', '1', 'P', '1', 'Q', '1', 'R', '1',
 d.cas_switch_statcode)
                -- d.cas_switch_statcode
                --d.cas_switch_stat
                INTO    v_cam_acct_no, v_cat_switch_type, v_cas_switch_stat
                --v_cas_switch_stat
                FROM    CMS_PAN_ACCT a,CMS_ACCT_MAST b,CMS_ACCT_TYPE c, CMS_ACCT_STAT d
                WHERE    a.cpa_inst_code        =    instcode
                AND    a.cpa_pan_code        =    v_hash_pan--pancode
                AND      a.cpa_mbr_numb    =    v_mbrnumb
                AND   a.cpa_acct_id         =     y.cpa_acct_id
                AND    a.cpa_inst_code    =    b.cam_inst_code
                AND   a.cpa_acct_id         =     b.cam_acct_id
                AND   b.cam_inst_code        =    c.cat_inst_code
                AND   b.cam_type_code        =    c.cat_type_code
                AND   b.cam_inst_code        =    d.cas_inst_code
                AND   b.cam_stat_code        =    d.cas_stat_code
                ;
                UPDATE CMS_CAF_INFO
                SET         cci_seg31_typ3        =    RPAD(v_cat_switch_type,2,' '),
                        cci_seg31_num3        =      RPAD(v_cam_acct_no,19,' '),
                        cci_seg31_stat3        =    v_cas_switch_stat        ,
                        cci_seg31_descr3        =      '          '                ,
                        cci_seg31_corp3        =      ' '                    ,
                        cci_seg31_user_fld2a3    =    ' '
                WHERE    cci_inst_code            =    instcode
                AND        cci_pan_code    =     v_hash_pan--pancode
                AND        cci_mbr_numb        =    v_mbrnumb;
            ELSIF y.cpa_acct_posn = 5 THEN
                SELECT b.cam_acct_no,c.cat_switch_type,
                DECODE(d.cas_switch_statcode, '3', '1' , 'M', '1', 'N', '1', 'O', '1', 'P', '1', 'Q', '1', 'R', '1',
 d.cas_switch_statcode)
                --d.cas_switch_statcode
                --d.cas_switch_stat
                INTO    v_cam_acct_no, v_cat_switch_type, v_cas_switch_stat
                -- v_cas_switch_stat
                FROM    CMS_PAN_ACCT a,CMS_ACCT_MAST b,CMS_ACCT_TYPE c, CMS_ACCT_STAT d
                WHERE    a.cpa_inst_code        =    instcode
                AND    a.cpa_pan_code        =    v_hash_pan--pancode
                AND      a.cpa_mbr_numb    =    v_mbrnumb
                AND   a.cpa_acct_id         =     y.cpa_acct_id
                AND    a.cpa_inst_code    =    b.cam_inst_code
                AND   a.cpa_acct_id         =     b.cam_acct_id
                AND   b.cam_inst_code        =    c.cat_inst_code
                AND   b.cam_type_code        =    c.cat_type_code
                AND   b.cam_inst_code        =    d.cas_inst_code
                AND   b.cam_stat_code        =    d.cas_stat_code;
                UPDATE CMS_CAF_INFO
                SET         cci_seg31_typ4        =    RPAD(v_cat_switch_type,2,' '),
                        cci_seg31_num4        =      RPAD(v_cam_acct_no,19,' '),
                        cci_seg31_stat4        =    v_cas_switch_stat        ,
                        cci_seg31_descr4        =      '          '                ,
                        cci_seg31_corp4        =      ' '                    ,
                        cci_seg31_user_fld2a4    =    ' '
                WHERE    cci_inst_code            =    instcode
                AND        cci_pan_code    =     v_hash_pan--pancode
                AND        cci_mbr_numb        =    v_mbrnumb;
            ELSIF y.cpa_acct_posn = 6 THEN
                SELECT b.cam_acct_no,c.cat_switch_type,
                DECODE(d.cas_switch_statcode, '3', '1' , 'M', '1', 'N', '1', 'O', '1', 'P', '1', 'Q', '1', 'R', '1',
 d.cas_switch_statcode)
                -- d.cas_switch_statcode
                --d.cas_switch_stat
                INTO    v_cam_acct_no, v_cat_switch_type, v_cas_switch_stat
                -- v_cas_switch_stat
                FROM    CMS_PAN_ACCT a,CMS_ACCT_MAST b,CMS_ACCT_TYPE c, CMS_ACCT_STAT d
                WHERE    a.cpa_inst_code        =    instcode
                AND    a.cpa_pan_code        =    v_hash_pan--pancode
                AND      a.cpa_mbr_numb    =    v_mbrnumb
                AND   a.cpa_acct_id         =     y.cpa_acct_id
                AND    a.cpa_inst_code    =    b.cam_inst_code
                AND   a.cpa_acct_id         =     b.cam_acct_id
                AND   b.cam_inst_code        =    c.cat_inst_code
                AND   b.cam_type_code        =    c.cat_type_code
                AND   b.cam_inst_code        =    d.cas_inst_code
                AND   b.cam_stat_code        =    d.cas_stat_code    ;
                UPDATE CMS_CAF_INFO
                SET         cci_seg31_typ5        =    RPAD(v_cat_switch_type,2,' '),
                        cci_seg31_num5        =      RPAD(v_cam_acct_no,19,' '),
                        cci_seg31_stat5        =    v_cas_switch_stat        ,
                        cci_seg31_descr5        =      '          '                ,
                        cci_seg31_corp5        =      ' '                    ,
                        cci_seg31_user_fld2a5    =    ' '
                WHERE    cci_inst_code            =    instcode
                AND        cci_pan_code    =     v_hash_pan--pancode
                AND        cci_mbr_numb        =    v_mbrnumb;
            ELSIF y.cpa_acct_posn = 7 THEN
                SELECT b.cam_acct_no,c.cat_switch_type,
                DECODE(d.cas_switch_statcode, '3', '1' , 'M', '1', 'N', '1', 'O', '1', 'P', '1', 'Q', '1', 'R', '1',
 d.cas_switch_statcode)
                -- d.cas_switch_statcode
                -- d.cas_switch_stat
                INTO    v_cam_acct_no, v_cat_switch_type, v_cas_switch_stat
                -- v_cas_switch_stat
                FROM    CMS_PAN_ACCT a,CMS_ACCT_MAST b,CMS_ACCT_TYPE c, CMS_ACCT_STAT d
                WHERE    a.cpa_inst_code        =    instcode
                AND    a.cpa_pan_code        =    v_hash_pan--pancode
                AND      a.cpa_mbr_numb    =    v_mbrnumb
                AND   a.cpa_acct_id         =     y.cpa_acct_id
                AND    a.cpa_inst_code    =    b.cam_inst_code
                AND   a.cpa_acct_id         =     b.cam_acct_id
                AND   b.cam_inst_code        =    c.cat_inst_code
                AND   b.cam_type_code        =    c.cat_type_code
                AND   b.cam_inst_code        =    d.cas_inst_code
                AND   b.cam_stat_code        =    d.cas_stat_code;
                UPDATE CMS_CAF_INFO
                SET         cci_seg31_typ6        =    RPAD(v_cat_switch_type,2,' '),
                        cci_seg31_num6        =      RPAD(v_cam_acct_no,19,' '),
                        cci_seg31_stat6        =    v_cas_switch_stat        ,
                        cci_seg31_descr6        =      '          '                ,
                        cci_seg31_corp6        =      ' '                    ,
                        cci_seg31_user_fld2a6    =    ' '
                WHERE    cci_inst_code            =    instcode
                AND        cci_pan_code    =     v_hash_pan--pancode
                AND        cci_mbr_numb        =    v_mbrnumb;
            ELSIF y.cpa_acct_posn = 8 THEN
                SELECT b.cam_acct_no,c.cat_switch_type,
                DECODE(d.cas_switch_statcode, '3', '1' , 'M', '1', 'N', '1', 'O', '1', 'P', '1', 'Q', '1', 'R', '1',
 d.cas_switch_statcode)
                -- d.cas_switch_statcode
                --d.cas_switch_stat
                INTO    v_cam_acct_no, v_cat_switch_type, v_cas_switch_stat
                -- v_cas_switch_stat
                FROM    CMS_PAN_ACCT a,CMS_ACCT_MAST b,CMS_ACCT_TYPE c, CMS_ACCT_STAT d
                WHERE    a.cpa_inst_code        =    instcode
                AND    a.cpa_pan_code        =    v_hash_pan--pancode
                AND      a.cpa_mbr_numb    =    v_mbrnumb
                AND   a.cpa_acct_id         =     y.cpa_acct_id
                AND    a.cpa_inst_code    =    b.cam_inst_code
                AND   a.cpa_acct_id         =     b.cam_acct_id
                AND   b.cam_inst_code        =    c.cat_inst_code
                AND   b.cam_type_code        =    c.cat_type_code
                AND   b.cam_inst_code        =    d.cas_inst_code
                AND   b.cam_stat_code        =    d.cas_stat_code;
                UPDATE CMS_CAF_INFO
                SET         cci_seg31_typ7        =    RPAD(v_cat_switch_type,2,' '),
                        cci_seg31_num7        =      RPAD(v_cam_acct_no,19,' '),
                        cci_seg31_stat7        =    v_cas_switch_stat        ,
                        cci_seg31_descr7        =      '          '                ,
                        cci_seg31_corp7        =      ' '                    ,
                        cci_seg31_user_fld2a7    =    ' '
                WHERE    cci_inst_code            =    instcode
                AND        cci_pan_code    =     v_hash_pan--pancode
                AND        cci_mbr_numb        =    v_mbrnumb;
            ELSIF y.cpa_acct_posn = 9 THEN
                SELECT b.cam_acct_no,c.cat_switch_type,
                DECODE(d.cas_switch_statcode, '3', '1' , 'M', '1', 'N', '1', 'O', '1', 'P', '1', 'Q', '1', 'R', '1',
 d.cas_switch_statcode)
                -- d.cas_switch_statcode
                --d.cas_switch_stat
                INTO    v_cam_acct_no, v_cat_switch_type, v_cas_switch_stat
                --, v_cas_switch_stat
                FROM    CMS_PAN_ACCT a,CMS_ACCT_MAST b,CMS_ACCT_TYPE c, CMS_ACCT_STAT d
                WHERE    a.cpa_inst_code        =    instcode
                AND    a.cpa_pan_code        =    v_hash_pan--pancode
                AND      a.cpa_mbr_numb    =    v_mbrnumb
                AND   a.cpa_acct_id         =     y.cpa_acct_id
                AND    a.cpa_inst_code    =    b.cam_inst_code
                AND   a.cpa_acct_id         =     b.cam_acct_id
                AND   b.cam_inst_code        =    c.cat_inst_code
                AND   b.cam_type_code        =    c.cat_type_code
                AND   b.cam_inst_code        =    d.cas_inst_code
                AND   b.cam_stat_code        =    d.cas_stat_code;
                UPDATE CMS_CAF_INFO
                SET         cci_seg31_typ8        =    RPAD(v_cat_switch_type,2,' '),
                        cci_seg31_num8        =      RPAD(v_cam_acct_no,19,' '),
                        cci_seg31_stat8        =    v_cas_switch_stat        ,
                        cci_seg31_descr8        =      '          '                ,
                        cci_seg31_corp8        =      ' '                    ,
                        cci_seg31_user_fld2a8    =    ' '
                WHERE    cci_inst_code            =    instcode
                AND        cci_pan_code    =     v_hash_pan--pancode
                AND        cci_mbr_numb        =    v_mbrnumb;
            ELSIF y.cpa_acct_posn = 10 THEN
                SELECT b.cam_acct_no,c.cat_switch_type,
                DECODE(d.cas_switch_statcode, '3', '1' , 'M', '1', 'N', '1', 'O', '1', 'P', '1', 'Q', '1', 'R', '1',
 d.cas_switch_statcode)
                -- d.cas_switch_statcode
                --d.cas_switch_stat
                INTO    v_cam_acct_no, v_cat_switch_type, v_cas_switch_stat
                --, v_cas_switch_stat
                FROM    CMS_PAN_ACCT a,CMS_ACCT_MAST b,CMS_ACCT_TYPE c, CMS_ACCT_STAT d
                WHERE    a.cpa_inst_code        =    instcode
                AND    a.cpa_pan_code        =    v_hash_pan--pancode
                AND      a.cpa_mbr_numb    =    v_mbrnumb
                AND   a.cpa_acct_id         =     y.cpa_acct_id
                AND    a.cpa_inst_code    =    b.cam_inst_code
                AND   a.cpa_acct_id         =     b.cam_acct_id
                AND   b.cam_inst_code        =    c.cat_inst_code
                AND   b.cam_type_code        =    c.cat_type_code
                AND   b.cam_inst_code        =    d.cas_inst_code
                AND   b.cam_stat_code        =    d.cas_stat_code;
                UPDATE CMS_CAF_INFO
                SET         cci_seg31_typ9        =    RPAD(v_cat_switch_type,2,' '),
                        cci_seg31_num9        =      RPAD(v_cam_acct_no,19,' '),
                        cci_seg31_stat9        =    v_cas_switch_stat        ,
                        cci_seg31_descr9        =      '          '                ,
                        cci_seg31_corp9        =      ' '                    ,
                        cci_seg31_user_fld2a9    =    ' '
                WHERE    cci_inst_code            =    instcode
                AND        cci_pan_code    =     v_hash_pan--pancode
                AND        cci_mbr_numb        =    v_mbrnumb;
        END IF    ;
--        EXIT WHEN c1%NOTFOUND;
        END LOOP;
        /*UPDATE    CMS_CAF_INFO
        SET    cci_pan_code = RPAD(cci_pan_code,19,' ')
        WHERE    cci_inst_code = instcode
        AND    cci_pan_code = pancode
        AND    cci_mbr_numb = v_mbrnumb;*/
--    dbms_output.put_line('Updation successfull');
        EXCEPTION    --excp 2
        WHEN OTHERS THEN
        errmsg := 'Excp 2 -- ErrorCode '||v_progress || ' Desc:-' || SQLERRM;
        END;        --end of begin 2
EXCEPTION    --Main excp
WHEN OTHERS THEN
errmsg := 'Main Excp for '||pancode||' -- '||SQLERRM;
END;        --Main begin ends
/


show error