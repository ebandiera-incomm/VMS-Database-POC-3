create or replace
package body               VMSCMS.VMSFILEPROCESS
as

/************************************************************************************************************

	  * Modified by      : MageshKumar.S
    * Modified Date    : 10-July-2018
    * Modified For     : VMS-392
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR03_B0004 
	
	* Modified by      : Baskar.K
    * Modified Date    : 18-July-2018
    * Modified For     : VMS-421
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR04_B0001 
    
    * Modified by      : Venkata Naga Sai.S
    * Modified Date    : 28-February-2019
    * Modified For     : VMS-788, VMS-795 & VMS-804
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR13_B0002 
    
    * Modified by      : UBAIDUR RAHMAN.H
    * Modified Date    : 29-MARCH-2019
    * Modified For     : VMS-823.
    * Reviewer         : Saravanankumar A
    * Build Number     : VMSR14_B0002.
    
    * Modified by      : UBAIDUR RAHMAN.H
    * Modified Date    : 23-APRIL-2019
    * Modified For     : VMS-874.
    * Reviewer         : Saravanankumar A
    * Build Number     : VMSR15_B0002.

	
	* Modified by      : BASKAR KRISHNAN
    * Modified Date    : 10-FEB-2020
    * Modified For     : VMS-1057.
    * Reviewer         : Saravanankumar A
    * Build Number     : VMSR26_B0002.
 *****************************************************************************************************************/
procedure PRINTER_RETURNFILE_PROCESS(P_INST_CODE_IN in number,P_FILE_NAME_IN in varchar2,
p_resp_msg_out out varchar2,p_child_partner_id_out out CLOB,
p_success_count_out out number,p_failure_count_out out number) as
l_cnt number;
l_pa_cnt  NUMBER;
l_tot_cnt  NUMBER;
L_PAN VMS_LINE_ITEM_DTL.VLI_PAN_CODE%type;
L_PARENT_ORDER_ID VMS_RETURNFILE_DATA_TEMP.VRD_PARENT_ORDER_ID%type;
l_child_order_id vms_returnfile_data_temp.vrd_child_order_id%type;
l_serial_number vms_returnfile_data_temp.VRD_SERIAL_NUMBER%type;
l_reject_code vms_returnfile_data_temp.vrd_reject_code%type;
l_reject_reason vms_returnfile_data_temp.vrd_reject_reason%type;
l_partner_id vms_line_item_dtl.vli_partner_id%type;
l_child_order_partner_id CLOB;
exp_reject_record exception;
L_INDEX NUMBER :=0;
l_index1 number:=0;
l_msg varchar2(300);
l_success_failure_flag  vms_fileprocess_rjreason_mast.vfr_success_failure_flag%type;
l_lineitem_id vms_line_item_dtl.vli_lineitem_id%type;
type_delete_pan shuffle_array_typ;
type_pan_array shuffle_array_typ;

cursor cur_rnfile_process is
select vrd_parent_order_id,vrd_child_order_id,
     vrd_serial_number,vrd_reject_code,vrd_reject_reason from VMS_RETURNFILE_DATA_TEMP
      where vrd_file_name=p_file_name_in
      and vrd_error_desc='Success';
