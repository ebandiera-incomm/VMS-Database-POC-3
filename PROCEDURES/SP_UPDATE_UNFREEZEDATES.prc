CREATE OR REPLACE PROCEDURE VMSCMS.sp_update_unfreezedates(errmsg OUT VARCHAR2)
AS

v_pan_number VARCHAR2(20);
v_prod_catg  VARCHAR2(1);

CURSOR C1 IS
SELECT cts_acct_no, cts_unfreeze_date
FROM CMS_TEMP_SBKIT;

BEGIN -- main

FOR x IN C1
LOOP

errmsg := 'OK';
	-- this query will fetch the first card issued on that account irrespective of whether it is a debit/ atm card and
	-- open/hotlisted card
	BEGIN -- #1 get the first card issued on that acct
	 	 SELECT /* + INDEX(CMS_APPL_PAN INDX_APPLPAN_INSTACCTNO) */ cap_pan_code, cap_prod_catg INTO
		 v_pan_number, v_prod_catg FROM CMS_APPL_PAN
		 WHERE cap_inst_code = 1
		 AND cap_acct_no = x.cts_acct_no
		 AND cap_pangen_date = (SELECT MIN(cap_pangen_date) FROM CMS_APPL_PAN
		 WHERE cap_inst_code = 1
		 AND cap_acct_no = x.cts_acct_no);

	EXCEPTION -- #1
	WHEN NO_DATA_FOUND THEN
	  	errmsg := 'No such PAN found';
		-- insert into some table ??
		INSERT INTO CMS_CARDBASE_ERR_LOG(cel_inst_code,  cel_pan_code, cel_error_mesg)
		VALUES ('1', v_pan_number, 'PanMissingExcp' || errmsg);
		-- continue with the loop for the rest of the acct nos.

	WHEN OTHERS THEN
	  	errmsg := 'Excp 1 -- '||SQLERRM;
		INSERT INTO CMS_CARDBASE_ERR_LOG(cel_inst_code,  cel_pan_code, cel_error_mesg)
		VALUES ('1', v_pan_number, 'PanMissingExcp' || errmsg);
		-- continue with the loop for the rest of the acct nos.

	END; --end of #1

	-- will come to this point only if such a pan is found above...
	IF v_prod_catg = 'D' AND errmsg = 'OK' THEN
	BEGIN  -- #2
		-- update the active date as the unfreeze date
		UPDATE CMS_APPL_PAN
		SET cap_active_date = x.cts_unfreeze_date
		WHERE cap_pan_code = v_pan_number
		AND cap_mbr_numb = '000';

		IF SQL%ROWCOUNT != 1 THEN
			errmsg := 'Problem in updation of active date for pan '||v_pan_number||'.';
			-- insert into an err table...
			INSERT INTO CMS_CARDBASE_ERR_LOG(cel_inst_code,  cel_pan_code, cel_error_mesg)
			VALUES ('1', v_pan_number, 'UpdatePanExcp' || errmsg);
		END IF;

	EXCEPTION -- #2
	WHEN OTHERS THEN
	  	 errmsg := 'Excp 2 -- '||SQLERRM;
		INSERT INTO CMS_CARDBASE_ERR_LOG(cel_inst_code,  cel_pan_code, cel_error_mesg)
		VALUES ('1', v_pan_number, 'UpdatePanExcp' || errmsg);
	END; -- #2
	END IF;

END LOOP;

EXCEPTION
WHEN OTHERS THEN
	errmsg:= 'Exception in main ' || SQLERRM;
END;
/


SHOW ERRORS