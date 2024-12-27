CREATE OR REPLACE FUNCTION VMSCMS."FN_DUP_APPL_CHECK" (custid CMS_CUST_MAST.ccm_cust_id%type,
	   	  		  		   					 bin number ,acct_id IN CMS_ACCT_MAST.cam_acct_id%type,
											 instcode IN number)
RETURN VARCHAR2 AS dup_check VARCHAR(1) ;
--acctid number(10);
dum number(3):=0;
errmsg varchar2(50) :='OK';
BEGIN -- main begin
dup_check:='F';

--  Begin
--   select cam_acct_id
--   into acctid
--   from cms_acct_mast
--   where cam_inst_code = instcode
--   and cam_acct_no = acct_no;
--   --errmsg := 'OK';
--  exception
--  when no_data_found then
--   errmsg := 'No account exists';
--  when others then
--   errmsg := 'Excp  '||SQLERRM;
--  End;

--  if errmsg = 'OK' then
--  Begin
--   select count(1) into dum
--   from cms_appl_det
--   where cad_acct_id = acctid
--   and cad_inst_code = instcode
--   and cad_ins_date > (sysdate - 1);
--   if dum > 0 then
--    dup_check := 'T';
--   end if;
--  Exception
--  when no_data_found then
--   dup_check := 'F';
--
--  End;
--  end if;
 ---
 IF errmsg = 'OK' THEN
 BEGIN
		  SELECT COUNT(1) INTO dum
		  FROM CMS_APPL_MAST ,CMS_APPL_DET,CMS_PROD_BIN,CMS_CUST_MAST
		  WHERE cam_appl_stat='A'
		  AND   cam_inst_code = instcode
		  AND cam_inst_code=cpb_inst_code
		  AND cam_prod_code=cpb_prod_code
		  AND cpb_inst_bin=bin    -- BIN
		  AND cad_inst_code=cam_inst_code
		  AND cad_appl_code=cam_appl_code
		  AND cad_acct_id = acct_id  -- Account No
		  AND ccm_inst_code=cam_inst_code
		  AND ccm_cust_code=cam_cust_code -- Customer Id
		  AND CCM_CUST_ID =custid;

		  IF dum > 0 THEN
		  		   dup_check := 'T';
		  END IF;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
  dup_check := 'F';

 END;
 END IF;

---

 return dup_check;

END ; -- main end
/


