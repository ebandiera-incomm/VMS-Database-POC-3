CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Money_Back_calc(inst_code IN NUMBER, userPin IN NUMBER , errmsg OUT VARCHAR2)
AS

v_errmsg VARCHAR2(100);
v_total_amt CMS_PAN_TRANS.cpt_trans_amt%TYPE;
v_hot_amt CMS_PAN_TRANS.cpt_trans_amt%TYPE;
v_reisu_amt CMS_PAN_TRANS.cpt_trans_amt%TYPE;
v_pan_code CMS_PAN_TRANS.cpt_pan_code%TYPE;
v_hot_pancode CMS_PAN_TRANS.cpt_pan_code%TYPE;
v_reisu_pancode CMS_PAN_TRANS.cpt_pan_code%TYPE;
v_latest_pan CMS_PAN_TRANS.cpt_pan_code%TYPE;
v_bin_no CMS_BIN_MAST.CBM_INST_BIN%TYPE;
v_scheme_amt CMS_MONEYBACK_MAST.CMM_MB_AMT%TYPE;
v_scheme_code CMS_MONEYBACK_MAST.CMM_MBSCHEME_CODE%TYPE;
v_final_amt NUMBER(10);
v_cap_card_stat CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
v_cap_mb_date   CMS_APPL_PAN.CAP_NEXT_MB_DATE%TYPE;
v_mb_period NUMBER(10);
mbr_numb  VARCHAR2(3):='000';
v_scheme_desc VARCHAR2(40);
v_from_date DATE;
v_to_date DATE;

CURSOR C_BIN IS
SELECT CBS_INST_BIN, CBS_MB_PERIOD FROM CMS_BIN_SCHEME;

CURSOR C_PANS (binNo NUMBER) IS
SELECT /*+INDEX (CMS_APPL_PAN PK_APPL_PAN)*/ CAP_PAN_CODE, CAP_CARD_STAT, CAP_NEXT_MB_DATE, CAP_ACCT_NO, SUBSTR(CAP_ACCT_NO,1,4) BRANCODE
FROM CMS_APPL_PAN
WHERE  SUBSTR(CAP_PAN_CODE,1,6) = binNo
AND CAP_MBR_NUMB = mbr_numb
AND CAP_NEXT_MB_DATE <  SYSDATE
AND CAP_CARD_STAT = '1'; -- MoneyBack not calculated for the Cards which are hotlisted and not reissued


---------- local procedure to find hotlisted card of reissued card --start
PROCEDURE	lp_search_hotlst_reisu		( l_pan_code  IN VARCHAR2, v_from_date IN DATE, v_to_date IN DATE, l_hot_pancode OUT VARCHAR2,l_hot_amt OUT NUMBER,l_errmsg OUT VARCHAR2 )
  IS
  BEGIN

   dbms_output.put_line('l_pan_code-'||l_pan_code||' v_from_date-'||v_from_date||' v_to_date-'||v_to_date);

  	   	 l_errmsg:='OK';
         l_hot_amt :=0;
		 BEGIN -- 2
    	  SELECT chr_pan_code
         INTO l_hot_pancode
         FROM CMS_HTLST_REISU
    	 WHERE chr_inst_code = inst_code
		 AND chr_new_pan =  l_pan_code
		 AND chr_mbr_numb = mbr_numb
       AND chr_ins_date > v_from_date ;
       --       BETWEEN v_from_date and v_to_date;

       dbms_output.put_line('l_hot_pancode-'||l_hot_pancode);
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
			 SELECT NVL(SUM(cpt_trans_amt),'0')
			 INTO l_hot_amt
			 FROM CMS_PAN_TRANS
			 WHERE cpt_inst_code = inst_code
			 AND cpt_pan_code = l_hot_pancode
			 AND cpt_mbr_numb =mbr_numb
          AND CPT_REC_TYP = '02'
			 AND cpt_trans_date BETWEEN v_from_date AND v_to_date
			 GROUP BY cpt_pan_code;

         dbms_output.put_line('l_hot_amt-'||l_hot_amt);

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