begin
p_resp_msg_out:='OK';
type_delete_pan :=shuffle_array_typ();
type_pan_array :=shuffle_array_typ();
  begin
    select vrf_success_reccount,vrf_failure_reccount 
       into p_success_count_out,p_failure_count_out
       from vms_return_fileupload_dtls where vrf_file_name=p_file_name_in;
     exception
        when others then
            l_msg:='Error while selecting from vms_return_fileupload_dtls '||substr(sqlerrm,1,200);
        raise exp_reject_record;
   end;  

     open cur_rnfile_process;

      loop
      begin
        fetch cur_rnfile_process into l_parent_order_id,l_child_order_id,
                                          l_serial_number,l_reject_code,l_reject_reason;
        exit when cur_rnfile_process%notfound;

        begin
          select pan.cap_pan_code,lineitem.vli_partner_id,lineitem.vli_parent_oid,lineitem.vli_order_id,lineitem.vli_lineitem_id
          into l_pan,l_partner_id,l_parent_order_id,l_child_order_id,l_lineitem_id
            FROM VMS_LINE_ITEM_DTL lineitem,CMS_APPL_PAN pan
          where --a.VLI_PARENT_OID=b.vrd_parent_order_id
         -- and a.vli_lineitem_id=b.vrd_child_order_id
          --and a.vli_order_id=b.vrd_child_order_id
         -- AND
          pan.CAP_FORM_FACTOR IS NULL
          and pan.cap_pan_code=lineitem.vli_pan_code(+)
          AND pan.CAP_CARD_STAT <> '9'
          and pan.cap_inst_code=p_inst_code_in
          and pan.CAP_MBR_NUMB='000'
          and pan.cap_serial_number=l_serial_number;

       exception
            when too_many_rows then
              select cap_pan_code,vli_partner_id,vli_parent_oid,vli_order_id,vli_lineitem_id
              into l_pan,l_partner_id,l_parent_order_id,l_child_order_id,l_lineitem_id
              from  ( select pan.cap_pan_code,lineitem.vli_partner_id,lineitem.vli_parent_oid,lineitem.vli_order_id,lineitem.vli_lineitem_id
                        FROM VMS_LINE_ITEM_DTL lineitem ,CMS_APPL_PAN pan
                      where  pan.CAP_FORM_FACTOR IS NULL
                      and pan.cap_pan_code=lineitem.vli_pan_code(+)
                      AND pan.CAP_CARD_STAT <> '9'
                      and pan.cap_inst_code=p_inst_code_in
                      and pan.CAP_MBR_NUMB='000'
                      and pan.cap_serial_number=l_serial_number order by pan.cap_pangen_date desc) where rownum=1;
            -- Added for VMS-795            
            when no_data_found then
                
                l_pan:=NULL;     
                l_msg:='Serial Number not found/Closed';
                raise exp_reject_record;
            WHEN OTHERS THEN
              l_msg:='Error while selecting data from VMS_LINE_ITEM_DTL'||substr(sqlerrm,1,200);
              raise exp_reject_record;
       end;

        begin
            select vfr_reject_code,vfr_success_failure_flag
            into l_reject_code,l_success_failure_flag
            from vms_fileprocess_rjreason_mast
            where upper(vfr_reject_reason)=upper(l_reject_reason);
        exception
            when no_data_found then
				  l_success_failure_flag :='N';
                  l_reject_reason:='Rejected Reason'||'-'||l_reject_reason;
            when others then
                 l_msg:='Error while getting reject reason code'||substr(sqlerrm,1,200);
                  raise exp_reject_record;
        end;


        begin
          update vms_line_item_dtl
          set vli_reject_code=l_reject_code,
          vli_reject_reason=l_reject_reason,
          vli_serial_number=l_serial_number,
          vli_printer_response=DECODE(l_success_failure_flag,'Y','Success'
          ||'-'
          ||l_reject_reason, 'Failed'
          ||'-'
          ||l_reject_reason),
          vli_status      = CASE WHEN (vli_status not IN ('Completed','Shipped') OR vli_status IS NULL) THEN DECODE(l_success_failure_flag,'Y','Printer_Acknowledged',vli_status) ELSE vli_status END
        WHERE vli_pan_code=l_pan;
         -- and VLI_PARENT_OID=l_parent_order_id
         -- and VLI_order_id=l_child_order_id;
        exception
            WHEN OTHERS THEN
              l_msg:='Error while updating vms_line_item_dtl'||substr(sqlerrm,1,200);
              raise exp_reject_record;
        end;
          begin
                  type_pan_array.extend;
                  l_index1:=l_index1+1;
                  type_pan_array(l_index1):=l_pan;
         exception
                WHEN OTHERS THEN
                l_msg:='Error while adding pan to type_pan_array'||substr(sqlerrm,1,200);
                raise exp_reject_record;
        end;

          if nvl(l_success_failure_flag,'N')<>'Y' and l_partner_id <> 'Replace_Partner_ID' then
            begin
                  type_delete_pan.extend;
                  l_index:=l_index+1;
                  TYPE_DELETE_PAN(L_INDEX):=L_PAN;
            exception
                WHEN OTHERS THEN
                    l_msg:='Error while adding pan to type_delete_pan'||substr(sqlerrm,1,200);
                    raise exp_reject_record;
            end;
          end if;

        -- Added for VMS-804
		if nvl(l_success_failure_flag,'N')='Y' then
          begin
            UPDATE cms_cardissuance_status
                     SET ccs_card_status = '14',
		     CCS_LUPD_DATE = SYSDATE
                   WHERE ccs_inst_code = p_inst_code_in
                     AND ccs_pan_code = l_pan
                     AND ccs_card_status = '3';    --- Added for VMS -874.
          exception
              when others then
                l_msg:='Error while updating card issuance status'||substr(sqlerrm,1,200);
                raise exp_reject_record;
          end;
        end if;
          begin
              insert into VMS_RETURNFILE_DATA(vrd_inst_code,vrd_file_name,vrd_customer_desc,
            vrd_ship_suffix_no,vrd_parent_order_id,vrd_child_order_id,vrd_serial_number,vrd_reject_code,
            vrd_reject_reason,vrd_file_date,vrd_card_type,vrd_client_order_id,vrd_process_flag,vrd_row_id,vrd_error_desc,
            vrd_ins_user,vrd_ins_date,vrd_lupd_user,vrd_lupd_date,vrd_lineitem_id)
                select vrd_inst_code,vrd_file_name,vrd_customer_desc,
            vrd_ship_suffix_no,vrd_parent_order_id,vrd_child_order_id,vrd_serial_number,vrd_reject_code,
            vrd_reject_reason,vrd_file_date,vrd_card_type,vrd_client_order_id,vrd_process_flag,vrd_row_id,vrd_error_desc,
            vrd_ins_user,sysdate,vrd_lupd_user,sysdate,l_lineitem_id
            from VMS_RETURNFILE_DATA_TEMP
            WHERE VRD_SERIAL_NUMBER=L_SERIAL_NUMBER;

      exception
          WHEN OTHERS THEN
              L_MSG:='Error while moving data from VMS_RETURNFILE_DATA_TEMP to
              VMS_RETURNFILE_DATA table'||substr(sqlerrm,1,200);
              raise exp_reject_record;
      end;

      if l_child_order_id is not null and l_partner_id is not null then
              begin

            
            l_child_order_partner_id:= l_child_order_id||':'||l_partner_id;
              
              if length(nvl(P_CHILD_PARTNER_ID_OUT,' ')) = length(replace (nvl(P_CHILD_PARTNER_ID_OUT,' '),l_child_order_partner_id,'')) 
              then                             
              P_CHILD_PARTNER_ID_OUT:=P_CHILD_PARTNER_ID_OUT||L_CHILD_ORDER_PARTNER_ID||',';
              end if;
            
              exception
                  WHEN OTHERS THEN
                    L_MSG:='Error while getting child order id'||substr(sqlerrm,1,200);
                    raise exp_reject_record;
              END;
      end if;

      exception
          when exp_reject_record then
              ROLLBACK;
              
              p_success_count_out := p_success_count_out - 1;
              p_failure_count_out := p_failure_count_out + 1;
              INSERT INTO VMS_RETURNFILE_ERROR_DATA(VRE_FILE_NAME,VRE_PARENT_ORDER_ID,
                      VRE_CHILD_ORDER_ID,VRE_SERIAL_NUMBER,VRE_REJECT_CODE,
                      VRE_REJECT_REASON,VRE_PAN,VRE_ERROR_MESSAGE) VALUES(P_FILE_NAME_IN,
                      L_PARENT_ORDER_ID,L_CHILD_ORDER_ID,L_SERIAL_NUMBER,
                                          l_reject_code,l_reject_reason,l_pan,l_msg);
                commit;
          when others then
              rollback;

              p_success_count_out := p_success_count_out - 1;
              p_failure_count_out := p_failure_count_out + 1;
              INSERT INTO VMS_RETURNFILE_ERROR_DATA(VRE_FILE_NAME,VRE_PARENT_ORDER_ID,
                      VRE_CHILD_ORDER_ID,VRE_SERIAL_NUMBER,VRE_REJECT_CODE,
                      VRE_REJECT_REASON,VRE_PAN,VRE_ERROR_MESSAGE) VALUES(P_FILE_NAME_IN,
                      L_PARENT_ORDER_ID,L_CHILD_ORDER_ID,L_SERIAL_NUMBER,
                                          l_reject_code,l_reject_reason,l_pan,l_msg);
              commit;
      end;

      commit;
      END LOOP;
    if   p_child_partner_id_out is not null then
      p_child_partner_id_out:=rtrim(p_child_partner_id_out,',');
    end if;

    for loop_cur in (select COUNT(*) AS total_count,
      SUM(
      CASE
        WHEN vli_status IN ('Completed','Shipped','Printer_Acknowledged','Rejected')
        THEN 1
	ELSE 0
      END) AS printer_acknowledged_count,
      count(case when vli_reject_reason in
    (select vfr_reject_reason from vms_fileprocess_rjreason_mast where
    vfr_success_failure_flag='Y' ) then 1 end ) as cnt,max(vli_reject_reason) as vli_reject_reason,vli_order_id,vli_partner_id,vli_lineitem_id
   FROM vms_line_item_dtl
    WHERE (vli_order_id,vli_lineitem_id,vli_partner_id)IN
        (SELECT dtl.vli_order_id,
          dtl.vli_lineitem_id,
          dtl.vli_partner_id
        FROM table (cast (type_pan_array as SHUFFLE_ARRAY_TYP)) o,vms_line_item_dtl dtl
       WHERE dtl.vli_pan_code =o.column_value
    -- FROM vms_line_item_dtl
    --  WHERE vli_pan_code member of type_pan_array
        )GROUP BY vli_order_id,
      vli_partner_id,
      vli_lineitem_id
      )
     loop

         --if loop_cur.cnt=0 then
                UPDATE vms_order_lineitem
              SET vol_order_status =
                CASE
                  WHEN loop_cur.cnt = 0
                  THEN 'Rejected'
                  WHEN loop_cur.total_count = loop_cur.printer_acknowledged_count
                  THEN 'Printer_Acknowledged'
                  else  vol_order_status
                END ,
                vol_return_file_msg= loop_cur.vli_reject_reason
              WHERE vol_order_id   =loop_cur.vli_order_id
              AND vol_line_item_id =loop_cur.vli_lineitem_id
              AND vol_partner_id   =loop_cur.vli_partner_id
              AND (vol_order_status not IN ('Completed','Shipped','Rejected','Shipping') or vol_order_status IS NULL);    --- Added for VMS -874.
         --end if;

         SELECT COUNT(*),SUM(
          CASE
            WHEN vol_order_status <> 'Rejected'
            THEN 1
            ELSE 0
          END),
          SUM(
          CASE
            WHEN vol_order_status IN ('Completed','Shipped','Printer_Acknowledged','Rejected','Shipping')   --- Added for VMS -874.
            THEN 1
            ELSE 0
          END)
        INTO l_tot_cnt,l_cnt,
             l_pa_cnt
        FROM vms_order_lineitem
        WHERE vol_order_id =loop_cur.vli_order_id
          --  and vol_line_item_id=loop_cur.vli_lineitem_id
        AND vol_partner_id=loop_cur.vli_partner_id;


        --if l_cnt=0 then
              UPDATE vms_order_details
        SET vod_order_status=
          CASE
            WHEN l_cnt = 0
	    THEN 'Rejected'
	    WHEN l_pa_cnt =l_tot_cnt
            THEN 'Printer_Acknowledged'
            ELSE vod_order_status
          END
        WHERE vod_order_id    =loop_cur.vli_order_id
        AND vod_partner_id    =loop_cur.vli_partner_id
        AND (vod_order_status not IN ('Completed','Shipped','Rejected','Shipping') or vod_order_status IS NULL);   --- Added for VMS -874.
        --end if;

     END LOOP;

     begin
          vmsb2bapi.delete_cards(type_delete_pan,p_resp_msg_out);

          if p_resp_msg_out<>'OK' then
               raise exp_reject_record;
          end if;
     exception
          when exp_reject_record then
              raise;
          when others then
              p_resp_msg_out:='Error while calling vmsb2bapi.delete_cards'||substr(sqlerrm,1,200);
              raise exp_reject_record;
     end;
     
     begin    
     update vms_return_fileupload_dtls set vrf_success_reccount=p_success_count_out,
             vrf_failure_reccount=p_failure_count_out where vrf_file_name=p_file_name_in;
     exception
        when others then
            l_msg:='Error while updating data in vms_return_fileupload_dtls '||substr(sqlerrm,1,200);
        raise exp_reject_record;
   end;

