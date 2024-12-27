CREATE OR REPLACE TRIGGER VMSCMS.TRG_TRANSLIMITCHECK_STD
AFTER INSERT
ON VMSCMS.CMS_APPL_PAN REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN --main begin

             Insert into cms_translimit_check
                           (ctc_pan_code,
                               ctc_inst_code,
                            ctc_atm_offline_limit,
                            ctc_atm_online_limit,
                            ctc_pos_offline_limit,
                            ctc_pos_online_limit,
                            ctc_offline_aggr_limit,
                            ctc_online_aggr_limit,
                            ctc_atmusage_amt,
                            ctc_posusage_amt,
                            ctc_mbr_numb,
                            ctc_lupd_date,
                            ctc_ins_date,
                            ctc_atmusage_limit,
                            ctc_posusage_limit,
                            ctc_business_date,
                            ctc_pan_code_encr,
                            ctc_mmpos_offline_limit,
                            ctc_mmpos_online_limit,
                            ctc_mmposusage_limit,
                            ctc_mmposusage_amt
                            )
                         Values
                           (:new.cap_pan_code,
                               :new.cap_inst_code,
                            :new.cap_atm_offline_limit,
                            :new.cap_atm_online_limit,
                            :new.cap_pos_offline_limit,
                            :new.cap_pos_online_limit,
                            :new.cap_offline_aggr_limit,
                            :new.cap_online_aggr_limit,
                            '0','0',:new.cap_mbr_numb,
                            :new.cap_lupd_date,
                            :new.cap_ins_date,
                            '0','0',TO_DATE (TO_CHAR (:new.cap_ins_date, 'dd/mm/yyyy') || ' 23:59:59',
                            'dd/mm/yyyy hh24:mi:ss'),
                            :new.cap_pan_code_encr,
                            :new.cap_mmpos_offline_limit,
                            :new.cap_mmpos_online_limit,
                            0,
                            0);
END; --main end
/


