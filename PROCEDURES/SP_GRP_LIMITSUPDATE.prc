CREATE OR REPLACE PROCEDURE VMSCMS.SP_GRP_LIMITSUPDATE  (
   prm_instcode   IN       NUMBER,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
) IS    


ERRMSG_1 VARCHAR2(100);


excep_callimit exception;
v_txn_code               VARCHAR2 (2);
v_txn_type               VARCHAR2 (2);
v_txn_mode               VARCHAR2 (2);
v_del_channel            VARCHAR2 (2);
v_csr_spprt_rsncode      cms_spprt_reasons.csr_spprt_rsncode% type;
V_ins_user cms_func_mast.cfm_ins_user%type;
V_inst_date cms_func_mast.cfm_inst_date%type; 
V_inst_code cms_func_mast.cfm_inst_code%type;
v_resoncode CMS_SPPRT_REASONS.csr_spprt_rsncode%type;  
v_reasondesc CMS_SPPRT_REASONS.csr_reasondesc%type;
              


   
CURSOR C  IS
SELECT CGL_INST_CODE,
CGL_CARD_NO,
CUL_ATM_ONLINE_LIMIT,
CUL_POS_ONLINE_LIMIT,
CUL_ATM_OFFLINE_LIMIT,
CUL_POS_OFFLINE_LIMIT,
CGL_REMARKS,
CGL_INS_USER,
CGL_MBR_NUMB
FROM CMS_GROUP_limitupdate_TEMP
WHERE cgl_process_flag = 'N'
and CGL_INST_CODE=prm_instcode;
   
   
  BEGIN -- MAIN BEGIN STARTS HERE
    
  ERRMSG_1 :='OK';
  
        begin 
            select csr_spprt_rsncode into v_csr_spprt_rsncode 
            from cms_spprt_reasons
            where csr_spprt_key='LIMT'
            and CSR_INST_CODE=prm_instcode;
         
        exception when no_data_found then 
        ERRMSG_1 := 'no supprt reason code found in cms_supprt_reason';
        raise excep_callimit;
        when others then
        ERRMSG_1 := 'Error occured---> '||' '||SQLCODE||''||substr(SQLERRM,1,300);
        raise excep_callimit;
        
        end;   
        
        begin -- begin 001 starts here 
          
                SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type,CFM_INS_USER,CFM_INST_DATE,CFM_INST_CODE
                INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type,V_ins_user,V_inst_date,V_inst_code
                FROM CMS_FUNC_MAST
                WHERE cfm_func_code = 'LIMT'
                and CFM_INST_CODE=prm_instcode;
           
               EXCEPTION WHEN NO_DATA_FOUND THEN ---exception 001 starts here  
               ERRMSG_1 := 'no details found in cms_func_mast';
               raise excep_callimit;
               when others then 
               ERRMSG_1 := 'Excep_001--->'||' '||SQLCODE||' '||SQLERRM;---exception 001 ends here
               raise excep_callimit;
           
           end;--begin 001 ends here    
           
           
           --========================
           
              BEGIN
              
             SELECT csr_spprt_rsncode,csr_reasondesc
                     INTO v_resoncode, v_reasondesc
              FROM CMS_SPPRT_REASONS
             WHERE csr_spprt_key = 'LIMT' and CSR_INST_CODE=prm_instcode AND ROWNUM < 2;
             
            EXCEPTION
            WHEN VALUE_ERROR
            THEN
          errmsg_1 := 'Hotlist  reason code not present in master ';
          RAISE excep_callimit;
            WHEN NO_DATA_FOUND
            THEN
            errmsg_1 := 'Hotlist  reason code not present in master';
            RAISE excep_callimit;
       WHEN OTHERS
       THEN
          errmsg_1 :=
                'Error while selecting reason code from master'
             || SUBSTR (SQLERRM, 1, 200);
          RAISE excep_callimit;
    END;
           --==========================         
  
        -- processing multiple limit values in loops by calling procedure  

   FOR I IN C LOOP---loop starts here
   exit when C%notfound;
                    
                
                    SP_CHECK_LIMITS(i.cgl_inst_code,i.cul_atm_online_limit,i.cul_atm_offline_limit,i.cul_pos_online_limit,i.cul_pos_offline_limit,i.cgl_card_no,i.cgl_mbr_numb,v_csr_spprt_rsncode,i.cgl_remarks,i.cgl_ins_user,i.cgl_ins_user,errmsg_1);
                    
                     if ERRMSG_1='OK' then 
          
           insert into process_audit_log (PAL_CARD_NO,
                                       PAL_ACTIVITY_TYPE,
                                       PAL_TRANSACTION_CODE,
                                       PAL_DELV_CHNL,
                                       pal_tran_amt, 
                                       pal_source,
                                       PAL_INS_USER,
                                       PAL_INS_DATE,
                                       PAL_INST_CODE,
                                       PAL_SUCCESS_FLAG,
                                       PAL_PROCESS_MSG,
                                       pal_reason_desc,
                                       PAL_ATM_ONLINT_LIMIT,
                                       PAL_ATM_OFFLINT_LIMIT,
                                       PAL_POS_ONLINT_LIMIT,
                                       PAL_POS_OFFLINT_LIMIT,
                                       pal_remarks,
                                       pal_spprt_type
                                       )
           VALUES(                     i.cgl_card_no,
                                       'GROUP LIMIT UPDATE',
                                       v_txn_code,
                                       v_del_channel,
                                       0,
                                       'HOST',
                                       V_INS_USER,
                                       V_INST_DATE,
                                       V_INST_CODE,
                                       'S',
                                       'SUCCESSFUL',
                                       v_reasondesc,
                                       i.cul_atm_online_limit,
                                       i.cul_atm_offline_limit,
                                       i.cul_pos_online_limit,
                                       i.cul_pos_offline_limit,
                                       i.CGL_REMARKS,
                                       'G'
                  );                     
           
           
           update cms_group_limitupdate_temp
             set    CGL_PROCESS_FLAG ='S',
                    CGL_PROCESS_MSG  ='SUCCESSFUL'
                    where  CGL_PROCESS_FLAG ='N'
                    and CGL_CARD_NO=i.CGL_CARD_NO;
                   
                   
            insert into CMS_LIMITUPDATE_DETAIL (CLD_INST_CODE,    
                                                CLD_CARD_NO,        
                                                CLD_FILE_NAME,        
                                                CLD_REMARKS,        
                                                CLD_PROCESS_FLAG,    
                                                CLD_PROCESS_MSG,    
                                                CLD_INS_USER,    
                                                CLD_INS_DATE,
                                                CLD_ATM_ONLINE_LIMIT,
                                                CLD_ATM_OFFLINE_LIMIT,
                                                CLD_POS_ONLINE_LIMIT,
                                                CLD_POS_OFFLINE_LIMIT,
                                                CLD_MSG24_FLAG,
                                                CLD_PROCESS_MODE,
                                                CLD_LUPD_DATE
                                                )
                                         select CGL_INST_CODE,
                                                CGL_CARD_NO,
                                                CGL_FILE_NAME,
                                                CGL_REMARKS,
                                                CGL_PROCESS_FLAG,
                                                CGL_PROCESS_MSG,
                                                CGL_INS_USER,
                                                CGL_INS_DATE,
                                                CUL_ATM_ONLINE_LIMIT,
                                                CUL_ATM_OFFLINE_LIMIT,
                                                CUL_POS_ONLINE_LIMIT,
                                                CUL_POS_OFFLINE_LIMIT,
                                                'N',
                                                'G',
                                                SYSDATE
                                         FROM cms_group_limitupdate_temp
                                         WHERE CGL_PROCESS_FLAG='S'
                                         and CGL_CARD_NO =i.CGL_CARD_NO;
           
           
           else 
           
           insert into process_audit_log (PAL_CARD_NO,
                                       PAL_ACTIVITY_TYPE,
                                       PAL_TRANSACTION_CODE,
                                       PAL_DELV_CHNL,
                                       pal_tran_amt, 
                                       pal_source,
                                       PAL_INS_USER,
                                       PAL_INS_DATE,
                                       PAL_INST_CODE,
                                       PAL_SUCCESS_FLAG,
                                       PAL_PROCESS_MSG,
                                       pal_reason_desc,
                                       PAL_ATM_ONLINT_LIMIT,
                                       PAL_ATM_OFFLINT_LIMIT,
                                       PAL_POS_ONLINT_LIMIT,
                                       PAL_POS_OFFLINT_LIMIT,
                                       pal_remarks,
                                       pal_spprt_type
                                       )
           VALUES(                     i.cgl_card_no,
                                       'GROUP LIMIT UPDATE',
                                       v_txn_code,
                                       v_del_channel,
                                       0,
                                       'HOST',
                                       V_INS_USER,
                                       V_INST_DATE,
                                       V_INST_CODE,
                                       'E',
                                       substr(errmsg_1,1,300),
                                       v_reasondesc,
                                       i.cul_atm_online_limit,
                                       i.cul_atm_offline_limit,
                                       i.cul_pos_online_limit,
                                       i.cul_pos_offline_limit,
                                       i.CGL_REMARKS,
                                       'G'
                  );  
           
           update cms_group_limitupdate_temp
             set    CGL_PROCESS_FLAG ='E',
                    CGL_PROCESS_MSG  = SUBSTR(ERRMSG_1,1,300)
                    where  CGL_PROCESS_FLAG ='N'
                    and CGL_CARD_NO=i.CGL_CARD_NO;
                    
                      insert into CMS_LIMITUPDATE_DETAIL (CLD_INST_CODE,    
                                                CLD_CARD_NO,        
                                                CLD_FILE_NAME,        
                                                CLD_REMARKS,        
                                                CLD_PROCESS_FLAG,    
                                                CLD_PROCESS_MSG,    
                                                CLD_INS_USER,    
                                                CLD_INS_DATE,
                                                CLD_ATM_ONLINE_LIMIT,
                                                CLD_ATM_OFFLINE_LIMIT,
                                                CLD_POS_ONLINE_LIMIT,
                                                CLD_POS_OFFLINE_LIMIT,
                                                CLD_MSG24_FLAG,
                                                CLD_PROCESS_MODE,
                                                CLD_LUPD_DATE
                                                )
                                         select CGL_INST_CODE,
                                                CGL_CARD_NO,
                                                CGL_FILE_NAME,
                                                CGL_REMARKS,
                                                CGL_PROCESS_FLAG,
                                                CGL_PROCESS_MSG,
                                                CGL_INS_USER,
                                                CGL_INS_DATE,
                                                CUL_ATM_ONLINE_LIMIT,
                                                CUL_ATM_OFFLINE_LIMIT,
                                                CUL_POS_ONLINE_LIMIT,
                                                CUL_POS_OFFLINE_LIMIT,
                                                'N',
                                                'G',
                                                SYSDATE
                                         FROM cms_group_limitupdate_temp
                                         WHERE CGL_PROCESS_FLAG='E'
                                         and CGL_CARD_NO =i.CGL_CARD_NO;
                    
           
           
        end if;
          
   END LOOP;---loop ends here
     
             dbms_output.put_line(ERRMSG_1);
     
        prm_errmsg := ERRMSG_1;
    
        dbms_output.put_line('last exception');
    
        EXCEPTION WHEN excep_callimit THEN
        prm_errmsg := ERRMSG_1;
        dbms_output.put_line('inside last exception'||' '||prm_errmsg);
        when others then 
        prm_errmsg := 'Error Occured --->'||SQLCODE||' '||substr(SQLERRM,1,300);
        
 

END;-- MAIN BEGIN ENDS HERE;
/