exception
    when exp_reject_record then
         rollback;
         p_resp_msg_out:=l_msg;
    when others then
        rollback;
        p_resp_msg_out:='Error in main'||substr(sqlerrm,1,200);
end printer_returnfile_process;

procedure PRINTER_SHIPMENTFILE_PROCESS(P_INST_CODE_IN in number,P_FILE_NAME_IN in varchar2,
                          p_resp_msg_out out varchar2,p_child_partner_id_out out CLOB,
                          p_success_count_out out number,p_failure_count_out out number)as
l_pan vms_line_item_dtl.vli_pan_code%type;
l_pan_encr cms_appl_pan.cap_pan_code_encr%type;
l_cust_code CMS_APPL_PAN.CAP_CUST_CODE%type;
l_acct_id CMS_APPL_PAN.CAP_ACCT_ID%type;
l_parent_order_id vms_shipmentfile_data_temp.vsd_parent_order_id%type;
l_child_order_id vms_shipmentfile_data_temp.vsd_child_order_id%type;
l_serial_number vms_shipmentfile_data_temp.VsD_SERIAL_NUMBER%type;
l_tracking_no   vms_shipmentfile_data_temp.vsd_tracking_number%type;
l_shipping_datetime vms_shipmentfile_data_temp.vsd_ship_date%type;
l_package_id  vms_shipmentfile_data_temp.vsd_package_id%type;
l_cn_file_identifier vms_fulfillment_vendor_mast.vfv_b2b_cn_file_identifier%type;
l_partner_id vms_line_item_dtl.vli_partner_id%type;
l_child_order_partner_id CLOB;
exp_reject_record exception;
type_pan_array shuffle_array_typ;
l_index number:=0;
l_msg varchar2(300);
l_encryflag_cnt number;
l_encryption_flag cms_prod_cattype.CPC_ENCRYPT_ENABLE%type;
l_printer_resp vms_line_item_dtl.vli_printer_response%type;
l_stat        vms_line_item_dtl.vli_status%type;
l_print_order        vms_order_details.vod_print_order%TYPE; 
l_lineitem_status  vms_order_lineitem.vol_order_status%TYPE; 
l_update_status vms_order_lineitem.vol_order_status%TYPE;

cursor   cur_printfile_process(p_file_name varchar2) is
        select vsd_parent_order_id,vsd_child_order_id,
        vsd_serial_number,vsd_tracking_number,
        vsd_ship_date,VSD_PACKAGE_ID from VMS_SHIPMENTFILE_DATA_TEMP
          where vsd_file_name=p_file_name
         and vsd_error_desc='Success';
