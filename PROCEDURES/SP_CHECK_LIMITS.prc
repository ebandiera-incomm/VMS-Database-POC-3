CREATE OR REPLACE PROCEDURE VMSCMS.sp_check_limits (
                                                v_instcode in number,
												v_Online_ATM_Limit in cms_APPL_PAN.CAP_ATM_ONLINE_LIMIT%type,
                                                v_Offline_ATM_Limit in cms_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%type,
                                                v_Online_POS_Limit in cms_APPL_PAN.CAP_POS_ONLINE_LIMIT%type,
                                                v_Offline_POS_Limit in cms_APPL_PAN.CAP_POS_OFFLINE_LIMIT%type,
                                                v_CAP_PAN_CODE in  cms_appl_pan.CAP_PAN_CODE%type,
                                                v_mbrnumb in CMS_PAN_SPPRT.CPS_MBR_NUMB%type,
                                                v_csr_spprt_rsncode cms_spprt_reasons.csr_spprt_rsncode%type,
                                                v_cgl_remarks CMS_GROUP_limitupdate_TEMP.cgl_remarks%type,
                                                v_cgl_ins_user CMS_GROUP_limitupdate_TEMP.cgl_ins_user%type,
                                                v_lupduser number,
                                                v_errmsg out varchar2
)as


errmsg varchar2(1000);


v_cap_prod_catg cms_appl_pan.CAP_PROD_CATG%type;
v_CAP_PROD_CODE cms_appl_pan.CAP_PROD_CODE%type;
v_CAP_CARD_TYPE cms_appl_pan.CAP_CARD_TYPE%type; 
v_CPC_PROFILE_CODE cms_bin_param.CbP_PROFILE_CODE%TYPE;
v_CPM_PROFILE_CODE cms_prod_mast.CPM_PROFILE_CODE%type;

online_atm_limit  cms_bin_param.cbp_param_value%type;
offline_atm_limit cms_bin_param.cbp_param_value%type;
online_pos_limit  cms_bin_param.cbp_param_value%type;
offline_pos_limit  cms_bin_param.cbp_param_value%type;

excep_1 exception;

begin -- MAIN BEGIN STARTS HERE

v_errmsg:='OK';



if v_CAP_PAN_CODE is not null then

-- Sn1 : select prod code and card type cms_appl_pan.

begin --- '2ND BEGIN BLOCK STARTS HERE'


select CAP_PROD_CODE,CAP_CARD_TYPE,CAP_PROD_CATG into v_CAP_PROD_CODE,v_CAP_CARD_TYPE,v_cap_prod_catg 
from cms_appl_pan
where CAP_PAN_CODE = v_CAP_PAN_CODE
and CAP_INST_CODE=v_instcode;



EXCEPTION WHEN NO_DATA_FOUND THEN----EXCEPTION FOR 2ND BEGIN STARTS HERE
errmsg :='no product code and card type found from cms_appl_pan' ;
raise excep_1;

WHEN OTHERS THEN 
errmsg :='ERROR OCCURED IN 2ND BEGIN BLOCK WHILE GETTING PROD CODE AND CARD TYPE----->'||SQLCODE||' '||SQLERRM ;----EXCEPTION FOR 2ND BEGIN ENDS HERE
raise excep_1;


END ;--- '2ND BEGIN BLOCK ENDS HERE '

else 

errmsg :='Incorrect PAN Number';
raise excep_1;

end if;



-- Sn1 : select ends.


--Sn2 : select profile code from cms_prod_cattype from cms_prod_cattype.

begin ----  begin 002 starts here

select  CPC_PROFILE_CODE into v_CPC_PROFILE_CODE
from cms_prod_cattype
WHERE cpc_prod_code=v_CAP_PROD_CODE
and CPC_CARD_TYPE=v_CAP_CARD_TYPE
and CPC_INST_CODE=v_instcode;

EXCEPTION WHEN NO_DATA_FOUND THEN

--Sn3 : selecting profile code from  CMS_PROD_MAST based on product code and instcode

begin --- begin 006 starts here

select CPM_PROFILE_CODE into v_CPM_PROFILE_CODE 
from cms_prod_mast
where cpm_prod_code=v_CAP_PROD_CODE
and CPM_INST_CODE=v_instcode;

