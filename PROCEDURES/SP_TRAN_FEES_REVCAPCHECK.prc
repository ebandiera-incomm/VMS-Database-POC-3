create or replace
PROCEDURE        VMSCMS.SP_TRAN_FEES_REVCAPCHECK(
prm_inst_code          IN          NUMBER,
prm_acct_number        IN         VARCHAR2,
PRM_TRN_DATE           IN          VARCHAR2, 
prm_tran_fee           IN OUT      NUMBER,
prm_orgtran_fee        IN        NUMBER,
prm_fee_plan           IN         VARCHAR2,
prm_fee_code           IN         VARCHAR2,
prm_error              OUT         VARCHAR2)
IS
/***************************************************************************************
      * Created By       : Saiprasad
      * Created Date     : 25-Aug-2012
      * Reviewer         : Dhiraj
      * Reviewed Date    : 25-Aug-2012
      * Build Number     : RI0024.4_B0004

     * Modified by      : Sai Prasad
     * Modified Reason  : Mantis Id - 0012202 (FWR-11)
     * Modified Date    : 29-Aug-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 30-Aug-2013  
     * Build Number     : RI0024.4_B0006
     
     * Modified by      : Sai Prasad
     * Modified Reason  : Mantis Id - 12411 (FWR-11)
     * Modified Date    : 19-Sep-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    :   
     * Build Number     : RI0024.4_B0016
****************************************************************************************/

--exp_nofees          EXCEPTION ;
v_feecap_code       CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
v_fee_cap_amnt       CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
v_date_assesment CMS_FEE_MAST.CFM_DATE_ASSESSMENT%TYPE;
v_start_day CMS_FEE_MAST.CFM_DATE_START%TYPE;
V_ACCT_NUMBER      CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
v_count NUMBER;
v_fee_accrued CMS_FEECAP_DTL.CFD_FEE_ACCRUED%TYPE;
v_fee_waived CMS_FEECAP_DTL.CFD_FEE_WAIVED%TYPE;
v_tran_fee       CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
v_trans_date date;
v_flag number :=0;
V_DATE DATE;
V_MON Number(2);
V_DD Number(2);
V_LAST_DD Number(2);
BEGIN

 --V_DATE := TO_DATE(SUBSTR(TRIM(PRM_TRN_DATE), 1, 8), 'yyyymmdd'); --Commented for Mantis ID (12411) 
 V_DATE := sysdate; --Added for Mantis ID (12411) for capping on sysdate instead of bussiness date
BEGIN
SELECT CFM_FEE_CODE,
         CFM_FEE_AMT,CFM_DATE_ASSESSMENT,CFM_DATE_START into v_feecap_code, v_fee_cap_amnt,v_date_assesment, v_start_day
     FROM CMS_FEE_MAST, CMS_FEE_TYPES, CMS_FEE_FEEPLAN         
    WHERE CFM_INST_CODE =prm_inst_code AND CFM_INST_CODE = CFT_INST_CODE
          AND CFF_FEE_PLAN = prm_fee_plan AND CFF_FEE_CODE = CFM_FEE_CODE AND
             CFM_FEETYPE_CODE = CFT_FEETYPE_CODE AND
         CFT_FEE_FREQ = 'M' AND
         CFT_FEE_TYPE = 'C';
EXCEPTION
         WHEN NO_DATA_FOUND THEN
   prm_error := 'OK';
 RETURN;
        WHEN OTHERS THEN
   prm_error := 'Error while fetch Monthly fee cap '  || SUBSTR(SQLERRM, 1, 200);
 RETURN;
