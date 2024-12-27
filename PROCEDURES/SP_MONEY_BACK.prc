CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Money_Back(inst_code IN NUMBER, mbr_numb IN VARCHAR2,errmsg OUT VARCHAR2)
AS

v_errmsg VARCHAR2(100);
v_total_amt CMS_PAN_TRANS.cpt_trans_amt%TYPE;
v_hot_amt CMS_PAN_TRANS.cpt_trans_amt%TYPE;
v_reisu_amt CMS_PAN_TRANS.cpt_trans_amt%TYPE;
v_pan_code CMS_PAN_TRANS.cpt_pan_code%TYPE;
v_hot_pancode CMS_PAN_TRANS.cpt_pan_code%TYPE;
v_reisu_pancode CMS_PAN_TRANS.cpt_pan_code%TYPE;
v_latest_pan CMS_PAN_TRANS.cpt_pan_code%TYPE;
v_card_stat CMS_APPL_PAN.cap_card_stat%TYPE;


-- GET ALL CARDS FROM THE PAN_TRANS TABLE ON WHICH TRANSACTIONS HAVE BEEN DONE WITHIN THAT PERIOD....
CURSOR c1 IS
SELECT DISTINCT(cpt_pan_code)
FROM CMS_PAN_TRANS
WHERE cpt_inst_code = inst_code
AND cpt_trans_date BETWEEN TO_DATE('01042004 00:00:00','DDMMYYYY HH24:MI:SS') AND TO_DATE('31032005 23:59:59','DDMMYYYY HH24:MI:SS');


---------- local procedure to find hotlisted card of reissued card --start
PROCEDURE	lp_search_hotlst_reisu		( l_pan_code  IN VARCHAR2, l_hot_pancode OUT VARCHAR2,l_hot_amt OUT NUMBER,l_errmsg OUT VARCHAR2 )
  IS
  BEGIN
  	   	 l_errmsg:='OK';
         l_hot_amt :=0;
		 BEGIN -- 2
    	  SELECT chr_pan_code
         INTO l_hot_pancode
         FROM CMS_HTLST_REISU
    	 WHERE chr_inst_code = inst_code
		 AND chr_new_pan =  l_pan_code
		 AND chr_mbr_numb = mbr_numb
         AND chr_ins_date BETWEEN TO_DATE('01042004 00:00:00','DDMMYYYY HH24:MI:SS') AND TO_DATE('31052005 23:59:59','DDMMYYYY HH24:MI:SS');
         EXCEPTION
    	 	WHEN NO_DATA_FOUND THEN
			l_errmsg:='OK';
			l_hot_pancode:=NULL;
			l_hot_amt:=0;
     		 WHEN OTHERS THEN
  			l_errmsg := 'Excp1 LP1 -- '||SQLERRM;
		 END; -- 2
--		dbms_output.put_line('Hotlisted pan.....');
--dbms_output.put_line(l_hot_pancode);
-- if l_hot_pancode is not null means the card was reissued and l_hot_pancode has the old card
         IF  l_hot_pancode IS NOT NULL THEN
		 BEGIN --3
			 SELECT SUM(cpt_trans_amt)
			 INTO l_hot_amt
			 FROM CMS_PAN_TRANS
			 WHERE cpt_inst_code = inst_code
			 AND cpt_pan_code = l_hot_pancode
			 AND cpt_mbr_numb =mbr_numb
			 AND cpt_trans_date BETWEEN TO_DATE('01042004 00:00:00','DDMMYYYY HH24:MI:SS') AND TO_DATE('31032005 23:59:59','DDMMYYYY HH24:MI:SS')
			 GROUP BY cpt_pan_code;
		 EXCEPTION
        	 	WHEN NO_DATA_FOUND THEN
			l_hot_amt:=0;
			l_errmsg:='OK';
			WHEN OTHERS THEN
  			l_errmsg := 'Excp1 LP1 -- '||SQLERRM;
		 END; -- 3
--		 dbms_output.put_line('The hotlisted cards trans amount');
--		 dbms_output.put_line(l_hot_amt);

       END IF;
    END;
--- end of local procedure



