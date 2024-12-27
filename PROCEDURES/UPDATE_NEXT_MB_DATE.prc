CREATE OR REPLACE PROCEDURE vmscms.update_next_mb_date(p_prod_code_in IN VARCHAR2)
as
v_err VARCHAR2(500);
v_exp EXCEPTION;
begin
    for i in(select distinct cap_acct_no 
                from vmscms.cms_appl_pan a
                where cap_card_stat <> '9'
                and (cap_next_mb_date <> (select max(cap_next_mb_date)
                                        FROM vmscms.cms_appl_pan b 
                                        WHERE b.cap_acct_no=A.cap_acct_no) OR cap_next_mb_date is null)
				and cap_prod_code in (select regexp_substr(p_prod_code_in,'[^,]+', 1, level) from dual
                                     CONNECT BY regexp_substr(p_prod_code_in, '[^,]+', 1, LEVEL) IS NOT NULL))
     loop
        begin
        
            UPDATE vmscms.cms_appl_pan 
            SET cap_next_mb_date=(select max(cap_next_mb_date)
            FROM vmscms.cms_appl_pan  
            where cap_acct_no=i.cap_acct_no),
            cap_lupd_date=sysdate
            where cap_acct_no=i.cap_acct_no
            and cap_card_stat <> 9;
        
        exception
            when others  then
            rollback;
        END;
    commit;
    end loop;
    commit;  
exception
     WHEN v_exp THEN
          ROLLBACK;
          dbms_output.put_line(v_err);
     when others then
        rollback ;
        v_err :='Error in main-'|| substr (sqlerrm, 1, 200);
        dbms_output.put_line(v_err);
END;
/
show error