CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Acct_Close_Debit_old (
   instcode   IN       NUMBER,
   acctid     IN       VARCHAR2,
   rsncode    IN       NUMBER,
   remark     IN       VARCHAR2,
   prm_amount IN	   NUMBER,
   lupduser   IN       NUMBER,
   /*prm_sinkamt   IN       VARCHAR2,
   prm_sinkbankname   IN       VARCHAR2,
   prm_sinkbranch     IN       VARCHAR2,
   prm_sinkbankacct   IN       VARCHAR2,
   prm_sinkbankifcs   IN       VARCHAR2,*/
   errmsg     OUT      VARCHAR2
)
AS
   dum                 NUMBER;
   v_cap_prod_catg     VARCHAR2 (2);
   v_acctstat_code	   VARCHAR2(2);
   exp_reject_record   EXCEPTION;  -- Sn exception declaration on 10 sep 2008.

   CURSOR c1
   IS
      SELECT cpa_pan_code, cpa_mbr_numb, cpa_acct_posn
        FROM CMS_PAN_ACCT
       WHERE cpa_inst_code = instcode AND cpa_acct_id = acctid;

   CURSOR c2
   IS
      SELECT cca_cust_code
        FROM CMS_CUST_ACCT
       WHERE cca_acct_id = acctid;
--v_mbrnumb    VARCHAR2(3) ; -- Commented on 11 Sep 08 not used

-----------*****************************************************************************---------
BEGIN                                                             --main begin
   errmsg := 'OK';
   
   BEGIN
	   BEGIN  
	      SELECT CAM_STAT_CODE INTO v_acctstat_code FROM CMS_ACCT_MAST 
		  WHERE CAM_ACCT_ID = acctid AND cam_inst_code = instcode AND CAM_STAT_CODE != 2 ; 
	   EXCEPTION
	   			WHEN NO_DATA_FOUND
				THEN
	   			errmsg := 'Not a valid acct status for Account Close ';
				RAISE exp_reject_record;
	   		    WHEN OTHERS 
				THEN
	   		    errmsg := 'Not a valid acct status for Account Close '||SQLERRM;
				RAISE exp_reject_record;
	   END;                                                            --begin 1   
      FOR x IN c1
      LOOP
         BEGIN                                             --begin 1.1 starts
            SELECT cap_prod_catg
              INTO v_cap_prod_catg
              FROM CMS_APPL_PAN
             WHERE cap_pan_code = x.cpa_pan_code
               AND cap_mbr_numb = x.cpa_mbr_numb;
         EXCEPTION                                         --excp of begin 1.1
            WHEN NO_DATA_FOUND
            THEN
               errmsg := 'No such PAN ' || x.cpa_pan_code || ' found.';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               errmsg :=
                     'Error while selecting pan code '
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;                                                 --begin 1.1 ends

         BEGIN
            SELECT COUNT (ROWID)
              INTO dum
              FROM CMS_PAN_ACCT
             WHERE cpa_inst_code = instcode
               AND cpa_pan_code = x.cpa_pan_code
               AND cpa_mbr_numb = x.cpa_mbr_numb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               errmsg :=
                     'No record found for PAN '
                  || x.cpa_pan_code
                  || ' in pan account.';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               errmsg :=
                     'Error while selecting from pan account '
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;

----######################################## SINGLE ACCOUNT ######################
         IF dum = 1
         THEN
            --dbms_output.put_line('single accounts');
            --single accounts that means there is only one account linked to this pan
            --close the card and move that account to shadow table
            --insert into pan support
            --dbms_output.put_line('before insert into pan support');
                     --IF errmsg = 'OK' THEN -- Sn commented on 11 Sep 08
            BEGIN                                                 --Begin 1.2
               INSERT INTO CMS_PAN_SPPRT
                           (cps_inst_code, cps_pan_code, cps_mbr_numb,
                            cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                            cps_func_remark, cps_ins_user, cps_lupd_user,
                            cps_cmd_mode
                           )                                 -- RAHUL 2 APR 05
                    VALUES (instcode, x.cpa_pan_code, x.cpa_mbr_numb,
                            v_cap_prod_catg, 'ACCCL1', rsncode,
                            remark, lupduser, lupduser,
                            0
                           );                                -- RAHUL 2 APR 05
            --dbms_output.put_line('after insert into pan support');
            EXCEPTION                                      --Excp of begin 1.2
               WHEN OTHERS
               THEN
                  errmsg :=
                        'Error while inserting into pan support '
                     || SUBSTR (SQLERRM, 1, 300);
                  RAISE exp_reject_record;
            END;                                            --End of begin 1.2

                     --END IF; -- En commented on 11 Sep 08
            --dbms_output.put_line('before updation of appl pan for status of the pan as closed');

            --Sn update card stat
            BEGIN                                 -- Sn exception on 11 Sep 08
               UPDATE CMS_APPL_PAN
                  SET cap_card_stat = 9,
                      cap_lupd_user = lupduser
                WHERE cap_pan_code = x.cpa_pan_code
                  AND cap_mbr_numb = x.cpa_mbr_numb;

               IF SQL%ROWCOUNT != 1
               THEN
                  errmsg :=
                        'Problem in updation of status for pan '
                     || x.cpa_pan_code
                     || '.';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  errmsg :=
                        'Problem in updation of status for pan '
                     || x.cpa_pan_code
                     || ' . '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;                                  -- En exception on 11 Sep 08

            --En update card stat
			