begin
  p_resp_msg_out:='OK';
  type_pan_array :=shuffle_array_typ();
  begin
    select vsf_success_reccount,vsf_failure_reccount 
       into p_success_count_out,p_failure_count_out
       from vms_shipment_fileupload_dtls where vsf_file_name=p_file_name_in;
     exception
        when others then
            l_msg:='Error while selecting from vms_shipment_fileupload_dtls '||substr(sqlerrm,1,200);
        raise exp_reject_record;
   end;  
   
    open cur_printfile_process(p_file_name_in);

   loop
   begin
      fetch cur_printfile_process into l_parent_order_id,l_child_order_id,
                                           l_serial_number,l_tracking_no,l_shipping_datetime,l_package_id;
      exit when cur_printfile_process%notfound;

         begin
            begin
                select pan.cap_pan_code,pan.cap_pan_code_encr,dtl.vli_partner_id,dtl.vli_parent_oid,dtl.vli_order_id,pan.cap_cardpack_id,pan.cap_acct_id,pan.cap_cust_code,dtl.vli_printer_response,dtl.vli_status
                into l_pan,l_pan_encr,l_partner_id,l_parent_order_id,l_child_order_id,l_package_id,l_acct_id,l_cust_code,l_printer_resp,l_stat
                FROM VMS_LINE_ITEM_DTL dtl,CMS_APPL_PAN pan
                WHERE pan.CAP_FORM_FACTOR IS NULL
                and pan.cap_pan_code=dtl.vli_pan_code(+)
                AND pan.CAP_CARD_STAT <> '9'
                and pan.cap_inst_code=p_inst_code_in
                and pan.CAP_MBR_NUMB='000'
                and pan.cap_serial_number=l_serial_number;
            exception
               when too_many_rows then
                select cap_pan_code,cap_pan_code_encr,vli_partner_id,
                        vli_parent_oid,vli_order_id,cap_cardpack_id,
                        cap_acct_id,cap_cust_code,vli_printer_response,
                        vli_status  
                into l_pan,l_pan_encr,l_partner_id,l_parent_order_id,l_child_order_id,l_package_id,l_acct_id,l_cust_code,l_printer_resp,l_stat
                       from( select pan.cap_pan_code,pan.cap_pan_code_encr,dtl.vli_partner_id,dtl.vli_parent_oid,dtl.vli_order_id,pan.cap_cardpack_id,pan.cap_acct_id,pan.cap_cust_code,dtl.vli_printer_response,dtl.vli_status
                          FROM VMS_LINE_ITEM_DTL dtl,CMS_APPL_PAN pan
                        WHERE pan.CAP_FORM_FACTOR IS NULL
                        and pan.cap_pan_code=dtl.vli_pan_code(+)
                        AND pan.CAP_CARD_STAT <> '9'
                        and pan.cap_inst_code=p_inst_code_in
                        and pan.CAP_MBR_NUMB='000'
                        and pan.cap_serial_number=l_serial_number order by pan.cap_pangen_date desc) where rownum=1;
                -- Added for VMS-788           
                when no_data_found then
                 l_pan:=NULL;
                 l_msg:='Serial Number not found/Closed';
                    raise exp_reject_record;        
               when others then
                    l_msg:='Error while selecting data from vms_line_item_dtl'||substr(sqlerrm,1,200);
                    raise exp_reject_record;
             end;
         
             
          if upper(l_stat)  = 'COMPLETED' or upper(l_stat)  = 'SHIPPED' then
              l_msg:='Order already Processed';
              raise exp_reject_record;       
          end if; 
          
          if upper(l_printer_resp)  like 'FAILED%'  then
              l_msg:=l_printer_resp;
              raise exp_reject_record;       
          end if; 
          
         exception
              when exp_reject_record then
              raise exp_reject_record; 
              when others then
                l_msg:='Error while selecting data from vms_line_item_dtl'||substr(sqlerrm,1,200);
                raise exp_reject_record;
         end;

           begin
                    type_pan_array.extend;
                    l_index:=l_index+1;
                    type_pan_array(l_index):=l_pan;
           exception
                  when others then
                       l_msg:='Error while adding pan to type_pan_array'||substr(sqlerrm,1,200);
                      raise exp_reject_record;
          end;

         BEGIN
              select a.VFV_B2B_VENDOR_CNFILE_REQ
               into l_cn_file_identifier
               from vms_fulfillment_vendor_mast a,VMS_PACKAGEID_MAST b,cms_prod_cardpack c
               where a.vfv_fvendor_id=b.vpm_vendor_id
               and b.VPM_PACKAGE_ID = c.CPC_CARD_DETAILS
               and c.CPC_CARD_ID =l_package_id;

         EXCEPTION
            when others then
                l_msg:='Error while getting VFV_B2B_VENDOR_CNFILE_REQ from
                vms_fulfillment_vendor_mast'||substr(sqlerrm,1,200);
                raise exp_reject_record;
         end;

          begin
            update vms_line_item_dtl
            set  vli_tracking_no=l_tracking_no,
                vli_shipping_datetime=l_shipping_datetime,
                vli_status=decode(l_cn_file_identifier,'N','Completed','Shipped')
            where vli_pan_code=l_pan;
            --and VLI_PARENT_OID=l_parent_order_id
            --and VLI_ORDER_ID=l_child_order_id;
          exception
              when others then
                l_msg:='Error while updating vms_line_item_dtl'||substr(sqlerrm,1,200);
                raise exp_reject_record;
          end;

          begin
            UPDATE cms_cardissuance_status
                     SET ccs_card_status = '15',
                         ccs_shipped_date = l_shipping_datetime
                   WHERE ccs_inst_code = p_inst_code_in
                     AND ccs_pan_code = l_pan;
          exception
              when others then
                l_msg:='Error while updating card issuance status'||substr(sqlerrm,1,200);
                raise exp_reject_record;
          end;
          BEGIN
           INSERT INTO cms_smsandemail_alert (csa_inst_code,
                                                  csa_pan_code,
                                                  csa_pan_code_encr,
                                                  csa_loadorcredit_flag,
                                                  csa_lowbal_flag,
                                                  csa_negbal_flag,
                                                  csa_highauthamt_flag,
                                                  csa_dailybal_flag,
                                                  csa_insuff_flag,
                                                  csa_incorrpin_flag,
                                                  csa_fast50_flag,
                                                  csa_fedtax_refund_flag,
                                                  csa_deppending_flag,
                                                  csa_depaccepted_flag,
                                                  csa_deprejected_flag,
                                                  csa_ins_user,
                                                  csa_ins_date)
                    VALUES (p_inst_code_in,
                           l_pan,
                           l_pan_encr,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            SYSDATE);
            EXCEPTION
               WHEN OTHERS
               THEN
                 null;
            END;

            BEGIN
               INSERT INTO cms_pan_acct (cpa_inst_code,
                                         cpa_cust_code,
                                         cpa_acct_id,
                                         cpa_acct_posn,
                                         cpa_pan_code,
                                         cpa_mbr_numb,
                                         cpa_ins_user,
                                         cpa_lupd_user,
                                         cpa_pan_code_encr)
                    VALUES (p_inst_code_in,
                            l_cust_code,
                            l_acct_id,
                            1,
                            l_pan,
                            '000',
                            1,
                            1,
                            l_pan_encr);
            EXCEPTION
               WHEN OTHERS
               THEN
                 null;
            END;

          begin

            select COUNT(*) INTO l_encryflag_cnt
            from VMS_ORDER_LINEITEM,cms_prod_cattype
            where vol_product_id = cpc_product_id
            and VOL_ORDER_ID = l_child_order_id
            and VOL_PARTNER_ID = l_partner_id
            and CPC_ENCRYPT_ENABLE = 'Y';

            if l_encryflag_cnt > 0 then
              l_encryption_flag := 'Y';
              ELSE
              l_encryption_flag := 'N';
            end if;

            EXCEPTION
            when others then
                l_msg:='Error while getting encryprion enable flag from
                cms_prod_cattype for order id'||substr(sqlerrm,1,200);
                raise exp_reject_record;
         end;



          begin
              insert into VMS_SHIPMENTFILE_DATA(VSD_INST_CODE,VSD_FILE_NAME,
              VSD_CUSTOMER_DESC,VSD_SOURCEONE_BATCH_NO,VSD_PARENT_ORDER_ID,
              VSD_CHILD_ORDER_ID,VSD_FILE_DATE,VSD_SERIAL_NUMBER,VSD_CARDS,
              VSD_PACKAGE_ID,VSD_CARD_TYPE,VSD_CONTACT_NAME,VSD_SHIP_TO,VSD_ADDRESS_ONE,
              VSD_ADDRESS_TWO,VSD_CITY,VSD_STATE,VSD_ZIP,VSD_TRACKING_NUMBER,VSD_SHIP_DATE,
              VSD_SHIPMENT_ID,VSD_SHIPMENT_METHOD,VSD_PROCESS_FLAG,VSD_ROW_ID,VSD_ERROR_DESC,
                VSD_INS_USER,VSD_INS_DATE,VSD_LUPD_USER,VSD_LUPD_DATE) select VSD_INST_CODE,VSD_FILE_NAME,
              VSD_CUSTOMER_DESC,VSD_SOURCEONE_BATCH_NO,VSD_PARENT_ORDER_ID,
              VSD_CHILD_ORDER_ID,VSD_FILE_DATE,VSD_SERIAL_NUMBER,VSD_CARDS,
              VSD_PACKAGE_ID,VSD_CARD_TYPE,DECODE(l_encryption_flag,'N',VSD_CONTACT_NAME,fn_emaps_main(VSD_CONTACT_NAME)),DECODE(l_encryption_flag,'N',VSD_SHIP_TO,fn_emaps_main(VSD_SHIP_TO)),DECODE(l_encryption_flag,'N',VSD_ADDRESS_ONE,fn_emaps_main(VSD_ADDRESS_ONE)),
              DECODE(l_encryption_flag,'N',VSD_ADDRESS_TWO,fn_emaps_main(VSD_ADDRESS_TWO)),DECODE(l_encryption_flag,'N',VSD_CITY,fn_emaps_main(VSD_CITY)),DECODE(l_encryption_flag,'N',VSD_STATE,fn_emaps_main(VSD_STATE)),DECODE(l_encryption_flag,'N',VSD_ZIP,fn_emaps_main(VSD_ZIP)),VSD_TRACKING_NUMBER,VSD_SHIP_DATE,VSD_SHIPMENT_ID
              VSD_SHIPMENT_ID,VSD_SHIPMENT_METHOD,VSD_PROCESS_FLAG,VSD_ROW_ID,VSD_ERROR_DESC,
            VSD_INS_USER,VSD_INS_DATE,VSD_LUPD_USER,VSD_LUPD_DATE from VMS_SHIPMENTFILE_DATA_TEMP
             where vsd_serial_number=l_serial_number;

          exception
              when others then
                  l_msg:='Error while moving data from VMS_SHIPMENTFILE_DATA_TEMP to VMS_SHIPMENTFILE_DATA'||substr(sqlerrm,1,200);
                  raise exp_reject_record;
          END;
        if l_child_order_id is not null and  l_partner_id is not null then
           begin
              l_child_order_partner_id:= l_child_order_id||':'||l_partner_id||':0' ;
              
              if length(nvl(P_CHILD_PARTNER_ID_OUT,' ')) = length(replace (nvl(P_CHILD_PARTNER_ID_OUT,' '),l_child_order_partner_id,'')) 
             then                             
              P_CHILD_PARTNER_ID_OUT:=P_CHILD_PARTNER_ID_OUT||L_CHILD_ORDER_PARTNER_ID||',';
            end if;


           exception
                when others then
                    l_msg:='Error while getting vsd_child_order_id from VMS_SHIPMENTFILE_DATA_TEMP'||substr(sqlerrm,1,200);
                    raise exp_reject_record;
          END;
      end if;
      exception
          when exp_reject_record then
              rollback;
               p_success_count_out := p_success_count_out - 1;
               p_failure_count_out := p_failure_count_out + 1;
               insert into VMS_SHIPMENTFILE_ERROR_DATA(VSE_FILE_NAME,
               VSE_PARENET_ORDER_ID,VSE_CHILD_ORDER_ID,VSE_SERIAL_NUMBER,VSE_TRACKING_NO,
               VSE_SHIP_DATE,VSE_PACKAGE_ID,VSE_PAN,VSE_ERROR_MSG) values
               (p_file_name_in,l_parent_order_id,l_child_order_id,l_serial_number,
                l_tracking_no,l_shipping_datetime,l_package_id,l_pan,l_msg);
                commit;
          when others then
                rollback;
               p_success_count_out := p_success_count_out - 1;
               p_failure_count_out := p_failure_count_out + 1;
               insert into VMS_SHIPMENTFILE_ERROR_DATA(VSE_FILE_NAME,
               VSE_PARENET_ORDER_ID,VSE_CHILD_ORDER_ID,VSE_SERIAL_NUMBER,VSE_TRACKING_NO,
               VSE_SHIP_DATE,VSE_PACKAGE_ID,VSE_PAN,VSE_ERROR_MSG) values
               (p_file_name_in,l_parent_order_id,l_child_order_id,l_serial_number,
                l_tracking_no,l_shipping_datetime,l_package_id,l_pan,l_msg);

                commit;


      end;
      commit;
   END LOOP;
   if p_child_partner_id_out is not null then
   p_child_partner_id_out:=rtrim(p_child_partner_id_out,',');
     end if;
                     
    for loop_cur in (select count(*) as total_count,
                      count(case when vli_status IN ('Completed','Shipped','Rejected') then 1 end) as processed_count,
                      count(case when vli_status='Completed' then 1 end) as  complete_count,
                      count(case when vli_status='Shipped' then 1 end) as shipped_count, 
                      vli_order_id,vli_lineitem_id,vli_partner_id
                     from vms_line_item_dtl where (vli_order_id,vli_lineitem_id,vli_partner_id)in
                     (select dtl.vli_order_id,dtl.vli_lineitem_id,dtl.vli_partner_id from vms_line_item_dtl dtl,table (cast (type_pan_array as SHUFFLE_ARRAY_TYP)) o where 
                   dtl.vli_pan_code = o.column_value ) group by vli_order_id,vli_lineitem_id,vli_partner_id )
   
       loop
       
         BEGIN 
         SELECT DECODE(UPPER(VOD_PRINT_ORDER),'TRUE','P','F') 
         INTO l_print_order
         FROM VMS_ORDER_DETAILS
         WHERE VOD_ORDER_ID = loop_cur.vli_order_id
         AND VOD_PARTNER_ID = loop_cur.vli_partner_id;
                     
         EXCEPTION 
	 WHEN OTHERS THEN 
	 l_msg:='Error while selecting from VMS_ORDER_DETAILS '||substr(sqlerrm,1,200);
        	raise exp_reject_record; 
	 
	 END; 
	 
	 BEGIN
         SELECT vol_order_status 
         INTO l_lineitem_status
         FROM vms_order_lineitem
         where vol_order_id=loop_cur.vli_order_id
                  and vol_line_item_id=loop_cur.vli_lineitem_id
                  and vol_partner_id=loop_cur.vli_partner_id;
         
	 EXCEPTION 
	 WHEN OTHERS THEN 
	 l_msg:='Error while selecting from vms_order_lineitem '||substr(sqlerrm,1,200);
        	raise exp_reject_record; 
	 END;	         
         
         IF 
         loop_cur.total_count=loop_cur.processed_count AND loop_cur.shipped_count>0          
                  then l_update_status := 'Shipped';
         ELSIF
         loop_cur.total_count=loop_cur.processed_count AND loop_cur.complete_count>0
                  then l_update_status := 'Completed';   
         ELSIF
         (loop_cur.shipped_count > 0 OR loop_cur.complete_count > 0) AND l_print_order = 'P'
                  then l_update_status := 'Shipping'; 
         ELSE  
         l_update_status := l_lineitem_status;               
         end if;
                  
          
          
          IF  l_lineitem_status <> l_update_status AND l_lineitem_status <>'Rejected'
          THEN
          
          P_CHILD_PARTNER_ID_OUT :=
                    REPLACE (P_CHILD_PARTNER_ID_OUT,loop_cur.vli_order_id||':'||loop_cur.vli_partner_id||':0',
                                                    loop_cur.vli_order_id||':'||loop_cur.vli_partner_id||':1'); 
          
          END IF;
                  
                  
           
        update vms_order_lineitem
                  set vol_order_status= l_update_status
                  where vol_order_id=loop_cur.vli_order_id
                  and vol_line_item_id=loop_cur.vli_lineitem_id
                  and vol_partner_id=loop_cur.vli_partner_id
                  and vol_order_status<>'Rejected'; 
                 
  /*          
       if loop_cur.total_count=loop_cur.not_processed_count then
            if loop_cur.complete_count=0 then
                  update vms_order_lineitem
                  set vol_order_status='Shipped'
                  where vol_order_id=loop_cur.vli_order_id
                  and vol_line_item_id=loop_cur.vli_lineitem_id
                  and vol_partner_id=loop_cur.vli_partner_id
                  and vol_order_status<>'Rejected';
            end if;

            if loop_cur.shipped_count=0 then
                update vms_order_lineitem
                  set vol_order_status='Completed'
                  where vol_order_id=loop_cur.vli_order_id
                  and vol_line_item_id=loop_cur.vli_lineitem_id
                  and vol_partner_id=loop_cur.vli_partner_id
                  and vol_order_status<>'Rejected';
            end if;

      end if;
      
      
      */

      end loop;

          for loop_cur in (select vol_order_id,vol_partner_id ,
          count(*) as total_count,
          count(case when vol_order_status IN ('Completed','Shipped','Rejected') then 1 end) as processed_count,
          count(case when vol_order_status='Completed' then 1 end) as  complete_count,
          count(case when vol_order_status='Shipped' then 1 end) as shipped_count,
          count(case when vol_order_status='Shipping' then 1 end) as shipping_count
          from vms_order_lineitem where (vol_order_id,vol_partner_id) in    
            (select dtl.vli_order_id,dtl.vli_partner_id from vms_line_item_dtl dtl,table (cast (type_pan_array as shuffle_array_typ)) o where dtl.vli_pan_code 
                   =o.column_value) group by vol_order_id,vol_partner_id )
   
          loop
          
          
          update vms_order_details 
                  set vod_order_status= CASE 
                                        WHEN loop_cur.total_count=loop_cur.processed_count AND loop_cur.shipped_count>0 
                                        THEN 'Shipped'
                                        WHEN loop_cur.total_count=loop_cur.processed_count AND loop_cur.complete_count>0
                                        THEN 'Completed' 
                                        WHEN (loop_cur.shipping_count > 0 or loop_cur.complete_count > 0 or loop_cur.shipped_count > 0 )AND upper(vod_print_order) = 'TRUE'
                                        THEN 'Shipping' 
                                        ELSE vod_order_status 
                                        END 
                  where vod_order_id=loop_cur.vol_order_id
                  and vod_partner_id=loop_cur.vol_partner_id
                  and vod_order_status<>'Rejected';
                  
                  
        /*  
         if loop_cur.total_count=loop_cur.not_processed_count then
            if loop_cur.complete_count=0 then
                  update vms_order_details
                  set vod_order_status='Shipped'
                  where vod_order_id=loop_cur.vol_order_id
                  and vod_partner_id=loop_cur.vol_partner_id
                  and vod_order_status<>'Rejected';
            end if;

            if loop_cur.shipped_count=0 then
                     update vms_order_details
                    set vod_order_status='Completed'
                    where vod_order_id=loop_cur.vol_order_id
                    and vod_partner_id=loop_cur.vol_partner_id
                    and vod_order_status<>'Rejected';

            end if;
	           end if;
        */
       END LOOP;
     
   begin    
   update vms_shipment_fileupload_dtls set vsf_success_reccount=p_success_count_out,
             vsf_failure_reccount=p_failure_count_out where vsf_file_name=p_file_name_in;
    exception
        when others then
             l_msg:='Error while updating data in vms_shipment_fileupload_dtls '||substr(sqlerrm,1,200);
        raise exp_reject_record;
   end;
   