EXCEPTION WHEN NO_DATA_FOUND THEN
errmsg :='no profile code found for prod code ='||' '||v_CAP_PROD_CODE||' '|| 'and inst code='||' '||v_instcode;
raise excep_1;

WHEN OTHERS THEN
errmsg := 'error occured while getting profile code in begin 006 ---->'||' '||sqlcode||'-------'||sqlerrm;
raise excep_1;

end;-- begin 006 ends here

--Sn3 : selecting ends here



--Sn4: select online atm limit from cms_bin_param

begin --- begin 007 starts here

select cbp_param_value into online_atm_limit
from cms_bin_param
where CBP_PROFILE_CODE =v_CPM_PROFILE_CODE
and CBP_INST_CODE=v_instcode
and CBP_PARAM_NAME in ('Online ATM Limit');

EXCEPTION WHEN NO_DATA_FOUND THEN
errmsg :='no online limit found inside begin 007 for profile code ='||' '||v_CPM_PROFILE_CODE;
raise excep_1;

WHEN OTHERS THEN
errmsg := 'error occured while getting online_atm_limit in begin 007---->'||' '||sqlcode||'-------'||sqlerrm;
raise excep_1;

end;-- begin 007 ends here

--Sn4: select ends here


---Sn5: check online atm limit with input value for same.

IF NVL(v_online_atm_limit,0) != 0 THEN 


if  TO_NUMBER(online_atm_limit) >= TO_NUMBER(v_online_atm_limit) then


errmsg:='OK';
dbms_output.put_line ( 'INSIDE BEGIN 1.2.1-->online atm limit is correct ='||' '|| v_online_atm_limit);

else 

errmsg :='online atm limit is beyond predefined limit ='||' '|| v_online_atm_limit;
raise excep_1;

end if;

ELSE 

errmsg :='Enter proper online Atm Limit';
raise excep_1;

end if;

---Sn5: check check ends here.


--Sn6: select offline atm limit from cms_bin_param

begin --- begin 008 starts here

select cbp_param_value into offline_atm_limit from cms_bin_param
where CBP_PROFILE_CODE =v_CPM_PROFILE_CODE
and CBP_INST_CODE=v_instcode
and CBP_PARAM_NAME in ('Offline ATM Limit');

EXCEPTION WHEN NO_DATA_FOUND THEN
errmsg :='no offline limit found in begin 008 for profile code ='||' '||v_CPM_PROFILE_CODE;
raise excep_1;

WHEN OTHERS THEN
errmsg := 'error occured while getting offline_atm_limit in begin 008 ---->'||' '||sqlcode||'-------'||sqlerrm;
raise excep_1;

end;-- begin 008 ends here

--Sn6: select ends here



---Sn7: check offline atm limit with input value for same.

IF NVL(v_offline_atm_limit,0) != 0 THEN

if  TO_NUMBER(offline_atm_limit) >= TO_NUMBER(v_offline_atm_limit) then


errmsg:='OK';
dbms_output.put_line ( 'offline atm limit is correct ='||' '|| v_offline_atm_limit);

else 

errmsg :='offline atm limit is beyond predefined limit ='||' '|| v_online_atm_limit;
raise excep_1;

end if;

else 

errmsg :='Enter proper offline Atm Limit';
raise excep_1;

end if;
---Sn7: check ends here.


--Sn8: select online pos limit from cms_bin_param

begin --- begin 009 starts here

select cbp_param_value into online_pos_limit 
from cms_bin_param
where CBP_PROFILE_CODE =v_CPM_PROFILE_CODE
and CBP_INST_CODE=v_instcode
and CBP_PARAM_NAME in ('Online POS Limit');

EXCEPTION WHEN NO_DATA_FOUND THEN
errmsg :='no online pos limit found for profile code ='||' '||v_CPM_PROFILE_CODE;
raise excep_1;

WHEN OTHERS THEN
errmsg := 'error occured ---->'||' '||sqlcode||'-------'||sqlerrm;
raise excep_1;

end;-- begin 009 ends here

--Sn8: select ends here



