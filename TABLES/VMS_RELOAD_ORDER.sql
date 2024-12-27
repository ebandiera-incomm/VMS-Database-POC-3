create table vmscms.VMS_RELOAD_ORDER
(vro_reload_id varchar2(10),
vro_proxyorserial_type varchar2(20),
vro_proxyorserial_number varchar2(20),
vro_load_amnt number(20,3),
vro_comments varchar2(100),
vro_ins_user number(5,0),
vro_ins_date date);