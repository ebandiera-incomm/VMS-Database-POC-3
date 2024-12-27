CREATE OR REPLACE TRIGGER VMSCMS.TRG_CARD_FEE_AUDIT
   AFTER UPDATE OR DELETE
   ON VMSCMS.CMS_CARD_EXCPFEE    FOR EACH ROW
DECLARE

   v_cai_ins_date   DATE      := SYSDATE;
   update_audit     EXCEPTION;
   delete_audit     EXCEPTION;
/*************************************************
     * Modified By      :  Deepa
     * Modified Date    :  20-June-2012
     * Modified Reason  :  Fee changes
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  21-June-2012
     * Build Number     :  CMS3.5.1_RI0010_B0009
 ***********************************************/

BEGIN                                                 --SN Trigger body begins
   IF UPDATING
   THEN
      BEGIN
         INSERT INTO cms_card_excpfee_hist
                     (cce_inst_code,cce_pan_code,
                      cce_mbr_numb,
                      cce_fee_type, cce_fee_code,
                      cce_crgl_catg, cce_crgl_code,
                      cce_crsubgl_code, cce_cracct_no,
                      cce_drgl_catg, cce_drgl_code,
                      cce_drsubgl_code, cce_dracct_no,
                      cce_valid_from, cce_valid_to,
                      cce_flow_source, cce_ins_user,
                      cce_ins_date, cce_lupd_user,
                      cce_lupd_date, cce_st_crgl_catg,
                      cce_st_crgl_code, cce_st_crsubgl_code,
                      cce_st_cracct_no, cce_st_drgl_catg,
                      cce_st_drgl_code, cce_st_drsubgl_code,
                      cce_st_dracct_no, cce_cess_crgl_catg,
                      cce_cess_crgl_code, cce_cess_crsubgl_code,
                      cce_cess_cracct_no, cce_cess_drgl_catg,
                      cce_cess_drgl_code, cce_cess_drsubgl_code,
                      cce_cess_dracct_no, cce_st_calc_flag,
                      cce_cess_calc_flag, cce_act_date, cce_act_type,
                      cce_cardfee_id,CCE_FEE_PLAN
                     )
              VALUES (:OLD.cce_inst_code,
                      :OLD.cce_pan_code, :OLD.cce_mbr_numb,
                      :OLD.cce_fee_type, :OLD.cce_fee_code,
                      :OLD.cce_crgl_catg, :OLD.cce_crgl_code,
                      :OLD.cce_crsubgl_code, :OLD.cce_cracct_no,
                      :OLD.cce_drgl_catg, :OLD.cce_drgl_code,
                      :OLD.cce_drsubgl_code, :OLD.cce_dracct_no,
                      :OLD.cce_valid_from, :OLD.cce_valid_to,
                      :OLD.cce_flow_source, :OLD.cce_ins_user,
                      :OLD.cce_ins_date, :OLD.cce_lupd_user,
                      :OLD.cce_lupd_date, :OLD.cce_st_crgl_catg,
                      :OLD.cce_st_crgl_code, :OLD.cce_st_crsubgl_code,
                      :OLD.cce_st_cracct_no, :OLD.cce_st_drgl_catg,
                      :OLD.cce_st_drgl_code, :OLD.cce_st_drsubgl_code,
                      :OLD.cce_st_dracct_no, :OLD.cce_cess_crgl_catg,
                      :OLD.cce_cess_crgl_code, :OLD.cce_cess_crsubgl_code,
                      :OLD.cce_cess_cracct_no, :OLD.cce_cess_drgl_catg,
                      :OLD.cce_cess_drgl_code, :OLD.cce_cess_drsubgl_code,
                      :OLD.cce_cess_dracct_no, :OLD.cce_st_calc_flag,
                      :OLD.cce_cess_calc_flag, v_cai_ins_date, 'U',
                      :OLD.cce_cardfee_id,:OLD.CCE_FEE_PLAN
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE update_audit;
      END;
   ELSIF DELETING
   THEN
      BEGIN
         INSERT INTO cms_card_excpfee_hist
                     (cce_inst_code,
                      cce_pan_code, cce_mbr_numb,
                      cce_fee_type, cce_fee_code,
                      cce_crgl_catg, cce_crgl_code,
                      cce_crsubgl_code, cce_cracct_no,
                      cce_drgl_catg, cce_drgl_code,
                      cce_drsubgl_code, cce_dracct_no,
                      cce_valid_from, cce_valid_to,
                      cce_flow_source, cce_ins_user,
                      cce_ins_date, cce_lupd_user,
                      cce_lupd_date, cce_st_crgl_catg,
                      cce_st_crgl_code, cce_st_crsubgl_code,
                      cce_st_cracct_no, cce_st_drgl_catg,
                      cce_st_drgl_code, cce_st_drsubgl_code,
                      cce_st_dracct_no, cce_cess_crgl_catg,
                      cce_cess_crgl_code, cce_cess_crsubgl_code,
                      cce_cess_cracct_no, cce_cess_drgl_catg,
                      cce_cess_drgl_code, cce_cess_drsubgl_code,
                      cce_cess_dracct_no, cce_st_calc_flag,
                      cce_cess_calc_flag, cce_act_date, cce_act_type,
                      cce_cardfee_id,CCE_FEE_PLAN
                     )
              VALUES (:OLD.cce_inst_code,
                      :OLD.cce_pan_code, :OLD.cce_mbr_numb,
                      :OLD.cce_fee_type, :OLD.cce_fee_code,
                      :OLD.cce_crgl_catg, :OLD.cce_crgl_code,
                      :OLD.cce_crsubgl_code, :OLD.cce_cracct_no,
                      :OLD.cce_drgl_catg, :OLD.cce_drgl_code,
                      :OLD.cce_drsubgl_code, :OLD.cce_dracct_no,
                      :OLD.cce_valid_from, :OLD.cce_valid_to,
                      :OLD.cce_flow_source, :OLD.cce_ins_user,
                      :OLD.cce_ins_date, :OLD.cce_lupd_user,
                      :OLD.cce_lupd_date, :OLD.cce_st_crgl_catg,
                      :OLD.cce_st_crgl_code, :OLD.cce_st_crsubgl_code,
                      :OLD.cce_st_cracct_no, :OLD.cce_st_drgl_catg,
                      :OLD.cce_st_drgl_code, :OLD.cce_st_drsubgl_code,
                      :OLD.cce_st_dracct_no, :OLD.cce_cess_crgl_catg,
                      :OLD.cce_cess_crgl_code, :OLD.cce_cess_crsubgl_code,
                      :OLD.cce_cess_cracct_no, :OLD.cce_cess_drgl_catg,
                      :OLD.cce_cess_drgl_code, :OLD.cce_cess_drsubgl_code,
                      :OLD.cce_cess_dracct_no, :OLD.cce_st_calc_flag,
                      :OLD.cce_cess_calc_flag, v_cai_ins_date, 'D',
                      :OLD.cce_cardfee_id,:OLD.CCE_FEE_PLAN
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE delete_audit;
      END;
   END IF;
EXCEPTION
   WHEN update_audit
   THEN
      raise_application_error (-20001,
                                  'Error While Update Audit for card excp fee '
                               || SQLERRM
                              );
   WHEN delete_audit
   THEN
      raise_application_error
                             (-20002,
                                 'Error While Delete  Audit for card excp fee '
                              || SQLERRM
                             );
END;
/


