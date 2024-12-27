Insert into vmscms.VMS_CVVPLUS_FSAPI (VCF_REQ_TYPE,VCF_HEADER_PARAM,VCF_BODY_PARAM,VCF_REQ_METHOD,VCF_TIMEOUT,VCF_URL) 
values ('RELOAD_POSTBACK','x-incfs-date~x-incfs-ip~x-incfs-channel~x-incfs-channel-identifier~x-incfs-username~x-incfs-correlationid~apikey~partnerid',null,'POST','500','http://10.44.72.181:8080/cms/fsapi');

Insert into vmscms.VMS_CVVPLUS_FSAPI (VCF_REQ_TYPE,VCF_HEADER_PARAM,VCF_BODY_PARAM,VCF_REQ_METHOD,VCF_TIMEOUT,VCF_URL) 
values ('ORDER_POSTBACK','x-incfs-date~x-incfs-ip~x-incfs-channel~x-incfs-channel-identifier~x-incfs-username~x-incfs-correlationid~apikey~partnerid',null,'POST','500','http://10.44.72.181:8080/cms/fsapi');