---------- local procedure to find reissued card of hotlisted card --start
PROCEDURE	lp_search_reisu		( l_pan_code  IN VARCHAR2, l_reisu_pancode OUT VARCHAR2,l_reisu_amt OUT NUMBER,l_errmsg OUT VARCHAR2 )
  IS
  BEGIN
         l_reisu_amt :=0;
		 l_errmsg:='OK';
		 BEGIN -- 2
    	 SELECT chr_new_pan
         INTO l_reisu_pancode
         FROM CMS_HTLST_REISU
    	 WHERE chr_inst_code = inst_code
		 AND chr_pan_code =  l_pan_code
		 AND chr_mbr_numb = mbr_numb
         AND chr_ins_date BETWEEN TO_DATE('01042004 00:00:00','DDMMYYYY HH24:MI:SS') AND TO_DATE('31052005 23:59:59','DDMMYYYY HH24:MI:SS');
         EXCEPTION
    	 	WHEN NO_DATA_FOUND THEN
			l_errmsg:='OK';
			l_reisu_pancode:=NULL;
			l_reisu_amt:=0;
     		 WHEN OTHERS THEN
  			l_errmsg := 'Excp1 LP1 -- '||SQLERRM;
		 END; -- 2


--		dbms_output.put_line('Reissued pan.....');
 --       dbms_output.put_line(l_reisu_pancode);


-- if l_reisu_pancode is not null means the card was hotlisted and l_reisu_pancode has the new card
         IF  l_reisu_pancode IS NOT NULL THEN
		 BEGIN --3
			 SELECT SUM(cpt_trans_amt)
			 INTO l_reisu_amt
			 FROM CMS_PAN_TRANS
			 WHERE cpt_inst_code = inst_code
			 AND cpt_pan_code = l_reisu_pancode
			 AND cpt_mbr_numb =mbr_numb
			 AND cpt_trans_date BETWEEN TO_DATE('01042004 00:00:00','DDMMYYYY HH24:MI:SS') AND TO_DATE('31032005 23:59:59','DDMMYYYY HH24:MI:SS')
			 GROUP BY cpt_pan_code;
		 EXCEPTION
        	 	WHEN NO_DATA_FOUND THEN
			l_reisu_amt:=0;
			l_errmsg:='OK';
			WHEN OTHERS THEN
  			l_errmsg := 'Excp1 LP1 -- '||SQLERRM;
		 END; -- 3
       END IF;
--	   	 dbms_output.put_line('The reisu cards trans amount');
--		 dbms_output.put_line(l_reisu_amt);

    END;
--- end of local procedure




/*------------------main procedure starts----------------*/
BEGIN -- main

FOR x IN c1
LOOP

BEGIN -- for

errmsg:='OK';

	 v_pan_code:=x.cpt_pan_code;

	BEGIN
	SELECT cap_card_stat
	INTO v_card_stat
	FROM CMS_APPL_PAN
	WHERE cap_pan_code = v_pan_code;
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		 BEGIN
		 		 INSERT INTO CMS_MONEYBK_DET VALUES (	v_pan_code, 0, 'E', SYSDATE );
		 EXCEPTION
		 WHEN OTHERS THEN
		 	  errmsg := 'Excp   in inserting error record-- '||SQLERRM;
			   ROLLBACK;
		 END;

		 IF(errmsg='OK') THEN
		 		 COMMIT;
		 END IF;
--	when others then
		errmsg := 'Excp1  -- '||SQLERRM;
	END;

--initialize the total trans amount for the card to 0
	v_total_amt:=0;
--this is the trans amt from the hotlisted card if the currrent card is a reissued one
    v_hot_amt :=0;
--this is the trans amt from the reissued card if the currrent card is a closed one
	v_reisu_amt:=0;

--    dbms_output.put_line(v_pan_code);

	IF(errmsg='OK') THEN -- 1

--calculate the trans amount for the card from pan trans between 1 Apr 04 and 31 Mar 05
        BEGIN -- 1
		SELECT SUM(cpt_trans_amt)
		INTO v_total_amt
		FROM CMS_PAN_TRANS
		WHERE cpt_inst_code = inst_code
		AND cpt_pan_code =v_pan_code
		AND cpt_mbr_numb = mbr_numb
		AND cpt_trans_date BETWEEN TO_DATE('01042004 00:00:00','DDMMYYYY HH24:MI:SS') AND TO_DATE('31032005 23:59:59','DDMMYYYY HH24:MI:SS')
		GROUP BY cpt_pan_code;
         EXCEPTION
   	           WHEN NO_DATA_FOUND THEN
