INSERT INTO vmscms.vms_tableaudt_dictionary (vtd_tbl_id,
                                             vtd_col_name,
                                             vtd_ins_user,
                                             vtd_ins_date)
     VALUES ( (SELECT vtm_tbl_id
                 FROM vmscms.vms_tableaudt_mast
                WHERE vtm_tbl_name = 'CMS_PROD_CATTYPE'),
             'CPC_EXP_DATE_EXEMPTION',
             1,
             SYSDATE);
             
INSERT INTO vmscms.VMS_TABLEAUDT_DICTIONARY (vtd_tbl_id,
                                             vtd_col_name,
                                             vtd_ins_user,
                                             vtd_ins_date)
     VALUES ( (SELECT vtm_tbl_id
                 FROM vmscms.vms_tableaudt_mast
                WHERE vtm_tbl_name = 'CMS_PROD_CATTYPE'),
             'CPC_LOGO_ID',
             1,
             SYSDATE);