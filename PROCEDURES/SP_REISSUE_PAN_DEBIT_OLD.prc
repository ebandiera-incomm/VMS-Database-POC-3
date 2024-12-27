CREATE OR REPLACE PROCEDURE VMSCMS.sp_reissue_pan_debit_old (
   instcode          IN       NUMBER,
   pancode           IN       VARCHAR2,
   mbrnumb           IN       VARCHAR2,
   remark            IN       VARCHAR2,
   rsncode           IN       NUMBER,
   lupduser          IN       NUMBER,
   newpan            OUT      VARCHAR2,
   applprocess_msg   OUT      VARCHAR2,
   errmsg            OUT      VARCHAR2
)
AS
   v_dup_rec_count     NUMBER (3);
   v_cap_prod_catg     VARCHAR2 (2);
   v_mbrnumb           VARCHAR2 (3);
   dum                 NUMBER (1);
   v_cap_cafgen_flag   CHAR (1);
   v_cap_card_stat     CHAR (1);
   software_pin_gen    CHAR (1);
   v_check_bin         NUMBER (1);
   v_old_bin           NUMBER (1);
   v_acct_no		   CMS_APPL_PAN.cap_acct_no%TYPE;
   v_tran_code		   VARCHAR2(2);
   v_tran_mode		   VARCHAR2(1);
   v_tran_type		   VARCHAR2(1);
   v_delv_chnl		   VARCHAR2(2);
   v_feetype_code	   CMS_FEE_MAST.cfm_feetype_code%TYPE;
   v_fee_code		   CMS_FEE_MAST.cfm_fee_code%TYPE;
   v_fee_amt		   NUMBER(4);
   v_cust_code		   CMS_CUST_MAST.ccm_cust_code%TYPE;
   v_acct_id		   CMS_APPL_PAN.cap_acct_id%TYPE;
   CURSOR c1
   IS
--this cursor finds the addon cards which were attached to the previousPAN so that they can be pointed towards the PAN being reissued
      SELECT cap_pan_code, cap_mbr_numb
        FROM cms_appl_pan
       WHERE cap_addon_link = pancode
         AND cap_mbr_numb = mbrnumb
         AND cap_addon_stat = 'A';