----------------------------------------------------------------------------------
         --Caf Refresh
            IF errmsg = 'OK'
            THEN                                             -- Sn caf Refresh
               BEGIN                                 --Sn Begin 2 Caf Refresh
                  SELECT COUNT (ROWID)
                    INTO dum
                    FROM CMS_CAF_INFO
                   WHERE cci_inst_code = instcode
                     AND cci_pan_code = RPAD (x.cpa_pan_code, 19, ' ')
                     AND cci_mbr_numb = x.cpa_mbr_numb;

                  IF dum = 1
                  THEN
                     --that means there is a row in cafinfo for that pan but file is not generated
                     BEGIN                       -- Sn exception on 11 Sep 08
                        DELETE FROM CMS_CAF_INFO
                              WHERE cci_inst_code = instcode
                                AND cci_pan_code =
                                                RPAD (x.cpa_pan_code, 19, ' ')
                                AND cci_mbr_numb = x.cpa_mbr_numb;

                        IF SQL%ROWCOUNT != 1
                        THEN
                           errmsg :=
                                 'Problem in deletion of pan '
                              || x.cpa_pan_code
                              || '.'
                              || ' from caf info';
                           RAISE exp_reject_record;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           errmsg :=
                                 'Problem in deletion of pan '
                              || x.cpa_pan_code
                              || ' from caf info. '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;                         -- En exception on 11 Sep 08
                  END IF;                                 -- En End of dum = 1

                  --//// call the procedure to insert into cafinfo
                  Sp_Caf_Rfrsh (instcode,
                                x.cpa_pan_code,
                                NULL,
                                SYSDATE,
                                'C',
                                NULL,
                                'ACCCL',
                                lupduser,
                                errmsg
                               );

                  --//// dbms_output.put_line('Test point for error from caf refresh'||errmsg);
                  IF errmsg != 'OK'
                  THEN
                     errmsg :=
                              'From caf refresh ' || SUBSTR (SQLERRM, 1, 300);
                     RAISE exp_reject_record;
                  ELSIF errmsg = 'OK'
                  THEN
                     --dbms_output.put_line('Got ok from caf refresh proc, now updating caf info');
                     BEGIN
                        UPDATE CMS_CAF_INFO
                           SET cci_seg31_acct_cnt = '00'
                         WHERE cci_inst_code = instcode
                           AND cci_pan_code = RPAD (x.cpa_pan_code, 19, ' ')
                           AND cci_mbr_numb = x.cpa_mbr_numb;

                        IF SQL%ROWCOUNT != 1
                        THEN
                           errmsg :=
                                 'Problem in updation of pan '
                              || x.cpa_pan_code
                              || '.'
                              || ' in caf info';
                           RAISE exp_reject_record;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           errmsg :=
                                 'Problem in updation of pan '
                              || x.cpa_pan_code
                              || ' in caf info. '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;                         -- En exception on 11 Sep 08
                  END IF;                          -- En End of errmsg != 'OK'
               EXCEPTION                               --Exception for begin 2
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     errmsg :=
                           'Error from Caf Refresh main '
                        || SUBSTR (SQLERRM, 1, 300);
                     RAISE exp_reject_record;
               END;                               --End of Begin 2 Caf Refresh

    --end caf refresh
