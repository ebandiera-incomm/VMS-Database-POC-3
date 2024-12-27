CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Caffname( instcode IN  NUMBER  ,
	   	  	-- locnCode IN VARCHAR2,--** Rama PrabhuR for ICICI on 12th Apr 06 --Commeted By Kirti 17May10
			 rectype  IN VARCHAR2,--** Rama PrabhuR for ICICI on 12th Apr 06
             emvtype IN VARCHAR2, --** CR 239 - 19APR 2009 - JAYWANT Y - EMV N - NON-EMV
			 lupduser IN  NUMBER  ,
             caffname OUT  VARCHAR2  ,
             errmsg OUT  VARCHAR2)
AS

curr_date   VARCHAR2 (12);
v_ccc_caf_fname VARCHAR2 (12);
x_holder    NUMBER := 0;
duplicate_caf_gen EXCEPTION;

BEGIN  --Main Begin Block Starts Here

  BEGIN --Begin 1

	   SELECT COUNT(1)
	   INTO   x_holder
	   FROM   CMS_CAFGEN_DATA_TEMP;

	   IF x_holder <> 0 THEN

		RAISE duplicate_caf_gen;

	   ELSE

		Sp_Populate_Cafgen_Data(instcode,rectype,emvtype); --** Rama PrabhuR for ICICI on 12th Apr 06

	   END IF;

	   SELECT TO_CHAR(SYSDATE,'ddmmrr')
	   INTO curr_date
	   FROM dual;

   	   dbms_output.put_line('current date===>'||curr_date);

	   SELECT ccc_caf_fname
	   INTO v_ccc_caf_fname
	   FROM CMS_CAFGEN_CTRL
	   WHERE ccc_inst_code = instcode
	   AND  TRUNC(ccc_cafgen_date) = TRUNC(SYSDATE)
	   FOR UPDATE;

   	   dbms_output.put_line('v_ccc_caf_fname===>'||v_ccc_caf_fname);

	   caffname := 'CF'||curr_date||'.'||LPAD(TO_NUMBER(SUBSTR(v_ccc_caf_fname,10)+1),3,0);

   	   dbms_output.put_line('caffname===>'||caffname);

	   UPDATE CMS_CAFGEN_CTRL
	   SET	ccc_caf_fname = caffname,
		ccc_ins_user = lupduser
	   WHERE ccc_inst_code = instcode
	   AND  TRUNC(ccc_cafgen_date) = TRUNC(SYSDATE)
	   AND  ccc_caf_fname = v_ccc_caf_fname;

	   errmsg := 'OK';

  EXCEPTION --Exception of begin 1
   WHEN NO_DATA_FOUND THEN
	    caffname := 'CF'||curr_date||'.001';

	    INSERT INTO CMS_CAFGEN_CTRL ( CCC_INST_CODE  ,
		   CCC_CAFGEN_DATE ,
		   CCC_CAF_FNAME  ,
		   CCC_INS_USER  ,
		   CCC_LUPD_USER )
		   VALUES( instcode   ,
		   SYSDATE   ,
		   caffname   ,
		   lupduser   ,
		   lupduser);

	   errmsg := 'OK';

   WHEN duplicate_caf_gen THEN

      --Ashwini 21 Jan 2005  
   --  Displaying File Generated msg before updating appl_pan and caf_info. 
   -- File will be generated but the process will continue in the backend.
	--errmsg := 'CAF Process Already Going On';
   errmsg := 'Previous CAF Process terminated abnormally. ' ||   
             ' Please immediately contact System Administrator ';
	RAISE;

   WHEN OTHERS THEN

	   errmsg := 'Exeption 1 -- '||SQLCODE||'--'||SQLERRM;

   END; --End of begin 1

EXCEPTION --Exception of Main Begin

   WHEN duplicate_caf_gen THEN

   --Ashwini 21 Jan 2005  
   --  Displaying File Generated msg before updating appl_pan and caf_info. 
   -- File will be generated but the process will continue in the backend.
	--errmsg := 'CAF Process Already Going On';
   errmsg := 'Previous CAF Process terminated abnormally. ' ||   
             ' Please immediately contact System Administrator ';

   WHEN OTHERS THEN

	errmsg := 'Exeption Main -- '||SQLCODE||'--'||SQLERRM;

END ;  --Main Begin Block Ends Here
/


show error