BEGIN                                                      --Main begin starts
   IF mbrnumb IS NULL
   THEN
      v_mbrnumb := '000';
   ELSE
      v_mbrnumb := mbrnumb;
   END IF;

   errmsg := 'OK';

   /* --Sn Check Bin for old cards
    BEGIN
       SELECT 1
         INTO v_old_bin
         FROM cms_bin_mast
        WHERE cbm_inst_bin = SUBSTR (pancode, 1, 6) AND cbm_combi_flag = 'N';
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          errmsg :=
                'PAN : '
             || pancode
             || '  has Invalid Bin    '
             || SUBSTR (pancode, 1, 6)
             || 'FOR NORMAL Reissue ';
          RETURN;
       WHEN OTHERS
       THEN
          errmsg :=
                'Error while selecting  old pan for reissue  '
             || SUBSTR (SQLERRM, 1, 230);
          RETURN;
    END;*/

   --En Check for old cards
   /* BEGIN
       SELECT 1
         INTO v_check_bin
         FROM cms_prod_bin, cms_bin_mast
        WHERE cbm_combi_flag = 'N'
          AND cbm_inst_bin = cpb_inst_bin
          AND cbm_inst_code = cpb_inst_code
          AND cpb_prod_code = newprodcode
          AND cpb_inst_code = 1;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          errmsg :=
                'Combi Product cannot be attached to  card '
             || pancode
             || '  having non -combi Product';
          RETURN;
       WHEN OTHERS
       THEN
          errmsg :=
              'Error while selecting newproduct  ' || SUBSTR (SQLERRM, 1, 230);
          RETURN;
    END;*/
   IF errmsg = 'OK'
   THEN
      BEGIN                                                  --begin 1 starts
         SELECT cap_prod_catg, cap_cafgen_flag, cap_card_stat,cap_acct_no,cap_cust_code
           INTO v_cap_prod_catg, v_cap_cafgen_flag, v_cap_card_stat,v_acct_no,v_cust_code
           FROM cms_appl_pan
          WHERE cap_pan_code = pancode AND cap_mbr_numb = v_mbrnumb;
      EXCEPTION                                              --excp of begin 1
         WHEN NO_DATA_FOUND
         THEN
            errmsg := 'No such PAN ' || pancode || ' found.';
         WHEN OTHERS
         THEN
            errmsg := 'Excp 1 -- ' || SQLERRM;
      END;                                                      --begin 1 ends
   END IF;

   IF errmsg = 'OK' AND v_cap_cafgen_flag = 'N'
   THEN                                                            --cafgen if
      errmsg :=
              'CAF has to be generated atleast once for this pan ' || pancode;
   ELSE
   
   	    --Sn Check fees if any attached
	  IF errmsg  = 'OK' THEN
	  
	  	 v_tran_code :=		'SI';
		 v_tran_mode :=		'0';   
   		 v_tran_type :=		'0';   
   		 v_delv_chnl := 	'05';
		 
		 
		 
		 Sp_Calc_Fees_Offline_Debit
							(
							 instcode    ,
							 pancode,
							 v_tran_code ,
							 v_tran_mode ,
							 v_delv_chnl ,
							 v_tran_type ,
							 v_feetype_code,
							 v_fee_code,
							 v_fee_amt,
							 errmsg
							 );
				IF  errmsg  <> 'OK' THEN
				RETURN;
				END IF; 
				
			IF  v_fee_amt > 0 THEN
			
				--Sn INSERT A RECORD INTO CMS_CHARGE_DTL
				BEGIN
					 INSERT INTO CMS_CHARGE_DTL
					 			 (
								  CCD_INST_CODE     ,
								  CCD_FEE_TRANS     ,
								  CCD_PAN_CODE      ,
								  CCD_MBR_NUMB      ,
								  CCD_CUST_CODE     ,
								  CCD_ACCT_ID       ,
								  CCD_ACCT_NO       , 
								  CCD_FEE_FREQ      ,
								  CCD_FEETYPE_CODE  ,
								  CCD_FEE_CODE      ,
								  CCD_CALC_AMT      ,
								  CCD_EXPCALC_DATE  ,
								  CCD_CALC_DATE     ,
								  CCD_FILE_DATE     ,
								  CCD_FILE_NAME     ,
								  CCD_FILE_STATUS   ,
								  CCD_INS_USER      ,
								  CCD_INS_DATE      ,
								  CCD_LUPD_USER     ,
								  CCD_LUPD_DATE     ,
								  CCD_PROCESS_ID    ,
								  CCD_PLAN_CODE   
								 )
								VALUES
								(  
								instcode,
								NULL,
								pancode,
								mbrnumb,
								v_cust_code,
								v_acct_id,
								v_acct_no,
								'R',
								v_feetype_code,
								v_fee_code,
								v_fee_amt,
								SYSDATE,
								SYSDATE,
								NULL,
								NULL,
								NULL,
								lupduser,
								SYSDATE,
								lupduser,
								SYSDATE,
								NULL,
								NULL
								);
				EXCEPTION
				WHEN OTHERS THEN
				
				errmsg := ' Error while inserting into charge dtl ' || SUBSTR(SQLERRM,1,200);
				RETURN;
				END;
				
				--En INSERT A RECORD INTO CMS_CHARGE_DTL
			END IF;
	  
	  END IF ;
      --now update the status of the old card as closed
      IF errmsg = 'OK' AND v_cap_card_stat != '1'
      THEN
         BEGIN                                               --begin 5 starts
            UPDATE cms_appl_pan
               SET cap_card_stat = 9,
                   cap_lupd_user = lupduser
             WHERE cap_inst_code = instcode
               AND cap_pan_code = pancode
               AND cap_mbr_numb = v_mbrnumb;

            IF SQL%ROWCOUNT != 1
            THEN
               errmsg :=
                   'Problem in updation of status for pan ' || pancode || '.';
            END IF;
         EXCEPTION                                           --excp of begin 4
            WHEN OTHERS
            THEN
               errmsg := 'Excp 5 -- ' || SQLERRM;
         END;                                                   --begin 5 ends
      END IF;

      IF errmsg = 'OK'
      THEN
         BEGIN                                               --begin 2 starts
            sp_gen_reissuepan_pcms (instcode,
                                    pancode,
                                    mbrnumb,
                                    lupduser,
                                    newpan,
                                    applprocess_msg,
                                    errmsg
                                   );

            --added newprodcode and newprodcat as parameters

            -- the exra paramaters in the above line have been added for the purpose of re-issuing
            -- the card as a separate product
            IF errmsg != 'OK'
            THEN
               errmsg := 'From sp_gen_pan_pan -- ' || errmsg;
            END IF;

            --Caf Refresh for new pan
            software_pin_gen := 'N';

