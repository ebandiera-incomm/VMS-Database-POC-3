CREATE OR REPLACE TRIGGER VMSCMS.TRG_PRODCATTYPE_FEE_AUDIT
AFTER DELETE OR UPDATE
ON  CMS_PRODCATTYPE_FEES
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   v_cai_ins_date   DATE      := SYSDATE;
   update_audit     EXCEPTION;
   delete_audit     EXCEPTION;
   v_errm varchar(1000);
/*************************************************
     * Modified By      :  Deepa
     * Modified Date    :  20-June-2012
     * Modified Reason  :  Fee changes
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  21-June-2012
     * Build Number     :  CMS3.5.1_RI0010_B0009
 *************************************************/
BEGIN                                                 --SN Trigger body begins
   IF UPDATING
   THEN
      BEGIN
         INSERT INTO cms_prodcattype_fees_hist
                     (cpf_inst_code, cpf_func_code,
                      cpf_prod_code, cpf_card_type,
                      cpf_fee_type, cpf_fee_code,
                      cpf_crgl_catg, cpf_crgl_code,
                      cpf_crsubgl_code, cpf_cracct_no,
                      cpf_drgl_catg, cpf_drgl_code,
                      cpf_drsubgl_code, cpf_dracct_no,
                      cpf_valid_from, cpf_valid_to,
                      cpf_flow_source, cpf_ins_user,
                      cpf_ins_date, cpf_lupd_user,
                      cpf_lupd_date, cpf_st_crgl_catg,
                      cpf_st_crgl_code, cpf_st_crsubgl_code,
                      cpf_st_cracct_no, cpf_st_drgl_catg,
                      cpf_st_drgl_code, cpf_st_drsubgl_code,
                      cpf_st_dracct_no, cpf_cess_crgl_catg,
                      cpf_cess_crgl_code, cpf_cess_crsubgl_code,
                      cpf_cess_cracct_no, cpf_cess_drgl_catg,
                      cpf_cess_drgl_code, cpf_cess_drsubgl_code,
                      cpf_cess_dracct_no, cpf_st_calc_flag,
                      cpf_cess_calc_flag, cpf_act_date, cpf_act_type,
                      cpf_prodcattype_id,CPF_FEE_PLAN
                     )
              VALUES (:OLD.cpf_inst_code, :OLD.cpf_func_code,
                      :OLD.cpf_prod_code, :OLD.cpf_card_type,
                      :OLD.cpf_fee_type, :OLD.cpf_fee_code,
                      :OLD.cpf_crgl_catg, :OLD.cpf_crgl_code,
                      :OLD.cpf_crsubgl_code, :OLD.cpf_cracct_no,
                      :OLD.cpf_drgl_catg, :OLD.cpf_drgl_code,
                      :OLD.cpf_drsubgl_code, :OLD.cpf_dracct_no,
                      :OLD.cpf_valid_from, :OLD.cpf_valid_to,
                      :OLD.cpf_flow_source, :OLD.cpf_ins_user,
                      :OLD.cpf_ins_date, :OLD.cpf_lupd_user,
                      :OLD.cpf_lupd_date, :OLD.cpf_st_crgl_catg,
                      :OLD.cpf_st_crgl_code, :OLD.cpf_st_crsubgl_code,
                      :OLD.cpf_st_cracct_no, :OLD.cpf_st_drgl_catg,
                      :OLD.cpf_st_drgl_code, :OLD.cpf_st_drsubgl_code,
                      :OLD.cpf_st_dracct_no, :OLD.cpf_cess_crgl_catg,
                      :OLD.cpf_cess_crgl_code, :OLD.cpf_cess_crsubgl_code,
                      :OLD.cpf_cess_cracct_no, :OLD.cpf_cess_drgl_catg,
                      :OLD.cpf_cess_drgl_code, :OLD.cpf_cess_drsubgl_code,
                      :OLD.cpf_cess_dracct_no, :OLD.cpf_st_calc_flag,
                      :OLD.cpf_cess_calc_flag, v_cai_ins_date, 'U',
                      :OLD.cpf_prodcattype_id,:OLD.CPF_FEE_PLAN
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE update_audit;
      END;
   ELSIF DELETING
   THEN
      BEGIN
         INSERT INTO cms_prodcattype_fees_hist
                     (cpf_inst_code, cpf_func_code,
                      cpf_prod_code, cpf_card_type,
                      cpf_fee_type, cpf_fee_code,
                      cpf_crgl_catg, cpf_crgl_code,
                      cpf_crsubgl_code, cpf_cracct_no,
                      cpf_drgl_catg, cpf_drgl_code,
                      cpf_drsubgl_code, cpf_dracct_no,
                      cpf_valid_from, cpf_valid_to,
                      cpf_flow_source, cpf_ins_user,
                      cpf_ins_date, cpf_lupd_user,
                      cpf_lupd_date, cpf_st_crgl_catg,
                      cpf_st_crgl_code, cpf_st_crsubgl_code,
                      cpf_st_cracct_no, cpf_st_drgl_catg,
                      cpf_st_drgl_code, cpf_st_drsubgl_code,
                      cpf_st_dracct_no, cpf_cess_crgl_catg,
                      cpf_cess_crgl_code, cpf_cess_crsubgl_code,
                      cpf_cess_cracct_no, cpf_cess_drgl_catg,
                      cpf_cess_drgl_code, cpf_cess_drsubgl_code,
                      cpf_cess_dracct_no, cpf_st_calc_flag,
                      cpf_cess_calc_flag, cpf_act_date, cpf_act_type,
                      cpf_prodcattype_id,CPF_FEE_PLAN
                     )
              VALUES (:OLD.cpf_inst_code, :OLD.cpf_func_code,
                      :OLD.cpf_prod_code, :OLD.cpf_card_type,
                      :OLD.cpf_fee_type, :OLD.cpf_fee_code,
                      :OLD.cpf_crgl_catg, :OLD.cpf_crgl_code,
                      :OLD.cpf_crsubgl_code, :OLD.cpf_cracct_no,
                      :OLD.cpf_drgl_catg, :OLD.cpf_drgl_code,
                      :OLD.cpf_drsubgl_code, :OLD.cpf_dracct_no,
                      :OLD.cpf_valid_from, :OLD.cpf_valid_to,
                      :OLD.cpf_flow_source, :OLD.cpf_ins_user,
                      :OLD.cpf_ins_date, :OLD.cpf_lupd_user,
                      :OLD.cpf_lupd_date, :OLD.cpf_st_crgl_catg,
                      :OLD.cpf_st_crgl_code, :OLD.cpf_st_crsubgl_code,
                      :OLD.cpf_st_cracct_no, :OLD.cpf_st_drgl_catg,
                      :OLD.cpf_st_drgl_code, :OLD.cpf_st_drsubgl_code,
                      :OLD.cpf_st_dracct_no, :OLD.cpf_cess_crgl_catg,
                      :OLD.cpf_cess_crgl_code, :OLD.cpf_cess_crsubgl_code,
                      :OLD.cpf_cess_cracct_no, :OLD.cpf_cess_drgl_catg,
                      :OLD.cpf_cess_drgl_code, :OLD.cpf_cess_drsubgl_code,
                      :OLD.cpf_cess_dracct_no, :OLD.cpf_st_calc_flag,
                      :OLD.cpf_cess_calc_flag, v_cai_ins_date, 'D',
                      :OLD.cpf_prodcattype_id,:OLD.CPF_FEE_PLAN
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
         v_errm :=  SQLERRM;
            RAISE delete_audit;
      END;
   END IF;
EXCEPTION
   WHEN update_audit
   THEN
      raise_application_error (-20001,
                                  'Error While Update Audit for Prod_CatTyp '
                               || SQLERRM
                              );
   WHEN delete_audit
   THEN
      raise_application_error
                             (-20002,
                                 'Error While Delete  Audit for Prod_CatTyp '
                              || v_errm
                             );
END;
/