exception
when exp_reject_record then
          rollback;
          p_resp_msg_out:=l_msg;
when others then
          rollback;
          p_resp_msg_out:='Error in main'||substr(sqlerrm,1,200);
end printer_shipmentfile_process;

procedure printer_confirmfile_process(p_inst_code_in in number,p_file_name_in in varchar2,
p_resp_msg_out out varchar2,p_child_partner_id_out out CLOB,
p_success_count_out out number,p_failure_count_out out number) as
l_pan vms_line_item_dtl.vli_pan_code%type;
l_order_id VMS_RESPONSEFILE_DATA_TEMP.vrd_order_id%type;
l_serial_number VMS_RESPONSEFILE_DATA_TEMP.VrD_SERIAL_NUMBER%type;
L_TRACKING_NO   VMS_RESPONSEFILE_DATA_TEMP.VRD_TRACKING_NUMBER%type;
l_date VMS_RESPONSEFILE_DATA_TEMP.vrd_date%type;
l_child_order_partner_id CLOB;
l_partner_id vms_line_item_dtl.vli_partner_id%type;
exp_reject_record exception;
type_pan_array shuffle_array_typ;
l_index number:=0;
l_msg varchar2(300);

cursor   CUR_CONFIRMFILE_PROCESS(P_FILE_NAME varchar2) is select 
         vrd_serial_number,vrd_tracking_number,
        vrd_date from VMS_RESPONSEFILE_DATA_TEMP
          where vrd_file_name=p_file_name
         and vrd_error_desc='Success';