--means that the software pin generation will be out of the system so generate caf here itself

            --to be parameterinsed at the inst level.
            IF software_pin_gen = 'N'
            THEN                                             --soft_pin_gen_if
               IF errmsg = 'OK'
               THEN
                  BEGIN                                             --Begin 6
                     --call the procedure to insert into cafinfo
                     sp_caf_rfrsh (instcode,
                                   newpan,
                                   NULL,
                                   SYSDATE,
                                   'A',
                                   remark,
                                   'NEW',
                                   lupduser,
                                   errmsg
                                  );

                     IF errmsg != 'OK'
                     THEN
                        errmsg := 'From caf refresh for new pan-- ' || errmsg;
                     END IF;
                  EXCEPTION                                           --Excp 6
                     WHEN OTHERS
                     THEN
                        errmsg := 'Excp 6 -- ' || SQLERRM;
                  END;                                        --End of begin 6
               END IF;
            END IF;                                          --soft_pin_gen_if

                        --Caf Refresh for old(closed) pan
            -- as bank's request open cards should also be reissued and old open cards should not be closed
            IF errmsg = 'OK' AND v_cap_card_stat != '1'
            THEN
               BEGIN                                                --Begin 7
                  SELECT COUNT (*)
                    INTO dum
                    FROM cms_caf_info
                   WHERE cci_inst_code = instcode
                     AND cci_pan_code = RPAD (pancode, 19, ' ')
                     AND cci_mbr_numb = v_mbrnumb;

                  IF dum = 1
                  THEN
                     --that means there is a row in cafinfo for that pan but file is not generated
                     DELETE FROM cms_caf_info
                           WHERE cci_inst_code = instcode
                             AND cci_pan_code = RPAD (pancode, 19, ' ')
                             AND cci_mbr_numb = v_mbrnumb;
                  END IF;

                  --call the procedure to insert into cafinfo
                  sp_caf_rfrsh (instcode,
                                pancode,
                                NULL,
                                SYSDATE,
                                'C',
                                remark,
                                'REISSUE',
                                lupduser,
                                errmsg
                               );

                  IF errmsg != 'OK'
                  THEN
                     errmsg := 'From caf refresh for old pan -- ' || errmsg;
                  END IF;
               EXCEPTION                                              --Excp 7
                  WHEN OTHERS
                  THEN
                     errmsg := 'Excp 7 -- ' || SQLERRM;
               END;                                           --End of begin 7
            END IF;
         EXCEPTION                                           --excp of begin 2
            WHEN OTHERS
            THEN
               errmsg := 'Excp 2 -- ' || SQLERRM;
         END;                                                   --begin 2 ends
      END IF;

      IF errmsg = 'OK'
      THEN
         BEGIN                                               --Begin 3 starts
            --the status of the hotlisted card is updated to reissue once it is reissued. The insert statement is commented so that only one row of
            --hotlisted and reissued pan is maintained in pan support table*/
            INSERT INTO cms_pan_spprt
                        (cps_inst_code, cps_pan_code, cps_mbr_numb,
                         cps_prod_catg, cps_spprt_key, cps_func_remark,
                         cps_spprt_rsncode, cps_ins_user, cps_lupd_user,
                         cps_cmd_mode
                        )
                 VALUES (instcode, pancode, v_mbrnumb,
                         v_cap_prod_catg, 'REISSUE', remark,
                         rsncode, lupduser, lupduser,
                         0
                        );
         EXCEPTION                                           --excp of begin 3
            WHEN OTHERS
            THEN
               errmsg := 'Excp 3 -- ' || pancode || SQLERRM;
         END;                                                   --begin 3 ends
      END IF;

      --now enter the old pan and the new pan in the GROUP_REISSUECOMBI table
      IF errmsg = 'OK'
      THEN
         BEGIN                                               --begin 4 starts
            INSERT INTO cms_htlst_reisu
                        (chr_inst_code, chr_pan_code, chr_mbr_numb,
                         chr_new_pan, chr_new_mbr, chr_reisu_cause,
                         chr_ins_user, chr_lupd_user
                        )
                 VALUES (instcode, pancode, v_mbrnumb,
                         newpan, '000', 'H',
                         --hardcoded temporarily...to be removed once reissue after expiry is decided
                         lupduser, lupduser
                        );
         --hardcoded temporarily...to be removed once reissue after expiry is decided
         EXCEPTION                                           --excp of begin 4
            WHEN OTHERS
            THEN
               errmsg :=
                     'Excp 4 -- Given Pan '
                  || pancode
                  || '  is already reissued once '
                  || SQLERRM;
         END;                                                   --begin 4 ends
      END IF;
   END IF;                                                         --cafgen if
EXCEPTION                                                 --Excp of main begin
   WHEN OTHERS
   THEN
      errmsg := 'Main Exception -- ' || SQLERRM;
END;                                                         --Main begin ends
/


