CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Upd_Addr      (
				   instcode  IN NUMBER,
				   lupduser IN NUMBER,
				   errmsg OUT VARCHAR2)  IS

addr1_null_excp   EXCEPTION; --Ashwini 13 Jan 05
v_mbrnumb		VARCHAR2(3)	; ---shyam 05 04 05

--   CAU_MANDATE_FLAG --> this flag will indicate mandate or otherwise : 01 --> Mandate card 99--> Non-mandate card
-- Note : bin for mandate card is 940112 at the moment...
-- *** There will be one more column added to the cms_addr_update table to indicate if the update is
-- *** for normal or mandate card -- jimmy 10th June 2005  -- CR 116

  CURSOR C1 IS
  SELECT CAU_ACCT_NO, CAU_DISP_NAME, CAU_ADDR1, CAU_ADDR2,CAU_CITY_NAME,CAU_STATE_SWITCH,
  CAU_PIN_CODE,CAU_CNTRY_CODE,CAU_PHONE_ONE,CAU_PHONE_TWO,CAU_MANDATE_FLAG, ROWID
  FROM CMS_ADDR_UPDATE
  WHERE CAU_DONE_FLAG = 'N';

  --Commented by christopher on 13Mar04  bcoz the address update is now card  based
  /*
  CURSOR C2(C1_ACCTNO IN VARCHAR2) IS
  select  CAM_BILL_ADDR
  from cms_acct_mast
  where cam_inst_code = instcode
  and CAM_ACCT_NO = C1_ACCTNO;
  */
  -- Picking up the card details that has the given acct as Primary  acct
  CURSOR C3(C1_ACCTNO IN VARCHAR2) IS--this cursor is taken because the query is returning multiple in case of joint accounts
  SELECT cap_cust_code , cap_disp_name , cap_bill_addr, cap_pan_code -- shyam added pan_code 05 04 05
  FROM	CMS_APPL_PAN
  WHERE cap_inst_code = instcode
  AND	cap_acct_no   = C1_ACCTNO;

  -- *** one more clause to filter out the mandate card will be added -- jimmy 10th June 2005 -- CR 116
  B24ADDR1 VARCHAR2(30);
  B24ADDR2 VARCHAR2(30);
  B24ADDR3 VARCHAR2(30);
  v_cap_cust_code  CMS_APPL_PAN.cap_cust_code%TYPE;
  v_errmsg VARCHAR2(500) ;
  v_raise_addr_excp  EXCEPTION ;
  v_bill_addr CMS_ACCT_MAST.CAM_BILL_ADDR%TYPE;
  DUM NUMBER(2);


  /**  Adding the following variables for CR 116 - mandate flag addr update check **/
  mandateAddrUpdException EXCEPTION;
  v_mandate_flag VARCHAR2(2);
  v_bin			 VARCHAR2(6);
  /**			 **/


  --local procedure to create countries
 PROCEDURE lp_create_countries
  	IS
  	err VARCHAR2(500);
  	cntrycode NUMBER(3);
	CURSOR c1 IS
  	SELECT DISTINCT cau_cntry_code
  	FROM  CMS_ADDR_UPDATE
  	WHERE cau_cntry_code NOT IN (SELECT gcm_curr_code FROM GEN_CURR_MAST);

  	BEGIN
  		FOR x IN c1
  		LOOP
			SELECT MAX(gcm_cntry_code)+1
			INTO cntrycode
			FROM GEN_CNTRY_MAST;
			INSERT INTO GEN_CURR_MAST(GCM_CURR_CODE ,
						GCM_CURR_NAME  ,
						GCM_CURR_DESC  ,
						GCM_LUPD_USER  )
					VALUES(	x.cau_cntry_code,
						x.cau_cntry_code||' - DFLT',
						'CREATED DURING ADDRESS UPDATE',
						lupduser);
			INSERT INTO GEN_CNTRY_MAST(GCM_CNTRY_CODE,
						GCM_CURR_CODE  ,
						GCM_CNTRY_NAME,
						GCM_LUPD_USER  )
					VALUES(cntrycode,
						x.cau_cntry_code,
						x.cau_cntry_code||' - DFLT',
						lupduser);
  		END LOOP;
  	END;
  --local procedure to create countries ends

  BEGIN    -- main begin starts.....
  errmsg := 'OK';

  --this will create countries which are not present in the masters
  lp_create_countries;

  FOR X IN C1
    LOOP --c1 loop
	v_errmsg := 'OK';

	/* Put a check on the mandate flag -- jimmy 12th July 2005	 */
	v_mandate_flag := x.CAU_MANDATE_FLAG;

	--Change done By Christopher to update adress of secondary Accounts ...Change Starts .
	--BEGIN  -- Secondary Accts .
	SELECT COUNT(1) INTO DUM
  	FROM	CMS_APPL_PAN
  	WHERE  	cap_inst_code = instcode
  	AND	  	cap_acct_no   = x.cau_acct_no ;

	IF dum > 0 THEN  -- Secondary Accts if...>0 means the givn acct is primary .

	  --Change done By Christopher to update adress of secondary Accounts ...Change Ends .
      BEGIN  --C1 BEGIN
          FOR Y IN C3(X.CAU_ACCT_NO)
              LOOP --C3 LOOP
			  BEGIN -- /**** mandate begin...
			  v_errmsg := 'OK';

			  /**	Changes for CR 116 -- jimmy 14th July 2005  **/
			  /* New variable to store the bin for mandate card   */
			  v_bin := SUBSTR(Y.CAP_PAN_CODE, 1, 6);

			  /* '01' will indicate address update for mandate card only	*/
			  IF v_mandate_flag = '01' AND v_bin != '940112'
			   THEN RAISE mandateAddrUpdException;
			  END IF;

			  /*  '99' will indicate address update for cards other than mandate cards */
			  IF v_mandate_flag = '99'  AND v_bin = '940112'
			   THEN RAISE mandateAddrUpdException;
			  END IF;
			  /** End of changes for CR 116 **/


			 -- DBMS_OUTPUT.PUT_LINE('prim '||' '||y.cap_cust_code||substr(y.cap_disp_name, 8, 13)) ;
                SAVEPOINT NAME_POINT ;
	   		Sp_Split_Addr(X.CAU_ADDR1 , X.CAU_ADDR2 , B24ADDR1 , B24ADDR2 , B24ADDR3 , errmsg);
		    IF errmsg = 'OK' THEN
  		   	  -- Updating the address based on the address code of the card.
		      BEGIN --ADDR_UPD_ERR BLOCK
                  --Ashwini 13 Jan 05
                  IF trim(B24ADDR1) IS NULL THEN
                     RAISE addr1_null_excp;
                  END IF;

				  UPDATE  CMS_ADDR_MAST
                  SET	CAM_ADD_ONE = B24ADDR1 ,
                    CAM_ADD_TWO = B24ADDR2 ,
                    CAM_ADD_THREE = B24ADDR3 ,
                    CAM_PIN_CODE = X.CAU_PIN_CODE ,
                    CAM_PHONE_ONE = X.CAU_PHONE_ONE ,
                    CAM_PHONE_TWO = X.CAU_PHONE_TWO ,
                    CAM_CITY_NAME = NVL(X.CAU_CITY_NAME,' ') ,
                    CAM_CNTRY_CODE = (SELECT GCM_CNTRY_CODE
                            FROM GEN_CNTRY_MAST
                            WHERE  GCM_CURR_CODE = X.CAU_CNTRY_CODE),
                    CAM_STATE_SWITCH = X.CAU_STATE_SWITCH
                 WHERE	cam_inst_code = instcode
                 AND	CAM_ADDR_CODE = Y.CAP_BILL_ADDR;

			 EXCEPTION
			     WHEN addr1_null_excp THEN --Ashwini 13 Jan 05
				      v_errmsg := 'Error while Updating - ADDRESS ONE IS NULL' ;
			   		  UPDATE CMS_ADDR_UPDATE
					  SET cau_done_flag = 'E',
					  cau_process_result = v_errmsg --errmsg
					  WHERE ROWID = x.ROWID ; -- End
				 WHEN OTHERS THEN
				 	  v_errmsg := 'Error while Updating '||SQLERRM ;
					  UPDATE CMS_ADDR_UPDATE
					  SET cau_done_flag = 'E',
					  cau_process_result = v_errmsg --errmsg
					  WHERE ROWID = x.ROWID ;
			END  ;
  		   ELSE
  			    v_errmsg := 'From sp_split_addr -- '||errmsg;
			    --added on 31jul04 by christopher to catch the error .
			    UPDATE CMS_ADDR_UPDATE
  	   		    SET cau_done_flag = 'E',
  	   		    cau_process_result = errmsg
  	   		    WHERE ROWID = x.ROWID ;
  		   END IF;

		   	   -- DBMS_OUTPUT.PUT_LINE('b4 VISA '||' '||y.cap_cust_code||substr(y.cap_disp_name, 8, 13)||' --  '||v_errmsg) ;
              IF v_errmsg = 'OK' THEN   -- $$$
  				IF SUBSTR(y.cap_disp_name, 8, 13) = 'VISA ELECTRON' THEN   -- &&&
  				BEGIN
				  BEGIN
				--    DBMS_OUTPUT.PUT_LINE('VISA '||' '||y.cap_cust_code||substr(y.cap_disp_name, 8, 13)) ;
				--shyamjith 05 Aprl 05 active date and and next billdate shud be sysdate for VISA ELECTRON CARDS
  				/*	UPDATE	cms_appl_pan
  					SET	cap_disp_name = x.cau_disp_name
  					WHERE	cap_inst_code = instcode
  					AND	cap_acct_no   = x.cau_acct_no
					AND	cap_cust_code = y.cap_cust_code ; --added on 31jul04 to remove name disc*/
					UPDATE	CMS_APPL_PAN
  					SET	cap_disp_name = x.cau_disp_name,
					cap_active_date= SYSDATE,  -- shyamjith 05 aprl 05
					cap_next_bill_date = SYSDATE -- shyamjith 05 aprl 05
  					WHERE	cap_inst_code = instcode
  					AND	cap_acct_no   = x.cau_acct_no
					AND	cap_cust_code = y.cap_cust_code ; --added on 31jul04 to remove name disc
  				  EXCEPTION
  					 WHEN OTHERS THEN
  					  IF SQLCODE = '-1407' THEN
  					   v_errmsg := 'NAME COMING AS NULL FOR A CUSTOMER WHOSE NAME IS  VISA ELECTRON' ;
  					   ELSE
  					 v_errmsg := SQLERRM ;
  					 END IF ;
					 ROLLBACK TO NAME_POINT ;
  	   				 UPDATE CMS_ADDR_UPDATE
  	   				 SET cau_done_flag = 'E',
  	   				 cau_process_result = v_errmsg
  	   				 WHERE ROWID = x.ROWID ;
  					 RAISE  v_raise_addr_excp ;
  				   END ;
  				  BEGIN
  					UPDATE	CMS_CUST_MAST
  					SET	ccm_first_name = x.cau_disp_name
  					WHERE	ccm_inst_code  = instcode
  				--	AND	ccm_cust_code  = v_cap_cust_code;
  					AND	ccm_cust_code  = y.cap_cust_code;
  				EXCEPTION
  					WHEN OTHERS THEN
  						 IF SQLCODE = '-1407' THEN
						    v_errmsg := 'NAME COMING AS NULL FOR A CUSTOMER WHOSE NAME IS  VISA ELECTRON' ;
						 ELSE
						 	 v_errmsg := SQLERRM ;
  					 	 END IF ;

						 ROLLBACK TO NAME_POINT ;
	  	   				 UPDATE CMS_ADDR_UPDATE
						 SET cau_done_flag = 'E',
	  	   				 cau_process_result = v_errmsg
	  	   				 WHERE ROWID = x.ROWID ;
	  					 RAISE  v_raise_addr_excp ;
  				END ;

  				EXCEPTION
  				WHEN v_raise_addr_excp  THEN
  				--ROLLBACK TO NAME_POINT ; -- added by christopher to avoid nam disc due the failure of any of above two cmds
				NULL ;
  				END ;
				-------------shyam
			/*	v_mbrnumb:='000';
				IF errmsg = 'OK' THEN   -- ###
				   BEGIN		--Begin 4
				   		SELECT COUNT(*)
						INTO	dum
						FROM	CMS_CAF_INFO
						WHERE	cci_inst_code			=	instcode
						AND		TRUNC(cci_pan_code)	=	y.cap_pan_code
						AND		cci_mbr_numb		=	v_mbrnumb;
						IF dum = 1 THEN--that means there is a row in cafinfo for that pan but file is not generated
						DELETE FROM CMS_CAF_INFO
						WHERE	cci_inst_code			=	instcode
						AND		TRUNC(cci_pan_code)	=	y.cap_pan_code
						AND		cci_mbr_numb		=	v_mbrnumb;
						END IF;
		--call the procedure to insert into cafinfo
			   	   		Sp_Caf_Rfrsh(instcode,y.cap_pan_code,v_mbrnumb,SYSDATE,'C','ADDRESS UPDATE','ADDRUPD',lupduser,errmsg)		;
						IF errmsg != 'OK' THEN
							errmsg := 'From caf refresh -- '||errmsg;
						END IF;
					EXCEPTION	--Excp 4
						WHEN OTHERS THEN
						errmsg := 'Excp 4 -- '||SQLERRM;
					END;		--End of begin 4
				END IF;   -- ^### */
				------------shyam
  				END IF;   -- &&&
  		   END IF;   -- $$$


		   -- Rahul 29 Aug 05
		   	   BEGIN		--Begin 4
			   		v_mbrnumb:='000';
			   		SELECT COUNT(*)
					INTO	dum
					FROM	CMS_CAF_INFO
					WHERE	cci_inst_code	=	instcode
					AND		TRUNC(cci_pan_code)	=	y.cap_pan_code
					AND		cci_mbr_numb	=	v_mbrnumb;

					IF dum = 1 THEN
						DELETE FROM CMS_CAF_INFO
						WHERE	cci_inst_code =	instcode
						AND		TRUNC(cci_pan_code)  =	y.cap_pan_code
						AND		cci_mbr_numb  =	v_mbrnumb;
						END IF;
						--call the procedure to insert into cafinfo
			   	   		Sp_Caf_Rfrsh(instcode,y.cap_pan_code,v_mbrnumb,SYSDATE,'C','ADDRESS UPDATE','ADDRUPD',lupduser,errmsg)		;
						IF errmsg != 'OK' THEN
						   errmsg := 'From1 caf refresh -- '||errmsg;
					 	   UPDATE CMS_ADDR_UPDATE
						   SET cau_done_flag = 'E',
						   cau_process_result = errmsg
						   WHERE ROWID = x.ROWID ;
						END IF;
					EXCEPTION	--Excp 4
						WHEN OTHERS THEN
						errmsg := 'Excp 4 -- '||SQLERRM;
				 	    UPDATE CMS_ADDR_UPDATE
					    SET cau_done_flag = 'E',
					    cau_process_result = errmsg
					    WHERE ROWID = x.ROWID ;
					END;		--End of begin 4

		 /****  Added for Cr 116 -- jimmy 13th July 2005 ****/
		 EXCEPTION   /**** 	 	 		  ****/
		 	WHEN mandateAddrUpdException THEN
		 	  v_errmsg:= 'Mandate Card address update filter';
		 	  UPDATE CMS_ADDR_UPDATE
			   SET cau_done_flag = 'F',
			   cau_process_result = v_errmsg
			   WHERE ROWID = x.ROWID ;

		 END; -- end of mandate begin...
		 /**  	 **/

         END LOOP; --for C3 LOOP
         --COMMIT;
	    UPDATE CMS_ADDR_UPDATE
  	   	SET cau_done_flag = 'Y',
  	   	cau_process_result = 'Processed '
  	   	WHERE ROWID = x.ROWID  AND
  	   	cau_done_flag = 'N' ;


  	EXCEPTION -- c1 Exception
  	WHEN OTHERS THEN
  	  errmsg := SQLERRM ;
  	   UPDATE CMS_ADDR_UPDATE
  	   SET cau_done_flag = 'E',
  	   cau_process_result = errmsg
  	   WHERE ROWID = x.ROWID ;
         END ; -- c1 end
     --Change done By Christopher to update adress of secondary Accounts ..Change Starts .
     --EXCEPTION
       --WHEN NO_DATA_FOUND THEN
       ELSE -- secondary accts
       --When the Given Acct is not in Pan Master Then the Account May be a Secondary Acct .
         Sp_Split_Addr(X.CAU_ADDR1 , X.CAU_ADDR2 , B24ADDR1 , B24ADDR2 , B24ADDR3 , errmsg);
	 IF errmsg = 'OK' THEN
  	     BEGIN --Secondary Acct -- 2
            --Ashwini 13 Jan 05
               IF trim(B24ADDR1) IS NULL THEN
                  RAISE addr1_null_excp;
               END IF;
	       SELECT  CAM_BILL_ADDR
  	       INTO v_bill_addr
  	       FROM CMS_ACCT_MAST
  	       WHERE CAM_INST_CODE = 1 AND
  	       CAM_ACCT_NO = x.CAU_ACCT_NO ;
  			UPDATE  CMS_ADDR_MAST
  			  SET	  CAM_ADD_ONE = B24ADDR1 ,
  				  CAM_ADD_TWO = B24ADDR2 ,
  				  CAM_ADD_THREE = B24ADDR3 ,
  				  CAM_PIN_CODE = X.CAU_PIN_CODE ,
  				  CAM_PHONE_ONE = X.CAU_PHONE_ONE ,
  				  CAM_PHONE_TWO = X.CAU_PHONE_TWO ,
  				  CAM_CITY_NAME = NVL(X.CAU_CITY_NAME,' ') ,
  				  CAM_CNTRY_CODE = (SELECT GCM_CNTRY_CODE
  						    FROM GEN_CNTRY_MAST
  						    WHERE  GCM_CURR_CODE = X.CAU_CNTRY_CODE),
  				  CAM_STATE_SWITCH = X.CAU_STATE_SWITCH
  			  WHERE	cam_inst_code = instcode
  			  AND	CAM_ADDR_CODE = v_bill_addr;
  			  UPDATE CMS_ADDR_UPDATE
  			  SET cau_done_flag = 'Y',
  			  cau_process_result = 'Processed '
  			  WHERE ROWID = x.ROWID  AND
  			 cau_done_flag = 'N' ;
  		EXCEPTION
         WHEN addr1_null_excp THEN --Ashwini 13 Jan 05
            v_errmsg := 'Error while Updating - ADDRESS ONE IS NULL' ;
			   UPDATE CMS_ADDR_UPDATE
  	   		   SET cau_done_flag = 'E',
  	   		   cau_process_result = v_errmsg --errmsg
  	   		   WHERE ROWID = x.ROWID ; -- End
  	       WHEN NO_DATA_FOUND THEN
  			v_errmsg := 'NO SUCH ACCOUNT :'||x.cau_acct_no ;
  					UPDATE CMS_ADDR_UPDATE
  	   				 SET cau_done_flag = 'E',
  	   				 cau_process_result = v_errmsg
  	   				 WHERE ROWID = x.ROWID ;
  	       WHEN OTHERS THEN
  	              v_errmsg := 'Err:'||SQLERRM ;
  		                         UPDATE CMS_ADDR_UPDATE
  	   				 SET cau_done_flag = 'E',
  	   				 cau_process_result = v_errmsg
  	   				 WHERE ROWID = x.ROWID ;
  	       END ; -- Secondary Acct -- 2
  	ELSE
  		v_errmsg := 'From sp_split_addr(Secondary Acct) -- '||errmsg;
		 UPDATE CMS_ADDR_UPDATE
  	   				 SET cau_done_flag = 'E',
  	   				 cau_process_result = v_errmsg
  	   				 WHERE ROWID = x.ROWID ;
  	END IF ;
     END  IF ; -- Secondary Accts
     --Change done By Christopher to update adress of secondary Accounts ..Change Ends  .
     END LOOP ; --c1 LOOP
     -- Ashwini 28 Dec 2004  commented for taking successful report
   --DELETE FROM cms_addr_update where cau_done_flag = 'Y' ;
  	EXCEPTION
  	     WHEN OTHERS THEN
  	        errmsg := 'Main Excp -- '||SQLERRM;
  END;
/


