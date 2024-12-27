CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Update_Billdates(errmsg OUT VARCHAR2)
AS
v_issue_date DATE;
v_next_billdate DATE;
dum NUMBER;
v_errmsg VARCHAR2(200);
CURSOR c1 IS
	SELECT cap_active_date, cap_pan_code
	FROM CMS_APPL_PAN
	WHERE cap_card_stat = '1'
	AND SUBSTR(cap_pan_code,1,6) NOT IN  ('402657') -- HPCL bin
	AND  cap_prod_catg = 'D';

BEGIN -- main
	-- start updation for all non-HPCL cards
	FOR x IN c1
   		LOOP
	   		dum:=0;
 				   -- check if this card has been charged or not
				  BEGIN
				  SELECT COUNT(1) INTO dum
				  FROM TEMP_CARDS_UNCHRGD
             	  WHERE tcu_pan_code = x.cap_pan_code;
				  END;
				  IF x.cap_active_date < TO_DATE('01-04-2004', 'dd-mm-yyyy')  THEN
						IF  dum > 0 THEN -- means the card has not been charged -- if #3
						UPDATE CMS_APPL_PAN
			 			SET cap_next_bill_date = TO_DATE('01-04-2004', 'dd-mm-yyyy')
			 			WHERE cap_pan_code = x.cap_pan_code
			 			AND cap_mbr_numb= '000';
							IF SQL%rowcount != 1 THEN
							 	  errmsg := 'Error during updation for grp1a' || SQLERRM;
								 INSERT INTO CMS_CARDBASE_ERR_LOG(cel_inst_code,  cel_pan_code, cel_error_mesg)
								 VALUES ('1', x.cap_pan_code,errmsg );
			 				END IF;
						ELSE  -- card has been charged, update to april 1, 2005
							UPDATE CMS_APPL_PAN
							SET cap_next_bill_date = TO_DATE('01-04-2005', 'dd-mm-yyyy')
							WHERE cap_pan_code = x.cap_pan_code
       	 						AND cap_mbr_numb= '000';
							IF SQL%rowcount != 1 THEN
	 		 				 	 errmsg := 'Error during updation for grp1b' || SQLERRM;
 							  	 INSERT INTO CMS_CARDBASE_ERR_LOG(cel_inst_code,  cel_pan_code, cel_error_mesg)
								 VALUES ('1', x.cap_pan_code, errmsg);
			 				 END IF;   --
		   				END IF;
				END IF;
				IF ( x.cap_active_date >= TO_DATE('01-04-2004', 'dd-mm-yyyy')) AND  (x.cap_active_date < TO_DATE('08-03-2005', 'dd-mm-yyyy')) THEN
					  IF dum > 0 THEN -- means the card has not been charged -- if #3
					  	 UPDATE CMS_APPL_PAN
						 SET cap_next_bill_date = x.cap_active_date
						 WHERE cap_pan_code = x.cap_pan_code
      	 					 AND cap_mbr_numb= '000';
							 IF SQL%rowcount != 1 THEN
							 	errmsg := 'Error during updation for grp2a ' || SQLERRM;
								INSERT INTO CMS_CARDBASE_ERR_LOG(cel_inst_code,  cel_pan_code, cel_error_mesg)
								VALUES ('1', x.cap_pan_code, errmsg);
							END IF; -- of begin #4
					  ELSE  -- of if #3 -- card has been charged, update to april 1, 2005
					 	   UPDATE CMS_APPL_PAN
						   SET cap_next_bill_date = ADD_MONTHS(x.cap_active_date, 12)
						   WHERE cap_pan_code = x.cap_pan_code
      	 					   AND cap_mbr_numb= '000';
							   IF SQL%rowcount != 1 THEN
							   	  errmsg := 'Error during updation for grp2b ' || SQLERRM;
								  INSERT INTO CMS_CARDBASE_ERR_LOG(cel_inst_code,  cel_pan_code, cel_error_mesg)
								  VALUES ('1', x.cap_pan_code, errmsg);
		         				   END IF;   -- if #3
					  END IF;	-- if #2
			END IF;
		IF  x.cap_active_date >= TO_DATE('08-03-2005', 'dd-mm-yyyy') THEN
			   IF dum > 0 THEN -- means card not charged
				UPDATE CMS_APPL_PAN
				SET cap_next_bill_date = TO_DATE('01-04-2005', 'dd-mm-yyyy')
				WHERE cap_pan_code = x.cap_pan_code
				AND cap_mbr_numb= '000';
				 IF SQL%rowcount != 1 THEN
					errmsg := 'Error during updation for grp3a ' || SQLERRM;
					INSERT INTO CMS_CARDBASE_ERR_LOG(cel_inst_code,  cel_pan_code, cel_error_mesg)
						VALUES ('1', x.cap_pan_code, errmsg);
				END IF;
			   ELSE
				UPDATE CMS_APPL_PAN
				SET cap_next_bill_date = TO_DATE('01-04-2005', 'dd-mm-yyyy')
				WHERE cap_pan_code = x.cap_pan_code
				AND cap_mbr_numb= '000';
				 IF SQL%rowcount != 1 THEN
					errmsg := 'Error during updation for grp3a ' || SQLERRM;
					INSERT INTO CMS_CARDBASE_ERR_LOG(cel_inst_code,  cel_pan_code, cel_error_mesg)
						VALUES ('1', x.cap_pan_code, errmsg);
				END IF;
			   END IF;
		END IF; --  for active dates
END LOOP;
EXCEPTION
WHEN OTHERS THEN
errmsg:='Main Exception ' || SQLERRM;
END;
/