-- means no transactions were done with the card in  this period, hence total amount = 0
		       v_total_amt:=0;
			   WHEN OTHERS THEN
			   errmsg := 'Excp1 MP1 -- '||SQLERRM;
	     END; -- 1

--   dbms_output.put_line(v_total_amt);


--check if the card is reissued after  1 Apr 04 , then add the trans amounts of the hotlisted cards also
WHILE(v_pan_code IS NOT NULL)
LOOP
		BEGIN
	--		 	 		 dbms_output.put_line('Before calling LP search_hotlst_reisu.......');
	 	 				  lp_search_hotlst_reisu	(v_pan_code, v_hot_pancode ,v_hot_amt,errmsg );
		--	 	 		 dbms_output.put_line('After calling LP search_hotlst_reisu.......');
			--	 		 dbms_output.put_line(v_hot_amt);
				--		 dbms_output.put_line(errmsg);
						  IF(errmsg='OK') THEN
						  				 v_pan_code:=v_hot_pancode;
										  v_total_amt := v_total_amt + v_hot_amt;
						  END IF;
		 EXCEPTION
		 WHEN OTHERS THEN
		 errmsg:='Exp 2--- '|| v_pan_code || ' ' || SQLERRM;
		 END;
END LOOP ;

--if the card is hotlisted then find its reissue cards and add the trans amounts of the reissued cards also

			 	 	--	 dbms_output.put_line('If the card is open or hotlisted the second part  wont work as is not required.......');

			 	 		-- dbms_output.put_line('Before calling second LP lp_reisu.......');
-- 			 	 		 dbms_output.put_line('Total amt now :- ' ||v_total_amt);
	--		 	 		 dbms_output.put_line('If the card is closed  the second part  will  work as it  will search for a reissued card and further .......');

v_latest_pan:=v_pan_code;

v_pan_code:=x.cpt_pan_code;
v_latest_pan:=v_pan_code;------ in case of closed cards we try to insert the last reissued pan for that card in the next part , but for open and hotlisted cards the card is not reissued so it is the latest card


IF(v_card_stat=9) THEN
WHILE(v_pan_code IS NOT NULL)
LOOP
		BEGIN
				 lp_search_reisu	(v_pan_code, v_reisu_pancode ,v_reisu_amt,errmsg );
						  IF(errmsg='OK') THEN
						  				 v_pan_code:=v_reisu_pancode;
										 IF(v_reisu_pancode IS NOT NULL) THEN ---- in case of closed cards we try to insert the last reissued pan for that card.
										 		 v_latest_pan:=v_reisu_pancode;
										 END IF;
										  v_total_amt := v_total_amt + v_reisu_amt;
						  END IF;
		 EXCEPTION
		 WHEN OTHERS THEN
		 errmsg:='Exp 2--- '|| v_pan_code || ' ' || SQLERRM;
		 END;

		-- dbms_output.put_line('After calling LP search_hotlst_reisu.......');
END LOOP ;
END IF;

--if the total amount is greater than 10000
-- dbms_output.put_line('The total amtt' ||v_total_amt );
 IF(errmsg='OK') THEN
 				 IF v_total_amt >=10000 THEN
				    	 BEGIN
		 	   				 INSERT INTO CMS_MONEYBK_DET VALUES ( v_latest_pan, v_total_amt, 'Y', SYSDATE );

						 EXCEPTION
						 	 WHEN OTHERS THEN
							  errmsg:='Error in insertion' || SQLERRM;
							   ROLLBACK;
					     END;
  --  dbms_output.put_line('The total amt finally :- ' || v_total_amt);
							  IF(errmsg='OK') THEN
							  				  COMMIT;
         	  				END IF;
				END IF;
END IF;
END IF; -- first if errmsg :='OK'

END;
END LOOP;

END; -- main
/