/*------------------main procedure starts----------------*/
BEGIN -- main

   FOR x_bin IN C_BIN
      LOOP
         BEGIN --1
         errmsg:='OK';
         v_bin_no:=x_bin.CBS_INST_BIN;
         v_mb_period:=x_bin.CBS_MB_PERIOD;

         dbms_output.put_line('Bin - '||v_bin_no);

         FOR x_pan IN C_PANS (v_bin_no)
         LOOP
            BEGIN --1.1
                  v_pan_code:=x_pan.CAP_PAN_CODE;
                  v_latest_pan:=v_pan_code;
                  v_cap_card_stat:=x_pan.CAP_CARD_STAT;
                  v_cap_mb_date:=x_pan.CAP_NEXT_MB_DATE; -- cap_moneyback_date

                  --dbms_output.put_line('Pan - '||v_pan_code);

                  v_total_amt:=0;  --initialize the total trans amount for the card to 0
                  v_hot_amt :=0;  --this is the trans amt from the hotlisted card if the currrent card is a reissued one
                  v_reisu_amt:=0;  --this is the trans amt from the reissued card if the currrent card is a closed one

                  v_from_date:= TO_DATE(TO_CHAR(v_cap_mb_date-v_mb_period,'DDMMYYYY')||' 00:00:00','DDMMYYYY HH24:MI:SS');
                  v_to_date:= TO_DATE(TO_CHAR(v_cap_mb_date,'DDMMYYYY')||' 23:59:59','DDMMYYYY HH24:MI:SS');

                     BEGIN --1.1.2
                        --dbms_output.put_line('v_cap_mb_date - '||v_cap_mb_date);
                         SELECT NVL(SUM(cpt_trans_amt),'0')
                         INTO v_total_amt
                         FROM CMS_PAN_TRANS
                         WHERE cpt_inst_code = inst_code
                         AND cpt_pan_code =v_pan_code
                         AND cpt_mbr_numb = mbr_numb
                         AND CPT_REC_TYP = '02'
                         AND cpt_trans_date BETWEEN
                         v_from_date AND v_to_date;

                         --dbms_output.put_line('v_total_amt - '||v_total_amt);
                         --TO_DATE('01042004 00:00:00','DDMMYYYY HH24:MI:SS') AND TO_DATE('31032005 23:59:59','DDMMYYYY HH24:MI:SS')
                        EXCEPTION
                              WHEN NO_DATA_FOUND THEN  -- No Transactions done on the card in the specified period
                              v_total_amt:=0;
                        WHEN OTHERS THEN
                        errmsg := 'Excp 1.1.2 -- '||SQLERRM;
                     END; -- 1.1.2


                     dbms_output.put_line('%%%%%%%% v_pan_code - '||v_pan_code ||'    amt'||v_total_amt);

                     IF v_total_amt < 10000 THEN
                        --check if the card is reissued between the specied period , then add the trans amounts of the hotlisted cards also
                        WHILE(v_pan_code IS NOT NULL)
                        LOOP
                              dbms_output.put_line('%%%%%%%% ');
                              BEGIN --1.1.3
                                      lp_search_hotlst_reisu	(v_pan_code, v_from_date, v_to_date, v_hot_pancode ,v_hot_amt,errmsg );
                                      IF(errmsg='OK') THEN
                                           v_pan_code:=v_hot_pancode;
                                           v_total_amt := v_total_amt + v_hot_amt;
                                      END IF;
                               EXCEPTION
                               WHEN OTHERS THEN
                               errmsg:='Exp --1.1.3--- '|| v_pan_code || ' ' || SQLERRM;
                               END; --1.1.3
                        END LOOP ;
                     END IF;

                     v_pan_code:=v_latest_pan;

                     --dbms_output.put_line('pan-'||v_latest_pan||'  amt-'||v_total_amt);

