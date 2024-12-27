create or replace
PACKAGE body vmscms.vmsexpiry
as
    PROCEDURE upd_expiry_value(
        p_prod_code_in    IN VARCHAR2,
        p_prod_cattype_in in number,
        p_month_id_value_in in varchar2,
        p_user_in     IN NUMBER,
        p_date_in     IN DATE,
        p_resp_msg_out out varchar2)
      as
      l_cnt number;
      BEGIN
      p_resp_msg_out:='OK';
      for i in ((select regexp_substr(p_month_id_value_in,'[^,]+', 1, level) as month_id_value from dual
                                    connect by regexp_substr(p_month_id_value_in, '[^,]+', 1, level) is not null))
              loop
                  begin
                      update vms_expiry_mast
                      set Vem_MONTH_VALUE= substr(i.month_id_value,instr(i.month_id_value,':')+1),
                          vem_lupd_user=p_user_in,
                          vem_lupd_date=p_date_in
                      where Vem_MONTH_ID=substr(i.month_id_value,1,2)
                      and vem_prod_code=p_prod_code_in
                      and vem_prod_cattype=p_prod_cattype_in;
                  exception
                      when others then
                          rollback;
                           p_resp_msg_out:='Error while updating vms_expiry_mast '||substr(sqlerrm,1,200);
                           return;
                  end;
              end loop;     
          commit;
      exception
          when others then
             p_resp_msg_out:='Error in main'||substr(sqlerrm,1,200);
             return; 
      END;
END;
/
show error