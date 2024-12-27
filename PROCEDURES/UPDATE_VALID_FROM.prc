create or replace procedure vmscms.update_valid_from(p_prod_code_in in varchar2) as
   v_exp                   exception;
   v_err                   varchar2 (500);
begin
    for i in    (select cce_pan_code,cce_valid_from,cce_ins_date 
                from vmscms.cms_card_excpfee,vmscms.cms_appl_pan
                where trunc(cce_valid_from) < trunc(cce_ins_date)
                and cap_card_stat <> 9
                and cap_pan_code=cce_pan_code
                and cap_prod_code in (select regexp_substr(p_prod_code_in,'[^,]+', 1, level) from dual
                                     connect by regexp_substr(p_prod_code_in, '[^,]+', 1, level) is not null))
                loop
        begin
        
            UPDATE vmscms.cms_card_excpfee 
            SET cce_valid_from=cce_ins_date,
            cce_lupd_date=sysdate
            where cce_pan_code=i.cce_pan_code
            and cce_valid_from=i.cce_valid_from
            and cce_ins_date=i.cce_ins_date;
            
         exception
            when others  then
                rollback;
        end;
        
        commit;
    end loop;
    
    commit;  
    
exception
     when others then
        rollback ;
        v_err :='Error in main-'|| substr (sqlerrm, 1, 200);
        dbms_output.put_line(v_err);
end;
/
show error