--_____________________________________________________________________________________________________
/*                     IF(v_cap_card_stat=9) THEN
                     WHILE(v_pan_code IS NOT NULL)
                     LOOP
                           BEGIN --1.1.4

                                  lp_search_reisu	(v_pan_code, v_cap_mb_date, v_mb_period, v_reisu_pancode ,v_reisu_amt,errmsg );
                                  --dbms_output.put_line('reissue - ' ||v_reisu_pancode|| ' errmsg-'||errmsg);
                                   IF(errmsg='OK') THEN
                                              v_pan_code:=v_reisu_pancode;
                                              IF(v_reisu_pancode IS NOT NULL) THEN ---- in case of closed cards we try to insert the last reissued pan for that card.
                                                    v_latest_pan:=v_reisu_pancode;
                                              END IF;
                                               v_total_amt := v_total_amt + v_reisu_amt;
                                   END IF;
                            EXCEPTION
                            WHEN OTHERS THEN
                            errmsg:='Exp --1.1.4--- '|| v_pan_code || ' ' || SQLERRM;
                            END; --1.1.4
                     END LOOP ;
                     END IF;
*/
--_____________________________________________________________________________________________________

                     --if the total amount is greater than 10000
                     dbms_output.put_line('pan-'||v_latest_pan||'  amt-'||v_total_amt);
                      IF(errmsg='OK') THEN
                         IF v_total_amt >=10000 THEN
                            BEGIN --1.1.5

                               SELECT CMM_MBSCHEME_CODE, CMM_MB_AMT, CMM_MB_DESC INTO v_scheme_code, v_scheme_amt, v_scheme_desc
                               FROM CMS_MONEYBACK_MAST, CMS_BIN_SCHEME
                               WHERE CMM_MBSCHEME_CODE=CBS_MBSCHEME_CODE
                               AND CBS_INST_BIN=v_bin_no;

                               v_final_amt:=v_scheme_amt;

                               INSERT INTO CMS_MONEYBK_DET VALUES ( v_latest_pan, v_final_amt, 'N', SYSDATE,v_scheme_desc, x_pan.CAP_ACCT_NO, x_pan.BRANCODE,'',NULL );

                            EXCEPTION
                            WHEN OTHERS THEN
                              errmsg:='Excpe --1.1.5 Error in insertion' || SQLERRM;
                              ROLLBACK;
                            END; --1.1.5

                         END IF;
                         ------Update all the pans for this bin
                              UPDATE CMS_APPL_PAN SET CAP_NEXT_MB_DATE=v_cap_mb_date + v_mb_period
                              WHERE CAP_PAN_CODE=v_latest_pan
                              AND CAP_MBR_NUMB=mbr_numb;
                              IF(errmsg='OK') THEN
                                 COMMIT;
                              END IF;
                      END IF;

            EXCEPTION
            WHEN OTHERS THEN
            ERRMSG:='EXCP 1.1- '||SQLCODE||'---'||SQLERRM;
            END; --1.1

         END LOOP;

         EXCEPTION
         WHEN OTHERS THEN
         ERRMSG:='EXCP 1- '||SQLCODE||'---'||SQLERRM;
         END; --1
      END LOOP;
      errmsg:='OK';
      EXCEPTION
      WHEN OTHERS THEN
      errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
   END;
   /*

update cms_appl_pan set cap_next_mb_date = sysdate -2 where
cap_pan_code in ('4213950012900164','4667061234000089', '4213950012000015',
  '4213950012900164','4667060001002146','4667060001002153');


      declare errmsg varchar2(100);
      begin
            Sp_Money_Back_calc(1,1,errmsg);
      dbms_output.put_line('errmsg - '||errmsg);
      end;
   */

---------- local procedure to find reissued card of hotlisted card --start
/*PROCEDURE	lp_search_reisu		( l_pan_code  IN VARCHAR2, l_mb_date IN DATE, l_mb_period IN NUMBER, l_reisu_pancode OUT VARCHAR2,l_reisu_amt OUT NUMBER,l_errmsg OUT VARCHAR2 )
  IS
  BEGIN

   dbms_output.put_line('inst_code -'||inst_code);
   dbms_output.put_line('l_pan_code -'||l_pan_code);
   dbms_output.put_line('mbr_numb -'||mbr_numb);
   dbms_output.put_line('l_mb_date -'||l_mb_date);

         l_reisu_amt :=0;
		 l_errmsg:='OK';
		 BEGIN -- 2
    	 SELECT chr_new_pan
         INTO l_reisu_pancode
         FROM CMS_HTLST_REISU
    	 WHERE chr_inst_code = inst_code
		 AND chr_pan_code =  l_pan_code
		 AND chr_mbr_numb = mbr_numb
       AND chr_ins_date BETWEEN add_months(l_mb_date, -l_mb_period) and l_mb_date ;
         EXCEPTION
    	 	WHEN NO_DATA_FOUND THEN
         dbms_output.put_line('No Data Found');
			l_errmsg:='OK';
			l_reisu_pancode:=NULL;
			l_reisu_amt:=0;
     		 WHEN OTHERS THEN
  			l_errmsg := 'Excp1 LP1 -- '||SQLERRM;
		 END; -- 2


--		dbms_output.put_line('Reissued pan.....');
 --       dbms_output.put_line(l_reisu_pancode);


-- if l_reisu_pancode is not null means the card was hotlisted and l_reisu_pancode has the new card

dbms_output.put_line('l_reisu_pancode-'|| nvl(l_reisu_pancode,'null'));
dbms_output.put_line('l_mb_date-'||l_mb_date);
         IF  l_reisu_pancode IS NOT NULL THEN
		 BEGIN --3
			 SELECT SUM(cpt_trans_amt)
			 INTO l_reisu_amt
			 FROM CMS_PAN_TRANS
			 WHERE cpt_inst_code = inst_code
			 AND cpt_pan_code = l_reisu_pancode
			 AND cpt_mbr_numb =mbr_numb
          and CPT_REC_TYP = '02'
			 AND cpt_trans_date BETWEEN add_months(l_mb_date, -l_mb_period) and l_mb_date
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
dbms_output.put_line('l_reisu_amt-'||l_reisu_amt);
    END;
--- end of local procedure

*/
/