----------------------------------------------------------------------------------
                  -- IF errmsg = 'OK' THEN --Sn commented on 11 Sep 08
                        --dbms_output.put_line('before delete from pan_acct');
                        --before deleting move this(now non-existent relation of pan and acct) relation to a separat
                        --e table for history purposes
               BEGIN
                  INSERT INTO CMS_PAN_ACCT_HIST
                              (cpa_inst_code, cpa_pan_code, cpa_mbr_numb,
                               cpa_acct_id,              --added on 25/09/2002
                                           cpa_acct_posn, cpa_ins_user,
                               cpa_lupd_user
                              )
                       VALUES (instcode, x.cpa_pan_code, x.cpa_mbr_numb,
                               acctid,                   --added on 25/09/2002
                                      x.cpa_acct_posn, lupduser,
                               lupduser
                              );
               EXCEPTION                                       --Excp of begin
                  WHEN OTHERS
                  THEN
                     errmsg :=
                           'Error while inserting into pan account history '
                        || SUBSTR (SQLERRM, 1, 300);
                     RAISE exp_reject_record;
               END;                                             --End of begin

               BEGIN                              -- Sn exception on 11 Sep 08
                  DELETE FROM CMS_PAN_ACCT
                        WHERE cpa_inst_code = instcode
                          AND cpa_pan_code = x.cpa_pan_code
                          AND cpa_mbr_numb = x.cpa_mbr_numb
                          AND cpa_acct_posn = x.cpa_acct_posn;

                  --dbms_output.put_line('after  delete from pan_acct--->'||SQL%ROWCOUNT);
                  IF SQL%ROWCOUNT != 1
                  THEN
                     errmsg :=
                           'Problem in deletion of pan '
                        || x.cpa_pan_code
                        || '.'
                        || ' from pan account';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     errmsg :=
                           'Problem in deletion of pan '
                        || x.cpa_pan_code
                        || ' from pan account. '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;                               -- En exception on 11 Sep 08
            -- END IF; -- Sn for errmsg = 'OK' commented on 11 Sep 08
            END IF;                     -- Sn for errmsg = 'OK' of caf Refresh
----######################################## MULTIPLE ACCOUNT ######################
         ELSE              --means dum contains the the multiple account count
            --that means there are multiple accnts linked to this pan and shifting has to be done
            --close the card and move the account  to shadow table
            --insert into pan support
            --IF errmsg = 'OK' THEN -- Sn commented on 11 Sep 08
            BEGIN                                                 --Begin 1.2
               INSERT INTO CMS_PAN_SPPRT
                           (cps_inst_code, cps_pan_code, cps_mbr_numb,
                            cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                            cps_func_remark, cps_ins_user, cps_lupd_user,
                            cps_cmd_mode
                           )
                    VALUES (instcode, x.cpa_pan_code, x.cpa_mbr_numb,
                            v_cap_prod_catg, 'ACCCL2', rsncode,
                            remark, lupduser, lupduser,
                            0
                           );
            EXCEPTION                                      --Excp of begin 1.2
               --the when uniq_excp_acct exception commented on 10-07-02
               WHEN OTHERS
               THEN
                  errmsg :=
                        'Error while inserting into pan support '
                     || SUBSTR (SQLERRM, 1, 300);
                  RAISE exp_reject_record;
            END;                                            --End of begin 1.2

            --END IF;  En commented on 11 Sep 08

            --Changed Done by Christopher on 10April04 to insert records to shadow table   .......Change Starts
            BEGIN
               INSERT INTO CMS_PAN_ACCT_HIST
                           (cpa_inst_code, cpa_pan_code, cpa_mbr_numb,
                            cpa_acct_id, cpa_acct_posn, cpa_ins_user,
                            cpa_lupd_user
                           )
                    VALUES (instcode, x.cpa_pan_code, x.cpa_mbr_numb,
                            acctid, x.cpa_acct_posn, lupduser,
                            lupduser
                           );
            EXCEPTION                                          --Excp of begin
               WHEN OTHERS
               THEN
                  errmsg :=
                        'Error while inserting into pan account history '
                     || SUBSTR (SQLERRM, 1, 300);
                  RAISE exp_reject_record;
            END;                                                --End of begin

            --Changed Done by Christopher on 10April04 to insert records to shadow table   .......Change Ends
            BEGIN
               DELETE FROM CMS_PAN_ACCT
                     WHERE cpa_inst_code = instcode
                       AND cpa_pan_code = x.cpa_pan_code
                       AND cpa_mbr_numb = x.cpa_mbr_numb
                       AND cpa_acct_posn = x.cpa_acct_posn;

               IF SQL%ROWCOUNT != 1
               THEN
                  errmsg :=
                        'Problem in deletion of pan '
                     || x.cpa_pan_code
                     || '.'
                     || ' from pan account';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  errmsg :=
                        'Problem in deletion of pan '
                     || x.cpa_pan_code
                     || ' from pan account. '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;                                  -- En exception on 11 Sep 08

            --shifting
            BEGIN                                 -- Sn exception on 11 Sep 08
               UPDATE CMS_PAN_ACCT
                  SET cpa_acct_posn = cpa_acct_posn - 1,
                      cpa_lupd_user = lupduser
                WHERE cpa_inst_code = instcode
                  AND cpa_pan_code = x.cpa_pan_code
                  AND cpa_mbr_numb = x.cpa_mbr_numb
                  AND cpa_acct_posn > x.cpa_acct_posn;
            EXCEPTION
               WHEN OTHERS
               THEN
                  errmsg :=
                        'Problem in updation of pan '
                     || x.cpa_pan_code
                     || ' in pan account. '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;                                  -- En exception on 11 Sep 08

         --code added on 27-07-02 to update the account number in cms_appl_pan as that one which is the ne
