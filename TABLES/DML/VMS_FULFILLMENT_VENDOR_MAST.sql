insert into vmscms.vms_fulfillment_vendor_mast(vfv_fvendor_id,vfv_fvendor_name,vfv_ins_user,vfv_ins_date,vfv_lupd_user,
VFV_LUPD_DATE) VALUES('SourceOne','SourceOne',1,SYSDATE,1,SYSDATE);
insert into vmscms.vms_fulfillment_vendor_mast(vfv_fvendor_id,vfv_fvendor_name,vfv_ins_user,vfv_ins_date,vfv_lupd_user,
VFV_LUPD_DATE) VALUES('CPI','CPI',1,SYSDATE,1,SYSDATE);
insert into vmscms.vms_fulfillment_vendor_mast(vfv_fvendor_id,vfv_fvendor_name,vfv_ins_user,vfv_ins_date,vfv_lupd_user,
VFV_LUPD_DATE) VALUES('SourceOne1','CPI_Canada',1,SYSDATE,1,SYSDATE);
insert into vmscms.vms_fulfillment_vendor_mast(vfv_fvendor_id,vfv_fvendor_name,vfv_ins_user,vfv_ins_date,vfv_lupd_user,
VFV_LUPD_DATE) VALUES('CPI_1','CPI_Canada',1,SYSDATE,1,SYSDATE);
insert into vmscms.vms_fulfillment_vendor_mast(vfv_fvendor_id,vfv_fvendor_name,vfv_ins_user,vfv_ins_date,vfv_lupd_user,
VFV_LUPD_DATE) VALUES('CPI_2','HCS',1,SYSDATE,1,SYSDATE);
insert into vmscms.vms_fulfillment_vendor_mast(vfv_fvendor_id,vfv_fvendor_name,vfv_ins_user,vfv_ins_date,vfv_lupd_user,
VFV_LUPD_DATE) VALUES('SourceOne2','HGS',1,SYSDATE,1,SYSDATE);

update vmscms.vms_fulfillment_vendor_mast
set vfv_ccf_file_format='SourceOne_<<ProductCode>>_01_CCF<<Date>>_<<FileCount>>',
vfv_replace_ccf_file_format='SourceOne_<<ProductCode>>_02_CCF<<Date>>_<<FileCount>>'
where vfv_fvendor_name like 'SourceOne%';

update vmscms.vms_fulfillment_vendor_mast
set vfv_ccf_file_format='CPI_<<ProductCode>>_01_<<FileCount>>_0000_<<Date>>',
vfv_replace_ccf_file_format='CPI_<<ProductCode>>_02_<<FileCount>>_0000_<<Date>>'
where vfv_fvendor_name like 'CPI%';