begin
  p_resp_msg_out:='OK';
  type_pan_array :=shuffle_array_typ();
  begin
    select vrf_success_reccount,vrf_failure_reccount 
       into p_success_count_out,p_failure_count_out
       from vms_response_fileupload_dtls where vrf_file_name=p_file_name_in;
     exception
        when others then
            l_msg:='Error while selecting from vms_response_fileupload_dtls '||substr(sqlerrm,1,200);
        raise exp_reject_record;
   end;  
   

    open cur_confirmfile_process(p_file_name_in);

   loop
      fetch cur_confirmfile_process into 
      l_serial_number,l_tracking_no,l_date;
      exit when cur_confirmfile_process%notfound;
      begin
         begin
            select c.cap_pan_code,a.vli_partner_id,a.vli_order_id into l_pan,l_partner_id,l_order_id
            FROM VMS_LINE_ITEM_DTL A,VMS_RESPONSEFILE_DATA_TEMP B,CMS_APPL_PAN C
            WHERE 
              b.VRD_SERIAL_NUMBER=C.CAP_SERIAL_NUMBER
              AND C.CAP_FORM_FACTOR IS NULL
              and c.cap_pan_code=a.vli_pan_code(+)
              and c.cap_inst_code=p_inst_code_in
              and c.CAP_MBR_NUMB='000'
            and b.vrd_serial_number=l_serial_number;
         exception
              when others then
                  l_msg:='Error while getting data from vms_line_item_dtl'||substr(sqlerrm,1,200);
                raise exp_reject_record;
         end;

           begin
                    type_pan_array.extend;
                    l_index:=l_index+1;
                    type_pan_array(l_index):=l_pan;
           exception
                  when others then
                      l_msg:='Error while adding pan to type_pan_array'||substr(sqlerrm,1,200);
                      raise exp_reject_record;
          end;

          begin
            update vms_line_item_dtl
            set  vli_tracking_no=l_tracking_no,
                vli_shipping_datetime=l_date,
                vli_status='Shipped'
            where vli_pan_code=l_pan;
           exception
              when others then
                  l_msg:='Error while updating vms_line_item_dtl'||substr(sqlerrm,1,200);
                raise exp_reject_record;
          end;

          begin
              insert into VMS_RESPONSEFILE_DATA(VRD_BATCH_NUMBER,VRD_CARRIER,
              VRD_CASE_NUMBER,VRD_ORDER_ID,VRD_CITY,VRD_DATE,VRD_DC_ID,
              VRD_ERROR_DESC,VRD_FILE_NAME,VRD_INST_CODE,VRD_INS_DATE,
              VRD_INS_USER,VRD_LUPD_DATE,VRD_LUPD_USER,VRD_MAGIC_NUMBER,
              VRD_MERCHANT_ID,VRD_MERCHANT_NAME,VRD_PALLET_NUMBER,
              VRD_PARENT_SERIAL_NUMBER,VRD_PROCESS_FLAG,
              VRD_PROD_ID,VRD_ROW_ID,VRD_SERIAL_NUMBER,VRD_SHIP_TO,VRD_STATE,
              VRD_STATUS,VRD_STORELOCATIONID,VRD_STREET_ADDR1,VRD_STREET_ADDR2,
              VRD_TRACKING_NUMBER,VRD_ZIP) select VRD_BATCH_NUMBER,VRD_CARRIER,
              VRD_CASE_NUMBER,VRD_ORDER_ID,VRD_CITY,VRD_DATE,VRD_DC_ID,
              VRD_ERROR_DESC,VRD_FILE_NAME,VRD_INST_CODE,VRD_INS_DATE,
              VRD_INS_USER,VRD_LUPD_DATE,VRD_LUPD_USER,VRD_MAGIC_NUMBER,
              VRD_MERCHANT_ID,VRD_MERCHANT_NAME,VRD_PALLET_NUMBER,
              VRD_PARENT_SERIAL_NUMBER,VRD_PROCESS_FLAG,
              VRD_PROD_ID,VRD_ROW_ID,VRD_SERIAL_NUMBER,VRD_SHIP_TO,VRD_STATE,
              VRD_STATUS,VRD_STORELOCATIONID,VRD_STREET_ADDR1,VRD_STREET_ADDR2,
              VRD_TRACKING_NUMBER,VRD_ZIP from VMS_RESPONSEFILE_DATA_TEMP
              where vrd_serial_number=l_serial_number;
          exception
              when others then
                   l_msg:='Error while moving data from VMS_RESPONSEFILE_DATA_TEMP to
                    VMS_RESPONSEFILE_DATA'||substr(sqlerrm,1,200);
                  raise exp_reject_record;
          end;

        if l_order_id is not null and l_partner_id is not null then
           begin
                l_child_order_partner_id:=l_order_id||':'||l_partner_id;
                
              if length (nvl(p_child_partner_id_out,' ')) = length(replace (nvl(p_child_partner_id_out,' '),l_child_order_partner_id,'')) 
                then
              p_child_partner_id_out:=p_child_partner_id_out||l_child_order_partner_id||',';
              
              end if;

           exception
              when others then
                   l_msg:='Error while getting child order id from VMS_RESPONSEFILE_DATA_TEMP'||substr(sqlerrm,1,200);
                  raise exp_reject_record;
          END;
          end if;
      exception
          when exp_reject_record then
              rollback;
              
              p_success_count_out := p_success_count_out - 1;
              p_failure_count_out := p_failure_count_out + 1;
              insert into VMS_RESPONSEFILE_ERROR_DATA(vre_file_name,vre_order_id,
                vre_serial_number,vre_tracking_number,vre_date,vre_pan,vre_error_msg)
                values(p_file_name_in,l_order_id,l_serial_number,
                                           l_tracking_no,l_date,l_pan,l_msg);
              commit;
          when others then
              rollback;

              p_success_count_out := p_success_count_out - 1;
              p_failure_count_out := p_failure_count_out + 1;
              insert into VMS_RESPONSEFILE_ERROR_DATA(vre_file_name,vre_order_id,
                vre_serial_number,vre_tracking_number,vre_date,vre_pan,vre_error_msg)
                values(p_file_name_in,l_order_id,l_serial_number,
                                           l_tracking_no,l_date,l_pan,l_msg);
              commit;
      end;

      commit;
   END LOOP;
   if p_child_partner_id_out is not null then
   p_child_partner_id_out:=rtrim(p_child_partner_id_out,',');
  end if;

      for loop_cur in (select count(case when dtl.vli_status<>'Shipped' then 1 end) as cnt,
                      dtl.vli_order_id,dtl.vli_lineitem_id,dtl.vli_partner_id
                     from vms_line_item_dtl dtl,table (cast (type_pan_array as SHUFFLE_ARRAY_TYP)) o where dtl.vli_pan_code=o.column_value
                        group by dtl.vli_order_id,dtl.vli_lineitem_id,dtl.vli_partner_id )
       loop
          if loop_cur.cnt=0 then
                update vms_order_lineitem
                set vol_order_status='Shipped'
                where vol_order_id=loop_cur.vli_order_id
                and vol_line_item_id=loop_cur.vli_lineitem_id
                and vol_partner_id=loop_cur.vli_partner_id;
          end if;
        end loop;

        for loop_cur in (select count(case when vol_order_status<>'Shipped' then 1 end) as cnt,vol_order_id,
        vol_partner_id from vms_order_lineitem
        group by vol_order_id,vol_partner_id)
        loop


          if loop_cur.cnt=0 then
                update vms_order_details
                set vod_order_status='Shipped'
                where vod_order_id=loop_cur.vol_order_id
                and vod_partner_id=loop_cur.vol_partner_id;
          end if;

       END LOOP;
       
       begin    
       update vms_response_fileupload_dtls set vrf_success_reccount=p_success_count_out,
             vrf_failure_reccount=p_failure_count_out where vrf_file_name=p_file_name_in;
       exception
           when others then
                  l_msg:='Error while updating data in vms_response_fileupload_dtls '||substr(sqlerrm,1,200);
           raise exp_reject_record;
       end;