---Sn9: check offline atm limit with input value for same.

if nvl(v_online_pos_limit,0) != 0 then

if  TO_NUMBER(online_pos_limit) >= TO_NUMBER(v_online_pos_limit) then


errmsg:='OK';
dbms_output.put_line ( 'online pos limit is correct ='||' '|| v_online_pos_limit);

else 

errmsg :='online pos limit is beyond predefined limit ='||' '|| v_online_pos_limit;
raise excep_1;

end if;

else 

errmsg :='Enter proper online pos Limit';
raise excep_1;

end if;

---Sn9: check ends here.


--Sn10: select offline pos limit from cms_bin_param

begin --- begin 0010 starts here

select cbp_param_value into offline_pos_limit from cms_bin_param
where CBP_PROFILE_CODE =v_CPM_PROFILE_CODE
and CBP_INST_CODE=v_instcode
and CBP_PARAM_NAME in ('Offline POS Limit');

EXCEPTION WHEN NO_DATA_FOUND THEN
errmsg :='no offline pos limit found for profile code ='||' '||v_CPM_PROFILE_CODE;
raise excep_1;

WHEN OTHERS THEN
errmsg := 'error occured ---->'||' '||sqlcode||'-------'||sqlerrm;
raise excep_1;

end;-- begin 0010 ends here

--Sn10: select ends here. 


---Sn11 :  check offline atm limit with input value for same.

if nvl(v_offline_pos_limit,0)!=0 then

if  TO_NUMBER(offline_pos_limit) >= TO_NUMBER(v_offline_pos_limit) then


errmsg:='OK';
dbms_output.put_line ( 'offline pos limit is correct ='||' '|| v_offline_pos_limit);

else 

errmsg :='offline pos limit is beyond predefined limit ='||' '|| v_online_atm_limit;
raise excep_1;

end if;

else 

errmsg :='Enter proper offline pos Limit';
raise excep_1;

end if;---Sn11 :  check ends here.


----updating CMS_APPL_PAN for aggrigate limits 

IF errmsg ='OK' THEN 

BEGIN ---- BEGIN FOR INNER UPDATE STARTS HERE

savepoint ONE;

update cms_appl_pan 
set CAP_ONLINE_AGGR_LIMIT  =  nvl(TO_NUMBER(v_online_atm_limit),0)  +  nvl(TO_NUMBER(v_online_pos_limit),0),
    CAP_OFFLINE_AGGR_LIMIT =  nvl(TO_NUMBER(v_offline_atm_limit),0) + nvl(TO_NUMBER(v_offline_pos_limit),0),
    CAP_ATM_OFFLINE_LIMIT  =  nvl(TO_NUMBER(v_offline_atm_limit),0), 
    CAP_ATM_ONLINE_LIMIT   =  nvl(TO_NUMBER(v_online_atm_limit),0), 
    CAP_POS_OFFLINE_LIMIT  =  nvl(TO_NUMBER(v_offline_pos_limit),0), 
    CAP_POS_ONLINE_LIMIT   =  nvl(TO_NUMBER(v_online_pos_limit),0)
where CAP_PAN_CODE =v_CAP_PAN_CODE
and CAP_INST_CODE =v_instcode;

IF SQL%ROWCOUNT = 0 THEN
errmsg := 'no rows affected after INNER update'; 
RAISE EXCEP_1;
ELSE
errmsg:='OK'; 
END IF;

exception when EXCEP_1 then raise;
when others then 
errmsg := 'Problem Occured During Inner Updation----->'||' '||SQLCODE||' '||SQLERRM;
rollback to savepoint ONE;  

end; ---- BEGIN FOR INNER UPDATE ENDS HERE

end if;



WHEN OTHERS THEN 
errmsg :=' errror occured while fetching profile code from cms_prod_catype in begin 002 = ' ||' '||sqlcode||' '||sqlerrm;
raise excep_1;

end;--- begin 002 ends here 

--Sn2 : select ends here.



--Sn12 : select online atm limit from  cms_bin_param

begin -- begin 003 starts here 

select cbp_param_value into online_atm_limit
from cms_bin_param
where CBP_PROFILE_CODE =v_CPC_PROFILE_CODE
and CBP_INST_CODE=v_instcode
and CBP_PARAM_NAME in ('Online ATM Limit');

