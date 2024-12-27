CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_branch (
   instcode           IN       NUMBER,
   cntrycode          IN       NUMBER,
   statecode          IN       NUMBER,
   citycode           IN       NUMBER,
   brancode           IN       VARCHAR2,
   fiid               IN       VARCHAR2,
   micrno             IN       VARCHAR2,
   branloc            IN       VARCHAR2,
   addr1              IN       VARCHAR2,
   addr2              IN       VARCHAR2,
   addr3              IN       VARCHAR2,
   pincode            IN       NUMBER,
   phone1             IN       VARCHAR2,
   phone2             IN       VARCHAR2,
   phone3             IN       VARCHAR2,
   contprsn           IN       VARCHAR2,
   faxno              IN       VARCHAR2,
   email              IN       VARCHAR2,
   brancatg           IN       VARCHAR2,                     --sarvesh 24may08
   brantype           IN       VARCHAR2,                     --sarvesh 24may08
   reportingbran      IN       VARCHAR2,                     --sarvesh 24may08
   totwelkitlimit     IN       NUMBER,
   availwelkitlimit   IN       NUMBER,
   walletcatg         IN       VARCHAR2,
   wallettype         IN       VARCHAR2,
   commplan           IN       VARCHAR2,
   defcommplan        IN       VARCHAR2,                    --sarvesh 09june08
   saletrans          IN       VARCHAR2,                    --sarvesh 09june08
   topuptrans         IN       VARCHAR2,                    --sarvesh 09june08
--    reorderlevel IN NUMBER,
   lupduser           IN       NUMBER,
   errmsg             OUT      VARCHAR2
)
AS
   v_fiid              VARCHAR2 (6);
   exp_reject_record   EXCEPTION;
BEGIN                                           --Main Begin Block Starts Here
 errmsg := 'OK';
   IF fiid IS NULL
   THEN
      v_fiid := brancode;
   ELSE
      v_fiid := fiid;
   END IF;

   BEGIN
      INSERT INTO cms_bran_mast
                  (cbm_cntry_code, cbm_state_code, cbm_city_code,
                   cbm_inst_code, cbm_bran_code, cbm_bran_fiid, cbm_micr_no,
                   cbm_bran_locn, cbm_addr_one, cbm_addr_two,
                   cbm_addr_three, cbm_pin_code, cbm_phon_one, cbm_phon_two,
                   cbm_phon_three, cbm_cont_prsn, cbm_fax_no, cbm_email_id,
                   cbm_bran_catg,                            --sarvesh 24may08
                                 cbm_bran_type,              --sarvesh 24may08
                                               cbm_reporting_bran,
                                                             --sarvesh 24may08
                   cbm_tot_limit, cbm_avail_limit, cbm_wallet_catg,
                   cbm_wallet_type, cbm_commission_plan,
                   cbm_define_commplan,                     --sarvesh 09june08
                                       cbm_sale_trans,      --sarvesh 09june08
                                                      cbm_topup_trans,
                                                            --sarvesh 09june08
--         CBM_REORDER_LEVEL,
                   cbm_ins_user, cbm_lupd_user
                  )
           VALUES (cntrycode, statecode, citycode,
                   instcode, brancode, v_fiid, micrno,
                   branloc, addr1, addr2,
                   addr3, pincode, phone1, phone2,
                   phone3, contprsn, faxno, email,
                   brancatg,                                 --sarvesh 24may08
                            brantype,                        --sarvesh 24may08
                                     reportingbran,          --sarvesh 24may08
                   totwelkitlimit, availwelkitlimit, walletcatg,
                   wallettype, commplan,
                   defcommplan,                             --sarvesh 09june08
                               saletrans,                   --sarvesh 09june08
                                         topuptrans,        --sarvesh 09june08
--         reorderlevel,
                   lupduser, lupduser
                  );

      IF SQL%ROWCOUNT = 0
      THEN
         errmsg := 'Error While insertimg redord in CMS_BRAN_MAST' || SQLERRM;
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
     
      WHEN DUP_VAL_ON_INDEX
      THEN
         errmsg := 'Duplicate Record Found in Table CMS_BRAN_MAST';
         RAISE exp_reject_record;
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         errmsg := 'Error While insertimg redord in CMS_BRAN_MAST' || SQLERRM;
   RAISE exp_reject_record;
   END;
    
   
   BEGIN
      INSERT INTO pcms_inventory_loccode
                  (institution, loc_type, loc_code, loc_code_desc,
                   loc_address1, loc_address2, loc_address3, pin_code,
                   state, country, is_active
                  )
           VALUES ('1', 'BRANCH', brancode, branloc,
                   addr1, addr2, addr3, pincode,
                   statecode, cntrycode, 'Y'
                  );

      IF SQL%ROWCOUNT = 0
      THEN
         errmsg := 'Error While insertimg redord in CMS_BRAN_MAST' || SQLERRM;
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
       WHEN exp_reject_record
      THEN
         RAISE;
   
      WHEN DUP_VAL_ON_INDEX
      THEN
         errmsg := 'Duplicate Record Found in Table CMS_BRAN_MAST';
         RAISE exp_reject_record;
     
      WHEN OTHERS
      THEN
         errmsg :=
               'Error While insertimg redord in PCMS_INVENTORY_LOCCODE'
            || SQLERRM;
  RAISE exp_reject_record;
   END;

 
EXCEPTION                                               --Main block Exception
   WHEN exp_reject_record
   THEN
      errmsg := 'Error Msg ' || errmsg;
   WHEN OTHERS
   THEN
      errmsg := 'PCMS_001,' || SQLERRM;                     ---Main Exception
END;                                              --Main Begin Block Ends Here
/
SHOW ERROR