exception
when exp_reject_record then
          rollback;
          p_resp_msg_out:=l_msg;
when others then
          rollback;
          p_resp_msg_out:='Error in main'||substr(sqlerrm,1,200);
end printer_confirmfile_process;

procedure SERIAL_NUMBER_FILE_PROCESS(P_INST_CODE_IN in number,P_FILE_NAME_IN in varchar2,p_resp_msg_out out varchar2) as
l_cnt number;
l_product_id vms_serial_details_temp.VSD_PRODUCT_ID%type;
l_max_serial_number vms_serial_details_temp.vsd_serial_number%type;
l_min_serial_number vms_serial_details_temp.vsd_serial_number%type;
exp_reject_record exception;
l_msg varchar2(300);
l_success_count vms_serial_fileupload_dtls.vsf_success_reccount%type;
l_failure_count vms_serial_fileupload_dtls.vsf_failure_reccount%type;


CURSOR cur_snfile_process IS
select distinct VSD_PRODUCT_ID VSD_PRODUCT_ID from vms_serial_details_temp
      where VSD_FILE_NAME=p_file_name_in
      AND VSD_ERROR_DESC='Success';


begin
p_resp_msg_out:='OK';

     begin
     select vsf_success_reccount,vsf_failure_reccount 
       into l_success_count,l_failure_count
       from vms_serial_fileupload_dtls where vsf_file_name=p_file_name_in;
       exception
           when others then
                  l_msg:='Error while selecting data from vms_serial_fileupload_dtls '||substr(sqlerrm,1,200);
           raise exp_reject_record;
       end;
       
     open cur_snfile_process;

      loop
      begin
        fetch cur_snfile_process into l_product_id;
        exit when cur_snfile_process%notfound;

        begin
          select min(vsd_serial_number),max(vsd_serial_number)
          into l_min_serial_number,l_max_serial_number
            from vms_serial_details_temp
          where vsd_product_id=l_product_id;

        exception
            WHEN OTHERS THEN
              l_msg:='Error while selecting data from VMS_SERIAL_DETAILS_TEMP'||substr(sqlerrm,1,200);
              raise exp_reject_record;
       end;

       begin
          select NVL(SUM (CASE WHEN (VPS_START_SERL BETWEEN l_min_serial_number  AND l_max_serial_number) OR
                                    (VPS_END_SERL between l_min_serial_number  and l_max_serial_number) OR
                                    (l_min_serial_number  BETWEEN VPS_START_SERL + 1 AND VPS_END_SERL - 1) OR
                                    (l_max_serial_number  BETWEEN VPS_START_SERL + 1 AND VPS_END_SERL - 1)
           THEN 1  else 0 end) ,0) into  l_cnt from  VMS_PRODUCT_SERIAL_CNTRL ;
         exception
            WHEN OTHERS THEN
              l_msg:='Error while checking VMS_PRODUCT_SERIAL_CNTRL '||substr(sqlerrm,1,200);
              raise exp_reject_record;
       end;

       if l_cnt <> 0 then
         l_msg:='Serial Number should not be over lapped-'||l_max_serial_number||'-'||l_max_serial_number;
          raise exp_reject_record;
       end if;

        begin
          insert into vms_product_serial_cntrl(VPS_PRODUCT_ID,VPS_START_SERL,VPS_END_SERL,VPS_SERL_NUMB,VPS_SEQ_NO)
          values(l_product_id,l_min_serial_number,l_max_serial_number,l_min_serial_number,NVL((SELECT MAX(VPS.VPS_SEQ_NO)+1  FROM VMS_PRODUCT_SERIAL_CNTRL VPS where VPS.VPS_PRODUCT_ID=l_product_id),1));

        exception
            WHEN OTHERS THEN
              l_msg:='Error while insert vms_product_serial_cntrl'||substr(sqlerrm,1,200);
              raise exp_reject_record;
        end;

         begin
            update VMS_SERIAL_NUM_AUDIT
                set vsa_serialreq_status='Y'  where vsa_product_id=l_product_id and vsa_serialreq_status='N';
             exception
                  WHEN OTHERS THEN
              l_msg:='Error while update  VMS_SERIAL_NUM_AUDIT'||substr(sqlerrm,1,200);
              raise exp_reject_record;
        end;

        begin
            insert into VMS_SERIAL_DETAILS(VSD_INST_CODE,VSD_FILE_NAME,VSD_PRODUCT_ID,
          VSD_SERIAL_NUMBER,VSD_VAN16,VSD_PROCESS_FLAG,VSD_ROW_ID,VSD_ERROR_DESC,
          VSD_INS_USER,VSD_INS_DATE,VSD_LUPD_USER,VSD_LUPD_DATE)
              select VSD_INST_CODE,VSD_FILE_NAME,VSD_PRODUCT_ID,
          VSD_SERIAL_NUMBER,VSD_VAN16,VSD_PROCESS_FLAG,VSD_ROW_ID,VSD_ERROR_DESC,
          VSD_INS_USER,sysdate,VSD_LUPD_USER,sysdate
          from VMS_SERIAL_DETAILS_TEMP
          WHERE vsd_product_id=l_product_id;

          exception
              WHEN OTHERS THEN
                  L_MSG:='Error while moving data from VMS_SERIAL_DETAILS_TEMP to
                  VMS_SERIAL_DETAILS table'||substr(sqlerrm,1,200);
                  raise exp_reject_record;
        end;

        exception
        when exp_reject_record then
            ROLLBACK;

          update VMS_SERIAL_DETAILS_TEMP
          set VSD_ERROR_DESC=L_MSG
          WHERE vsd_product_id=l_product_id;
          l_success_count := l_success_count - 1;
          l_failure_count := l_failure_count + 1;

        INSERT INTO VMS_SERIALFILE_ERROR_DATA(VSD_FILE_NAME,VSD_PRODUCT_ID,VSD_SERIAL_NUMBER,VSD_ERROR_MESSAGE,
         VSD_INS_DATE) VALUES(P_FILE_NAME_IN,l_product_id,l_min_serial_number,l_msg,sysdate);

        commit;
        when others then
        rollback;

        l_success_count := l_success_count - 1;
        l_failure_count := l_failure_count + 1;
        INSERT INTO VMS_SERIALFILE_ERROR_DATA(VSD_FILE_NAME,VSD_PRODUCT_ID,VSD_SERIAL_NUMBER,VSD_ERROR_MESSAGE,
          VSD_INS_DATE) VALUES(P_FILE_NAME_IN,l_product_id,l_min_serial_number,l_msg,sysdate);

        commit;
      end;

      commit;
      end loop;
      
      begin
      update vms_serial_fileupload_dtls set vsf_success_reccount=l_success_count,
             vsf_failure_reccount=l_failure_count where vsf_file_name=p_file_name_in;
       exception
           when others then
                  l_msg:='Error while updating data in vms_serial_fileupload_dtls '||substr(sqlerrm,1,200);
           raise exp_reject_record;
       end;      

exception
    when exp_reject_record then
         rollback;
    when others then
        rollback;
        P_RESP_MSG_OUT:='Error in main'||SUBSTR(SQLERRM,1,200);
END SERIAL_NUMBER_FILE_PROCESS;


end vmsfileprocess;
/
show error