--w account in position 1
         --this condition will occur only if the pan has multiple accounts and the account number with pos
--ition 1 is closed
------------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
            IF x.cpa_acct_posn = 1
            THEN
               BEGIN                             -- Sn exception on 11 Sep 08
                  UPDATE CMS_APPL_PAN
                     SET (cap_acct_id, cap_acct_no) =
                            (SELECT cpa_acct_id, cam_acct_no
                               FROM CMS_PAN_ACCT a, CMS_ACCT_MAST b
                              WHERE b.cam_inst_code = a.cpa_inst_code
                                AND b.cam_acct_id = a.cpa_acct_id
                                AND a.cpa_pan_code = x.cpa_pan_code
                                AND a.cpa_mbr_numb = x.cpa_mbr_numb
                                AND a.cpa_acct_posn = 1)
                   WHERE cap_pan_code = x.cpa_pan_code
                     AND cap_mbr_numb = x.cpa_mbr_numb
					 AND cap_inst_code = instcode;

                  IF SQL%ROWCOUNT != 1
                  THEN
                     errmsg :=
                           'Problem in updation of pan '
                        || x.cpa_pan_code
                        || '.'
                        || ' in appl pan';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     errmsg :=
                           'Problem in updation of pan '
                        || x.cpa_pan_code
                        || ' in appl pan. '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;                               -- En exception on 11 Sep 08

--Changes done for setting the acct as primary acct in acct_master ....Change Starts
               BEGIN                              -- Sn exception on 11 Sep 08
                  UPDATE CMS_ACCT_MAST
                     SET cam_stat_code = 8
                   WHERE cam_inst_code = instcode
                     AND cam_acct_id =
                            (SELECT cpa_acct_id
                               FROM CMS_PAN_ACCT
                              WHERE cpa_pan_code = x.cpa_pan_code
                                AND cpa_mbr_numb = x.cpa_mbr_numb
                                AND cpa_acct_posn = 1);

                  IF SQL%ROWCOUNT != 1
                  THEN
                     errmsg :=
                           'Problem in updation of status for pan '
                        || x.cpa_pan_code
                        || '.'
                        || ' in acct mast';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     errmsg :=
                           'Problem in updation of status for pan '
                        || x.cpa_pan_code
                        || ' in acct mast. '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;                               -- En exception on 11 Sep 08
--Changes done for setting the acct as primary acct in acct_master  ....Change ends .
            END IF;                            --En end of x.cpa_acct_posn = 1

