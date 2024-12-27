DECLARE
v_err VARCHAR2(500);
v_exp EXCEPTION;
begin
	  v_err:='OK'; 
      begin
           for i in (select vti_token,vti_token_pan from vmscms.vms_token_info)
		  loop				
				begin
						update vmscms.VMS_TOKEN_INFO
            SET VTI_ACCT_NO=(SELECT CAP_ACCT_NO FROM VMSCMS.CMS_APPL_PAN
                             where cap_pan_code=i.vti_token_pan and cap_mbr_numb='000')
            where vti_token=i.vti_token
            and vti_token_pan=i.vti_token_pan;

				exception
						when others then
							dbms_output.put_line('Error while updating vms_token_info '||sqlerrm);
				end;
		   end loop;
		end;
       
       begin
           for i in (select vts_card_no from vmscms.vms_token_status_sync_dtls)
		  loop				
				begin
						update vmscms.vms_token_status_sync_dtls
            SET vts_acct_no=(SELECT CAP_ACCT_NO FROM VMSCMS.CMS_APPL_PAN
                             where cap_pan_code=i.vts_card_no and CAP_MBR_NUMB='000')
            where vts_card_no=i.vts_card_no;

				exception
						when others then
							dbms_output.put_line('Error while updating vms_token_status_sync_dtls '||sqlerrm);
				END;
		   end loop;
		   
      exception
          when others then
              v_err := 'Error while updating vms_token_status_sync_dtls '||sqlerrm;
              raise v_exp;
      end;
  
    commit;
    
    dbms_output.put_line(v_err);
exception
     WHEN v_exp THEN
          ROLLBACK;
          dbms_output.put_line(v_err);
     when others then
        rollback ;
        v_err :='Error in main-'|| substr (sqlerrm, 1, 200);
        dbms_output.put_line(v_err);
end;
/