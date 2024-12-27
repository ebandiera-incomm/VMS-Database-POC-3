create or replace
package vmscms.vmsexpiry
as
procedure upd_expiry_value(p_prod_code_in in varchar2,
                        p_prod_cattype_in in number,
                        p_month_id_value_in in varchar2,
                        p_user_in in number,
                        p_date_in in date,
                        p_resp_msg_out out varchar2);
end;
/
show error