------------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
------------------------------------Caf Refresh-------------------------------
            IF errmsg = 'OK'
            THEN
               BEGIN                                                --Begin 3
                  SELECT COUNT (ROWID)
                    INTO dum
                    FROM CMS_CAF_INFO
                   WHERE cci_inst_code = instcode
                     AND cci_pan_code = RPAD (x.cpa_pan_code, 19, ' ')
                     AND cci_mbr_numb = x.cpa_mbr_numb;

                  IF dum = 1
                  THEN
                     --that means there is a row in cafinfo for that pan but file is not generated
                     BEGIN
                        DELETE FROM CMS_CAF_INFO
                              WHERE cci_inst_code = instcode
                                AND cci_pan_code =
                                                RPAD (x.cpa_pan_code, 19, ' ')
                                AND cci_mbr_numb = x.cpa_mbr_numb;

                        IF SQL%ROWCOUNT != 1
                        THEN
                           errmsg :=
                                 'Problem in deletion of pan '
                              || x.cpa_pan_code
                              || '.'
                              || ' from caf info';
                           RAISE exp_reject_record;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           errmsg :=
                                 'Problem in deletion of pan '
                              || x.cpa_pan_code
                              || ' from caf info. '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;                         -- En exception on 11 Sep 08
                  END IF;                                    -- End of dum = 1

                  --//////call the procedure to insert into cafinfo
                  Sp_Caf_Rfrsh (instcode,
                                x.cpa_pan_code,
                                NULL,
                                SYSDATE,
                                'C',
                                NULL,
                                'ACCCL',
                                lupduser,
                                errmsg
                               );

                  --//////call the procedure to insert into cafinfo
                  IF errmsg != 'OK'
                  THEN
                     errmsg :=
                              'From caf refresh ' || SUBSTR (SQLERRM, 1, 300);
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION                                              --Excp 3
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     errmsg :=
                           'Error from Caf Refresh main '
                        || SUBSTR (SQLERRM, 1, 300);
                     RAISE exp_reject_record;
               END;                                           --End of begin 3
            END IF;                       -- Sn end of caf rfrsh errmsg = 'OK'
         END IF;                                          -- Sn end of dum = 1
----######################################## SINGLE ACCOUNT ######################
   --EXIT WHEN c1%NOTFOUND;
      END LOOP;                                            -- End of cursor C1

-----------*****************************************************************************---------
      IF errmsg = 'OK'
      THEN
         FOR y IN c2
         LOOP
            BEGIN
               INSERT INTO CMS_CLOSED_ACCTS
                           (cca_inst_code, cca_cust_code, cca_acct_id,
                            cca_ins_user, cca_lupd_user
                           )
                    VALUES (instcode, y.cca_cust_code, acctid,
                            lupduser, lupduser
                           );
            EXCEPTION          --Excp of begin on 10 sep 08 to catch exception
               WHEN OTHERS
               THEN
                  errmsg :=
                        'Error while inserting into closed accounts '
                     || SUBSTR (SQLERRM, 1, 300);
                  RAISE exp_reject_record;
            END;                                                --End of begin
         --EXIT WHEN c2%NOTFOUND;
         END LOOP;                                         -- End of cursor C2

--commented on 17-06-02, deletion replaced by updation because the table cms_appl_pan references the
-- cms_acct_mast
         UPDATE CMS_CUST_ACCT
            SET cca_rel_stat = 'N',
                cca_lupd_user = lupduser,
				CCA_FUNDTRANS_AMT = prm_amount --, 
				/*CCA_FUNDTRANS_ACCTNO = prm_sinkbankacct,
				CCA_FUNDTRANS_BANK = prm_sinkbankname, 
				CCA_FUNDTRANS_BRANCH = prm_sinkbranch, 
				CCA_FUNDTRANS_IFCS = prm_sinkbankifcs,
				 CCA_FUNDTRANS_FILEGEN_FLAG = 'N'*/
          WHERE cca_acct_id = acctid;

         BEGIN
            UPDATE CMS_ACCT_MAST
               SET cam_stat_code = 2,
                   cam_lupd_user = lupduser
             WHERE cam_inst_code = instcode AND cam_acct_id = acctid;

            IF SQL%ROWCOUNT != 1
            THEN
               errmsg := 'Problem in updation of status in acct mast';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               errmsg :=
                     'Problem in updation of status in acct mast. '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;                                     -- En exception on 11 Sep 08
      END IF;                                    -- End of errmsg = 'OK' of C2
   EXCEPTION                                                          --excp 1
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         errmsg := 'Exception from main begin ' || SUBSTR (SQLERRM, 1, 200);
   END;                                                          --end begin 1
--*********************************************************************************
EXCEPTION                                                       --excp of main
   WHEN exp_reject_record
   THEN
      errmsg := errmsg;
   WHEN OTHERS
   THEN
      errmsg := 'Error From main ' || SUBSTR (SQLERRM, 1, 200);
END;                                                             --end of main
/