EXCEPTION WHEN NO_DATA_FOUND THEN
errmsg :='no online atm limit found inside begin 003 for profile code ='||' '||v_CPC_PROFILE_CODE;
raise excep_1;

WHEN OTHERS THEN
errmsg := 'error occured ---->'||' '||sqlcode||'-------'||sqlerrm;
raise excep_1;

end;-- begin 003 ends here

--Sn12 : select ends here.


---Sn13 :  check online atm limit with input value for same.

if nvl(v_online_atm_limit,0)!=0 then

if  TO_NUMBER(online_atm_limit) >= TO_NUMBER(v_online_atm_limit) then


errmsg :='OK';
dbms_output.put_line ( 'online atm limit is correct ='||' '|| v_online_atm_limit);

else 

errmsg :='online atm limit is beyond predefined limit ='||' '|| v_online_atm_limit;
raise excep_1;

end if;

else 

errmsg :='Enter proper online atm Limit';
raise excep_1;

end if;

---Sn13 :  check ends here.


--Sn14 : select offline atm limit from  cms_bin_param

begin -- begin 004 starts here 

select cbp_param_value into offline_atm_limit 
from cms_bin_param
where CBP_PROFILE_CODE =v_CPC_PROFILE_CODE
and CBP_INST_CODE=v_instcode
and CBP_PARAM_NAME in ('Offline ATM Limit');


EXCEPTION WHEN NO_DATA_FOUND THEN
errmsg :='no offline atm limit found inside begin 004 for profile code ='||' '||v_CPC_PROFILE_CODE;
raise excep_1;

WHEN OTHERS THEN
errmsg := 'error occured inside begin 004 ---->'||' '||sqlcode||'-------'||sqlerrm;
raise excep_1;

end;-- begin 004 ends here

--Sn14 : select ends here.


---Sn15 :  check offline atm limit with input value for same.

if nvl(v_offline_atm_limit,0)!=0 then 

if  TO_NUMBER(offline_atm_limit) >= TO_NUMBER(v_offline_atm_limit) then


errmsg :='OK';
dbms_output.put_line ( 'offline atm limit is correct ='||' '|| v_offline_atm_limit);

else 

errmsg :='offline atm limit is beyond predefined limit ='||' '|| v_online_atm_limit;
raise excep_1;

end if;

else 

errmsg :='Enter proper offline atm Limit';
raise excep_1;

end if;

---Sn15 :  check ends here.



--Sn16 : select online pos limit from  cms_bin_param

begin -- begin 005 starts here 

select cbp_param_value into online_pos_limit from cms_bin_param
where CBP_PROFILE_CODE =v_CPC_PROFILE_CODE
and CBP_INST_CODE=v_instcode
and CBP_PARAM_NAME in ('Online POS Limit');


EXCEPTION WHEN NO_DATA_FOUND THEN
errmsg :='no online pos limit found inside begin 005 for profile code ='||' '||v_CPC_PROFILE_CODE;
raise excep_1;

WHEN OTHERS THEN
errmsg := 'error occured inside begin 005 ---->'||' '||sqlcode||'-------'||sqlerrm;
raise excep_1;

end;-- begin 005 ends here

--Sn16 : select ends here



---Sn17 :  check online pos limit with input value for same.

if nvl(v_online_pos_limit,0) !=0 then

if  TO_NUMBER(online_pos_limit) >= TO_NUMBER(v_online_pos_limit) then


errmsg :='OK';
dbms_output.put_line ( 'online pos limit is correct ='||' '|| v_online_pos_limit);

else 

errmsg :='online atm limit is beyond predefined limit ='||' '|| v_online_atm_limit;
raise excep_1;

end if;

else 

errmsg :='Enter proper online pos Limit';
raise excep_1;

end if;

---Sn17 :  check ends here.

--Sn18 : select offline pos limit from  cms_bin_param

begin -- begin 006 starts here 

select cbp_param_value into offline_pos_limit 
from cms_bin_param
where CBP_PROFILE_CODE =v_CPC_PROFILE_CODE
and CBP_INST_CODE=v_instcode
and CBP_PARAM_NAME in ('Offline POS Limit');