END;



 
 if v_date_assesment = 'CM' Then 
  v_trans_date := last_day(V_DATE);
 Elsif v_date_assesment = 'SM' Then
 V_MON := to_number (to_char(V_DATE,'MM'));
 V_DD := to_number (to_char(V_DATE,'DD'));
 V_LAST_DD := to_number (to_char(last_day(V_DATE),'DD')) ;
 
 
  if v_start_day = '31' then   -- modified for Mantis ID 12411
    if V_DD = 31 then 
      if V_MON = 12 then  
          v_trans_date := last_day(add_months(V_DATE,1)) -1;
        else
          v_trans_date := last_day(add_months(V_DATE,1));
      End if;
    Elsif V_LAST_DD = 31 then 
      v_trans_date := last_day(V_DATE) -1;
    Else 
      v_trans_date := last_day(V_DATE);
    End if; 
  elsif   v_start_day = '30' then -- modified for Mantis ID 12411
      if (V_DD >= 30 and V_MON = 01)  then
            v_trans_date := last_day(add_months(V_DATE,1));  
      elsif  V_MON = 02 then   
            v_trans_date := last_day(V_DATE);
      else                  
              if V_LAST_DD = '30'then
                if  (V_DD < 30) then
                    v_trans_date := last_day(V_DATE)-1;
                else
                    v_trans_date := last_day(Add_months(V_DATE,1))-2;
                End if;
              elsif V_LAST_DD = '31' then 
                  if (V_DD < 30)then
                    v_trans_date := last_day(V_DATE)-2;
            elsif (V_MON = 12)then  
                    v_trans_date := last_day(Add_months(V_DATE,1))-2;
              else 
                  v_trans_date := last_day(Add_months(V_DATE,1))-1;
              End if;
          END if;
      End if;
   else
	     IF length(v_start_day) < 2 then -- Added for Mantis ID 12411
		 v_start_day := '0'||v_start_day;
	     END if;
          v_trans_date := to_date(v_start_day||to_char(V_DATE,'MMYYYY'), 'DDMMYYYY'); 
          IF v_trans_date <= V_DATE then -- modified for Mantis ID 12411
           v_trans_date := Add_months(v_trans_date,1) -1;
          else
            v_trans_date := v_trans_date -1;
          END IF;
      End if;
   End IF;
   DBMS_OUTPUT.PUT_LINE('v_trans_date = ' || v_trans_date);
   DBMS_OUTPUT.PUT_LINE('v_fee_code = ' || v_feecap_code);
 BEGIN
 SELECT CFD_FEE_ACCRUED, CFD_FEE_WAIVED into v_fee_accrued, v_fee_waived FROM CMS_FEECAP_DTL            
    WHERE CFD_INST_CODE = prm_inst_code AND CFD_ACCT_NO =prm_acct_number
    AND CFD_FEE_CODE = v_feecap_code 
    AND trunc(CFD_FEE_PERIOD) = trunc(v_trans_date)
    ;    

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   v_fee_accrued := 0;
   v_fee_waived  := 0;
  WHEN OTHERS THEN
  prm_error := 'Error while fetch Monthly fee cap details '  || SUBSTR(SQLERRM, 1, 200);
 END;
  v_tran_fee := prm_tran_fee;
if v_fee_waived > 0 then
    if prm_tran_fee = 0 or prm_orgtran_fee > prm_tran_fee  then --modifed for Mantis Id 0012202 
      prm_tran_fee := prm_orgtran_fee;
    End if;
   if v_fee_waived < prm_tran_fee then
      prm_tran_fee :=  prm_tran_fee - v_fee_waived ;
       v_tran_fee := prm_tran_fee; 
      v_fee_waived :=0;
      
      else
      v_tran_fee :=0;
      v_fee_waived := v_fee_waived - prm_tran_fee;
      prm_tran_fee :=0;
   End if; 
  End IF;
 DBMS_OUTPUT.PUT_LINE('v_fee_waived = ' || v_fee_waived);
 
  BEGIN
      UPDATE CMS_FEECAP_DTL SET CFD_FEE_ACCRUED = CFD_FEE_ACCRUED - v_tran_fee, CFD_FEE_WAIVED = v_fee_waived,
      CFD_LUPD_DATE = sysdate
      where CFD_INST_CODE = prm_inst_code and CFD_ACCT_NO = prm_acct_number and CFD_FEE_CODE = v_feecap_code
      and trunc(CFD_FEE_PERIOD) = trunc(v_trans_date) ;
      
       IF SQL%ROWCOUNT = 0 THEN
                prm_error  := 'ERROR WHILE UPDATING CMS_FEECAP_DTL ';              
      END IF;    
  EXCEPTION
      WHEN OTHERS THEN
              prm_error  := 'ERROR WHILE UPDATING CMS_FEECAP_DTL ' ||                SUBSTR(SQLERRM, 1, 200);
               
    END; 
  if trunc(v_trans_date) > trunc(sysdate) then 
  BEGIN
    UPDATE CMS_ACCT_MAST
         SET CAM_FEE_CAP   = v_fee_cap_amnt,
            CAM_FEE_ACCRUED = v_fee_accrued - v_tran_fee
             WHERE CAM_ACCT_NO = prm_acct_number AND CAM_INST_CODE = prm_inst_code;
             
              IF SQL%ROWCOUNT = 0 THEN
                prm_error  := 'ERROR WHILE UPDATING CMS_ACCT_MAST ';              
      END IF;    
      EXCEPTION
      WHEN OTHERS THEN
              prm_error  := 'ERROR WHILE UPDATING CMS_ACCT_MAST ' ||                SUBSTR(SQLERRM, 1, 200);
               
    END; 
      End if;
 prm_error := 'OK';
END;
/
SHOW ERRORS;