CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Update_Billdates_Hpcl(errmsg OUT VARCHAR2)
AS
v_issue_date DATE;
v_next_billdate DATE;

-- this cursor will have all HPCL debit cards that are open...approx 4.2 lakh records
CURSOR c1 IS
SELECT cap_active_date, cap_pan_code
FROM CMS_APPL_PAN
WHERE cap_card_stat = '1'
AND  SUBSTR(cap_pan_code,1,6) =  '402657'
AND  cap_prod_catg = 'D'
AND cap_billdate_flag = NULL -- this flag will indicate whether the pan has been updated or not...
AND ROWNUM < 50000;   		 -- do this for 50000 records each ...commit outside

BEGIN -- main
-- start updation for all non-HPCL cards
FOR x IN c1

LOOP
	BEGIN  -- begin 2


-- [1] cards issued before 1st Feb 2004 are charged cards...add 1 year

	IF x.cap_active_date < TO_DATE('01-02-2004', 'dd-mm-yyyy') THEN  --

		 UPDATE CMS_APPL_PAN
		 SET cap_next_bill_date = ADD_MONTHS(x.cap_active_date,12),
		 CAP_BILLDATE_FLAG = 'Y'   -- update flag also...
		 WHERE cap_pan_code = x.cap_pan_code
		 AND cap_mbr_numb= '000';
		 IF SQL%rowcount < 1 THEN
			errmsg := 'Error during updation for grpHPCL1' || SQLERRM;
			INSERT INTO CMS_CARDBASE_ERR_LOG(cel_inst_code,  cel_pan_code, cel_error_mesg)
				VALUES ('1', x.cap_pan_code, errmsg);
	 	 END IF;
--	END IF;
-- [2] cards issued after 1st feb 2004 will have the same bill date as active date

   	 ELSE
	 -- IF x.cap_active_date >= TO_DATE('01-02-2004', 'dd-mm-yyyy') THEN  --

		 UPDATE CMS_APPL_PAN
		 SET cap_next_bill_date = x.cap_active_date
		 WHERE cap_pan_code = x.cap_pan_code
		 AND cap_mbr_numb= '000';
		    IF SQL%rowcount < 1 THEN
			errmsg := 'Error during updation for grpHPCL2' || SQLERRM;
			INSERT INTO CMS_CARDBASE_ERR_LOG(cel_inst_code,  cel_pan_code, cel_error_mesg)
			VALUES ('1', x.cap_pan_code, errmsg);
	       END IF;
    END IF;

 END;

END LOOP;
EXCEPTION
WHEN OTHERS THEN
errmsg:='Main Excp ' || SQLERRM;
END;
/