EXCEPTION WHEN NO_DATA_FOUND THEN
errmsg :='no offline pos limit found inside begin 006 for profile code ='||' '||v_CPC_PROFILE_CODE;
raise excep_1;

WHEN OTHERS THEN
errmsg := 'error occured inside begin 006---->'||' '||sqlcode||'-------'||sqlerrm;
raise excep_1;

end;-- begin 005 ends here

--Sn18 : select ends here.


---Sn19 :  check offline pos limit with input value for same.

if nvl(v_offline_pos_limit,0)!=0 then


if  TO_NUMBER(offline_pos_limit) >= TO_NUMBER(v_offline_pos_limit) then


errmsg :='OK';
dbms_output.put_line ( 'offline pos limit is correct ='||' '|| v_offline_pos_limit);

else 

errmsg :='offline pos limit is beyond predefined limit ='||' '|| v_offline_pos_limit;
raise excep_1;

end if;

else 

errmsg :='Enter proper offline pos Limit';
raise excep_1;

end if;

IF errmsg ='OK' THEN 

BEGIN ---- BEGIN FOR OUTER UPDATE STARTS HERE

SAVEPOINT TWO;

update cms_appl_pan 
set CAP_ONLINE_AGGR_LIMIT  =  nvl(TO_NUMBER(v_online_atm_limit),0)  +  nvl(TO_NUMBER(v_online_pos_limit),0),
    CAP_OFFLINE_AGGR_LIMIT =  nvl(TO_NUMBER(v_offline_atm_limit),0) +  nvl(TO_NUMBER(v_offline_pos_limit),0),
    CAP_ATM_OFFLINE_LIMIT  =  nvl(TO_NUMBER(v_offline_atm_limit),0), 
    CAP_ATM_ONLINE_LIMIT   =  nvl(TO_NUMBER(v_online_atm_limit),0), 
    CAP_POS_OFFLINE_LIMIT  =  nvl(TO_NUMBER(v_offline_pos_limit),0), 
    CAP_POS_ONLINE_LIMIT   =  nvl(TO_NUMBER(v_online_pos_limit),0)
where CAP_PAN_CODE =v_CAP_PAN_CODE
and CAP_INST_CODE =v_instcode;

IF SQL%ROWCOUNT = 0 THEN
errmsg := 'no rows affected after OUTER update'; 
RAISE EXCEP_1;
ELSE
errmsg:='OK'; 
END IF;

exception when EXCEP_1 then raise;
WHEN OTHERS THEN
errmsg:='Problem Occured During OUTER Updation------>'||' '||SQLCODE||' '||SQLERRM; 
ROLLBACK TO SAVEPOINT TWO; 

end; ---- BEGIN FOR OUTER UPDATE ENDS HERE

end if;

-------insert added for cms_pan_spprt on 22-apr-2010--------------

    if errmsg='OK' THEN

         BEGIN  ---insert begin here
              INSERT INTO CMS_PAN_SPPRT
                          (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                           cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                           cps_ins_user, cps_lupd_user, cps_cmd_mode
                          )
                   VALUES (v_instcode, v_CAP_PAN_CODE, v_mbrnumb, v_cap_prod_catg,
                           'LIMT', v_csr_spprt_rsncode, v_cgl_remarks,
                           v_lupduser, v_cgl_ins_user, 0
                          );
           EXCEPTION
              WHEN OTHERS
              THEN
                 errmsg :=
                       'Error while inserting records into card support master'
                    || SUBSTR (SQLERRM, 1, 200);
                 RAISE EXCEP_1;
           END;--insert ends here
           
    END IF;            
   
-------insert added for cms_pan_spprt on 22-apr-2010--------------


---Sn19 :  check ends here.

dbms_output.put_line(v_errmsg);

EXCEPTION WHEN excep_1
then v_errmsg := errmsg;

dbms_output.put_line(v_errmsg);
 
when others then 
v_errmsg := sqlcode||'------'||sqlerrm ;

dbms_output.put_line(v_errmsg);

END; --MAIN BEGIN ENDS HERE;
/


