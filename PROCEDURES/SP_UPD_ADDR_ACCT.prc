create or replace
PROCEDURE        VMSCMS.Sp_Upd_Addr_acct
  (
    instcode IN NUMBER,
    ipaddr   IN VARCHAR2,
    lupduser IN NUMBER,
    errmsg OUT VARCHAR2)
IS
    addr1_null_excp          EXCEPTION;
  --Ashwini 13 Jan 05
    v_mbrnumb                CMS_CAF_INFO.cci_mbr_numb%type;
    v_succ_flag              PROCESS_AUDIT_LOG.pal_success_flag%TYPE;
    V_ENCRYPT_ENABLE         cms_prod_cattype.cpc_encrypt_enable%TYPE;
    v_encr_addr_lineone      cms_addr_mast.CAM_ADD_ONE%type;
	v_encr_addr_linetwo      cms_addr_mast.CAM_ADD_TWO%type;
	v_encr_addr_linethree    cms_addr_mast.CAM_ADD_THREE%type;
	v_encr_city              cms_addr_mast.CAM_CITY_NAME%type;      
	v_encr_zip               cms_addr_mast.CAM_PIN_CODE%type;
	V_ENCR_PHONE_NO          CMS_ADDR_MAST.CAM_PHONE_ONE%TYPE;    
	v_encr_mob_one           cms_addr_mast.CAM_MOBL_ONE%type;
	v_encr_email             cms_addr_mast.CAM_EMAIL%type;
	v_encr_first_name        CMS_CUST_MAST.CCM_FIRST_NAME%TYPE;
	
    /************************************************* 
  ---shyam 05 04 05
  --   CAU_MANDATE_FLAG --> this flag will indicate mandate or otherwise : 01 --> Mandate card 99--> Non-mandate card
  -- Note : bin for mandate card is 940112 at the moment...
  -- *** There will be one more column added to the cms_addr_update table to indicate if the update is
  -- *** for normal or mandate card -- jimmy 10th June 2005  -- CR 116
  
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 09-JUL-2019
     * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
     * Reviewer         : Saravana Kumar.A
     * Release Number   : VMSGPRHOST_R18
       
   *************************************************/ 
  
  CURSOR C1
  IS
    SELECT TRIM(CAU_ACCT_NO) CAU_ACCT_NO,
      CAU_DISP_NAME,
      CAU_ADDR1,
      CAU_ADDR2,
      CAU_CITY_NAME,
      CAU_STATE_SWITCH,
      CAU_PIN_CODE,
      CAU_CNTRY_CODE,
      CAU_PHONE_ONE,
      CAU_PHONE_TWO ,
      CAU_MANDATE_FLAG,
      CAU_EMAIL,
      to_date(cau_dob,'ddmmrrrr') cau_dob,
      CAU_CUST_SEG --CR 261 - Jaywant D - 14 MAR 2010
      ,
      ROWID -- CR 116
    FROM CMS_ADDR_UPDATE
    WHERE CAU_DONE_FLAG = 'N';
  --Commented by christopher on 13Mar04  bcoz the address update is now card  based
 
  -- Picking up the card details that has the given acct as Primary  acct
  CURSOR C3(C1_ACCTNO IN VARCHAR2)
                      IS
    --this cursor is taken because the query is returning multiple in case of joint accounts
    SELECT cap_cust_code ,
      cap_disp_name ,
      cap_bill_addr,
      cap_pan_code, -- shyam added pan_code 05 04 05
      cap_pan_code_encr,
	  cap_prod_code,
	  cap_card_type
    FROM CMS_APPL_PAN
    WHERE cap_inst_code = instcode
    AND cap_acct_no     = C1_ACCTNO
    AND cap_Card_Stat  <> 'Z'          -- 04 Aprl 06 logically deleted cards should not come up for address update
    AND cap_acct_no NOT LIKE '%SMILE%' -- CR 170 instant cards should not come for support functions
    AND cap_disp_name NOT LIKE '%INSTANT%';
  
  B24ADDR1              CMS_ADDR_UPDATE.CAU_ADDR1%TYPE; 
  B24ADDR2              CMS_ADDR_UPDATE.CAU_ADDR1%TYPE; 
  B24ADDR3              CMS_ADDR_UPDATE.CAU_ADDR1%TYPE; 
   
  v_errmsg               TRANSACTIONLOG.ERROR_MSG%TYPE;
  
  v_bill_addr            CMS_ACCT_MAST.CAM_BILL_ADDR%TYPE;
  DUM                    PLS_INTEGER;
  v_record_exist         CHAR (1) := 'Y';
  v_caffilegen_flag      CMS_CAF_INFO.cci_file_gen%type  := 'N';
  v_issuestatus          CMS_CAF_INFO.cci_seg12_issue_stat%type;   
  v_pinmailer            CMS_CAF_INFO.cci_seg12_pin_mailer%type;   
  v_cardcarrier          CMS_CAF_INFO.cci_seg12_card_carrier%type;  
  v_pinoffset            CMS_CAF_INFO.cci_pin_ofst%type; 
  v_rec_type             CMS_CAF_INFO.cci_rec_typ%type;         
  -- CR 201
   
   
  v_tran_code			 CMS_FUNC_MAST.cfm_txn_code%type;
  v_tran_mode			 CMS_FUNC_MAST.cfm_txn_mode%type;
  v_tran_type			 CMS_FUNC_MAST.cfm_txn_type%type;  
  v_delv_chnl			 CMS_FUNC_MAST.cfm_delivery_channel%type;  
   
     
  -- CR 201
  /**  Adding the following variables for CR 116 - mandate flag addr update check **/
  v_raise_addr_excp         EXCEPTION ;
  mandateAddrUpdException   EXCEPTION;
  v_mandate_flag            CMS_ADDR_UPDATE.CAU_MANDATE_FLAG%TYPE;
  v_bin                     VARCHAR2(6);
  /**    **/
  --local procedure to create countries
PROCEDURE lp_create_countries
IS
   
  CURSOR c1
  IS
    SELECT cau_cntry_code ,
      rowid
    FROM CMS_ADDR_UPDATE
    WHERE cau_cntry_code NOT IN
      (SELECT gcm_curr_code FROM GEN_CURR_MAST
      );
BEGIN
  FOR x IN c1
  LOOP
    UPDATE CMS_ADDR_UPDATE
    SET cau_done_flag    = 'E',
      cau_process_result = 'Country code not  found in master'
    WHERE ROWID          = x.ROWID ;
 
  END LOOP;
END;
--local procedure to create countries ends
BEGIN
  errmsg := 'OK';
  
  --CARD DETAILS	   
  
  --this will create countries which are not present in the masters
  BEGIN
          SELECT cfm_txn_code,
            cfm_txn_mode,
            cfm_delivery_channel,
            CFM_TXN_TYPE
          INTO v_tran_code,
            v_tran_mode,
            v_delv_chnl,
            v_tran_type
          FROM CMS_FUNC_MAST
          WHERE cfm_inst_code = instcode
          AND cfm_func_code   = 'ADDR';
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          errmsg := 'Support function reissue not defined in master ' ;
          RETURN;
        WHEN TOO_MANY_ROWS THEN
          errmsg := 'More than one record found in master for reissue support func ' ;
          RETURN;
        WHEN OTHERS THEN
          errmsg := 'Error while selecting reissue fun detail ' || SUBSTR (SQLERRM, 1, 200);
          RETURN;
        END;
		
 ------En to get transaction code,delivery channel-----------------
   lp_create_countries;
  FOR X IN C1
  LOOP --c1 loop
    v_errmsg := 'OK';
    v_succ_flag:='S';
    IF x.cau_Acct_no LIKE '%SMILE%' THEN -- instant card check
      BEGIN
        v_succ_flag:='E';
        UPDATE CMS_ADDR_UPDATE
        SET cau_done_flag    = 'E',
          cau_process_result = 'Cannot process Instant Card Account'
        WHERE ROWID          = x.ROWID ;
      END;
    ELSE -- intant card check
      BEGIN
        /* Put a check on the mandate flag -- jimmy 12th July 2005 CR 116  */
        v_mandate_flag := x.CAU_MANDATE_FLAG;
        --Change done By Christopher to update adress of secondary Accounts ...Change Starts
        --BEGIN  -- Secondary Accts .
        SELECT COUNT(1)
        INTO DUM
        FROM CMS_APPL_PAN
        WHERE cap_inst_code = instcode
        AND cap_acct_no     = x.cau_acct_no ;
        
        
        
        IF dum              > 0 THEN -- Secondary Accts if...>0 means the givn acct is primary .
          --Change done By Christopher to update adress of secondary Accounts ...Change Ends .
          BEGIN --C1 BEGIN
            FOR Y IN C3(X.CAU_ACCT_NO)
            LOOP    --C3 LOOP
              BEGIN -- /**** mandate begin...
                v_errmsg := 'OK';
                v_succ_flag:='S';
                /** Changes for CR 116 -- jimmy 14th July 2005  **/
                /* New variable to store the bin for mandate card   */
                v_bin := SUBSTR(Y.CAP_PAN_CODE, 1, 6);
                /* '01' will indicate address update for mandate card only */
                IF v_mandate_flag = '01' AND v_bin <> '940112' THEN
                  RAISE mandateAddrUpdException;
                END IF;
                /*  '99' will indicate address update for cards other than mandate cards */
                IF v_mandate_flag = '99' AND v_bin = '940112' THEN
                  RAISE mandateAddrUpdException;
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
					
					  BEGIN
						SELECT  cpc_encrypt_enable
						INTO   v_encrypt_enable
						FROM   cms_prod_cattype 
						WHERE  cpc_inst_code = instcode
						AND    cpc_prod_code = y.cap_prod_code
						AND    cpc_card_type = y.cap_card_type;
						
					  EXCEPTION
						 WHEN NO_DATA_FOUND THEN
						   errmsg := 'No data found while selecting encrypt anble flag from cms_prod_cattype ' ;
						   RETURN;
						 WHEN OTHERS THEN
						   errmsg := 'Error while selecting cms_prod_cattype ' || SUBSTR (SQLERRM, 1, 200);
						   RETURN;
					  END;
					
					IF V_ENCRYPT_ENABLE = 'Y' THEN
						v_encr_addr_lineone   := fn_emaps_main(B24ADDR1);
						v_encr_addr_linetwo   := fn_emaps_main(B24ADDR2);
						v_encr_addr_linethree := fn_emaps_main(B24ADDR3);
						v_encr_city           := fn_emaps_main(X.CAU_CITY_NAME);
						v_encr_zip            := fn_emaps_main(X.CAU_PIN_CODE);
						v_encr_phone_no       := fn_emaps_main(X.CAU_PHONE_ONE);
						v_encr_mob_one        := fn_emaps_main(X.CAU_PHONE_TWO);
						v_encr_email          := fn_emaps_main(X.CAU_EMAIL);
				
				   ELSE
						v_encr_addr_lineone   := B24ADDR1;
						v_encr_addr_linetwo   := B24ADDR2;
						v_encr_addr_linethree := B24ADDR3;
						v_encr_city           := X.CAU_CITY_NAME;
						v_encr_zip            := X.CAU_PIN_CODE;
						v_encr_phone_no       := X.CAU_PHONE_ONE;
						v_encr_mob_one        := X.CAU_PHONE_TWO;
						v_encr_email          := X.CAU_EMAIL; 
					
				   END IF;
					
                    UPDATE CMS_ADDR_MAST
                       SET CAM_ADD_ONE  = v_encr_addr_lineone ,
                           CAM_ADD_TWO    = v_encr_addr_linetwo ,
                           CAM_ADD_THREE  = v_encr_addr_linethree ,
                           CAM_PIN_CODE   = v_encr_zip ,
                           CAM_PHONE_ONE  = v_encr_phone_no ,
                           CAM_PHONE_TWO  = v_encr_mob_one ,
                           CAM_CITY_NAME  = NVL(v_encr_city,' ') ,
                           CAM_EMAIL      =v_encr_email,
                           CAM_CNTRY_CODE = (SELECT GCM_CNTRY_CODE
                                                FROM GEN_CNTRY_MAST
                                                WHERE GCM_CURR_CODE = X.CAU_CNTRY_CODE
                                                AND GCM_INST_CODE   = instcode),
                           CAM_STATE_SWITCH  = X.CAU_STATE_SWITCH,
                           CAM_ADD_ONE_ENCR = fn_emaps_main(B24ADDR1),
                           CAM_ADD_TWO_ENCR = fn_emaps_main(B24ADDR2),
                           CAM_CITY_NAME_ENCR = fn_emaps_main(X.CAU_CITY_NAME),
                           CAM_PIN_CODE_ENCR = fn_emaps_main(X.CAU_PIN_CODE),
                           CAM_EMAIL_ENCR = fn_emaps_main(X.CAU_EMAIL)                           
                     WHERE cam_inst_code = instcode
                       AND CAM_ADDR_CODE   = Y.CAP_BILL_ADDR;
                       
                  EXCEPTION
                  WHEN addr1_null_excp THEN --Ashwini 13 Jan 05
                    v_succ_flag:='E';
                    v_errmsg := 'Error while Updating - ADDRESS ONE IS NULL' ;
                    UPDATE CMS_ADDR_UPDATE
                    SET cau_done_flag    = 'E',
                      cau_process_result = v_errmsg --errmsg
                    WHERE ROWID          = x.ROWID ;
                    -- End
                  WHEN OTHERS THEN
                    v_succ_flag:='E';
                    v_errmsg := 'Error while Updating '||SQLERRM ;
                    UPDATE CMS_ADDR_UPDATE
                    SET cau_done_flag    = 'E',
                      cau_process_result = v_errmsg --errmsg
                    WHERE ROWID          = x.ROWID ;
                  END ;
                ELSE
                  v_errmsg := 'From sp_split_addr -- '||errmsg;
                  --added on 31jul04 by christopher to catch the error .
                  v_succ_flag:='E';
                  UPDATE CMS_ADDR_UPDATE
                  SET cau_done_flag    = 'E',
                    cau_process_result = errmsg
                  WHERE ROWID          = x.ROWID ;
                END IF;
             
                IF v_errmsg = 'OK' AND (SUBSTR(y.cap_disp_name, 8, 13) = 'VISA ELECTRON' OR SUBSTR(y.cap_disp_name, 8, 10) = 'MASTERCARD') THEN
                    BEGIN
                      BEGIN
                     
                        UPDATE CMS_APPL_PAN
                        SET cap_disp_name    = x.cau_disp_name,
                          cap_active_date    = SYSDATE, -- shyamjith 05 aprl 05
                          cap_next_bill_date = SYSDATE  -- shyamjith 05 aprl 05
                        WHERE cap_inst_code  = instcode
                        AND cap_acct_no      = x.cau_acct_no
                        AND cap_cust_code    = y.cap_cust_code ;
                        
                      EXCEPTION
                      WHEN OTHERS THEN
                        IF SQLCODE  = '-1407' THEN
                          v_errmsg := 'NAME COMING AS NULL FOR A CUSTOMER WHOSE NAME IS  VISA ELECTRON' ;
                        ELSE
                          v_errmsg := SQLERRM ;
                        END IF ;
                        v_succ_flag:='E';
                        ROLLBACK TO NAME_POINT ;
                        UPDATE CMS_ADDR_UPDATE
                        SET cau_done_flag    = 'E',
                          cau_process_result = v_errmsg
                        WHERE ROWID          = x.ROWID ;
                        
                        RAISE v_raise_addr_excp ;
                      END ;
					  
					  IF V_ENCRYPT_ENABLE = 'Y' THEN
						V_ENCR_FIRST_NAME := fn_emaps_main(X.cau_disp_name);
					  ELSE
						V_ENCR_FIRST_NAME := X.cau_disp_name;
					  END IF;
					  
                      BEGIN
                        UPDATE CMS_CUST_MAST
                           SET ccm_first_name  = v_encr_first_name,
                               ccm_birth_date    = x.cau_dob,
                               CCM_FIRST_NAME_ENCR = fn_emaps_main(X.cau_disp_name)
                         WHERE ccm_inst_code = instcode
                           AND ccm_cust_code   = y.cap_cust_code;
                           
                      EXCEPTION
                      WHEN OTHERS THEN
                        IF SQLCODE  = '-1407' THEN
                          v_errmsg := 'NAME COMING AS NULL FOR A CUSTOMER WHOSE NAME IS  VISA ELECTRON' ;
                        ELSE
                          v_errmsg := SQLERRM ;
                        END IF ;
                        v_succ_flag:='E';
                        ROLLBACK TO NAME_POINT ;
                        UPDATE CMS_ADDR_UPDATE
                        SET cau_done_flag    = 'E',
                          cau_process_result = v_errmsg
                        WHERE ROWID          = x.ROWID ;
                        
                        RAISE v_raise_addr_excp ;
                      END;
                    EXCEPTION
                    WHEN v_raise_addr_excp THEN
                       
                      NULL ;
                    END ;
                 
                END IF;
                -- ****************** CR 261 - 17MAY2010 - Jaywant D **************
                IF errmsg = 'OK' THEN
                  BEGIN
                    UPDATE CMS_CUST_MAST
                       SET CCM_CUST_PARAM3 = x.cau_cust_seg,
                           ccm_birth_date    =x.cau_dob
                     WHERE ccm_inst_code = instcode
                       AND ccm_cust_code   = y.cap_cust_code;
                  EXCEPTION
                  WHEN OTHERS THEN
                    v_errmsg := SQLERRM ;
                    v_succ_flag:='E';
                    ROLLBACK TO NAME_POINT ;
                    UPDATE CMS_ADDR_UPDATE
                    SET cau_done_flag    = 'E',
                      cau_process_result = v_errmsg
                    WHERE ROWID          = x.ROWID ;
                    
                    RAISE v_raise_addr_excp;
                  END;
                END IF;
                -- ****************** CR 261 - 17MAY2010 - Jaywant D **************
                -- changes for Address update procedure
                BEGIN --Begin 4
                  v_mbrnumb:='000';
        
                  --Sn get caf detail
                  BEGIN
                    SELECT cci_rec_typ,
                      cci_file_gen,
                      cci_seg12_issue_stat,
                      cci_seg12_pin_mailer,
                      cci_seg12_card_carrier,
                      cci_pin_ofst
                    INTO v_rec_type,
                      v_caffilegen_flag,
                      v_issuestatus,
                      v_pinmailer,
                      v_cardcarrier,
                      v_pinoffset
                    FROM CMS_CAF_INFO
                    WHERE cci_inst_code = instcode
                    AND cci_pan_code    = DECODE(LENGTH(y.cap_pan_code), 16,y.cap_pan_code
                      || '   ', 19,y.cap_pan_code)--RPAD (y.cap_pan_code, 19, ' ')
                    AND cci_mbr_numb = v_mbrnumb
                    AND cci_file_gen = 'N' -- Only when a CAF is not generated
                    GROUP BY cci_rec_typ,
                      cci_file_gen,
                      cci_seg12_issue_stat,
                      cci_seg12_pin_mailer,
                      cci_seg12_card_carrier,
                      cci_pin_ofst;
                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    v_record_exist := 'N';
                  WHEN OTHERS THEN
                    errmsg := 'Error while selecting caf details '|| SUBSTR (SQLERRM, 1, 300);
                    RETURN;
                  END;
                  --En get caf detail
                  --Sn delete record from CAF
                  DELETE
                  FROM CMS_CAF_INFO
                  WHERE cci_inst_code = instcode
                  AND cci_pan_code    = DECODE(LENGTH(y.cap_pan_code), 16,y.cap_pan_code
                    || '   ', 19,y.cap_pan_code)--RPAD (y.cap_pan_code, 19, ' ')
                  AND cci_mbr_numb = v_mbrnumb;
                  --En delete record from CAF
                  
                  --call the procedure to insert into cafinfo
                  Sp_Caf_Rfrsh(instcode,Fn_Dmaps_main(y.cap_pan_code_encr),'000',SYSDATE,'C','ADDRESS UPDATE','ADDRUPD',lupduser,Fn_Dmaps_main(y.cap_pan_code_encr),errmsg) ;
                  --CR201
                  IF v_rec_type = 'A'  THEN
                      v_issuestatus := '00';                -- no pinmailer no embossa.
                      v_pinoffset := RPAD ('Z', 16, 'Z');        -- keep original pin .
                  END IF;
                  --Sn update caf info
                   IF v_record_exist = 'Y' THEN
                   BEGIN
                      UPDATE CMS_CAF_INFO
                      SET	 cci_seg12_issue_stat = v_issuestatus,
                       cci_seg12_pin_mailer = v_pinmailer,
                       cci_seg12_card_carrier = v_cardcarrier,
                       cci_pin_ofst = v_pinoffset                  -- rahul 10 Mar 05
                      WHERE  cci_inst_code = instcode
                      AND    cci_pan_code = DECODE(LENGTH(y.cap_pan_code), 16,y.cap_pan_code || '   ',
                                19,y.cap_pan_code)--RPAD (y.cap_pan_code, 19, ' ')
                      AND cci_mbr_numb    = v_mbrnumb;
                   EXCEPTION
                   WHEN OTHERS THEN
                    errmsg := 'Error updating CAF record ' || substr(sqlerrm,1,200);
                    RETURN;
                   END;
                   END IF;
                  --En update caf info
                  
                  
                  --CR201
                  IF errmsg <> 'OK' THEN
                    errmsg  := 'From1 caf refresh -- '||errmsg;
                    v_succ_flag:='E';
                    UPDATE CMS_ADDR_UPDATE
                    SET cau_done_flag    = 'E',
                      cau_process_result = errmsg
                    WHERE ROWID          = x.ROWID ;
                  END IF;
                  
                EXCEPTION --Excp 4
                WHEN OTHERS THEN
                  v_succ_flag:='E';
                  errmsg := 'Excp 4 -- '||SQLERRM;
                  UPDATE CMS_ADDR_UPDATE
                  SET cau_done_flag    = 'E',
                    cau_process_result = errmsg
                  WHERE ROWID          = x.ROWID ;
                END; --End of begin 4
                -- end of changes for address update
                /****  Added for Cr 116 -- jimmy 13th July 2005 ****/
              EXCEPTION
                /****         ****/
              WHEN mandateAddrUpdException THEN
                v_succ_flag:='E';
                v_errmsg:= 'Mandate Card address update filter';
                UPDATE CMS_ADDR_UPDATE
                SET cau_done_flag    = 'F',
                  cau_process_result = v_errmsg
                WHERE ROWID          = x.ROWID ;
              END;
              -- end of mandate begin...
              
                    --siva mar 24 2011
        --start for audit log success
      IF v_errmsg = 'OK'
      THEN
         --insert into Audit table
         BEGIN
            INSERT INTO cms_audit_log_process
                        (cal_inst_code, cal_appl_no, cal_acct_no,
                         cal_pan_no, cal_prod_code, cal_prg_name,
                         cal_action, cal_status, cal_ip_address,
                         cal_ref_tab_name, cal_ref_tab_rowid, cal_pan_encr,
                         cal_ins_user, cal_ins_date
                        )
                 VALUES (instcode, '', x.cau_acct_no,
                         '', '', 'GROUP ADDRESS CHANGE USING ACCOUNT',
                         'INSERT', 'SUCCESS', ipaddr,
                         'CMS_PAN_SPPRT', '', '',
                         lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while inserting records for audit log process'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      --end insert audit table

       --end for audit log success
      -- start for failure record
      ELSE
         --insert into Audit table
         BEGIN
            INSERT INTO cms_audit_log_process
                        (cal_inst_code, cal_appl_no, cal_acct_no,
                         cal_pan_no, cal_prod_code, cal_prg_name,
                         cal_action, cal_status, cal_ip_address,
                         cal_ref_tab_name, cal_ref_tab_rowid, cal_pan_encr,
                         cal_ins_user, cal_ins_date
                        )
                 VALUES (instcode, '', x.cau_acct_no,
                         '', '', 'GROUP ADDRESS CHANGE USING ACCOUNT',
                         'INSERT', 'FAILURE', ipaddr,
                         'CMS_PAN_SPPRT', '', '',
                         lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while inserting records for audit log process'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      --end insert audit table
      END IF;

      --end for failure status record
          --siva end mar 24 2011
          
              --start create audit logs records for primary accounts
                    begin
                      insert into PROCESS_AUDIT_LOG
                                (
                                 pal_inst_code,
                                 pal_card_no, 
                                 pal_activity_type, 
                                 pal_transaction_code,
                                 pal_delv_chnl, 
                                 pal_tran_amt, 
                                 pal_source,
                                 pal_success_flag, 
                                 pal_ins_user, 
                                 pal_ins_date,
                                 pal_process_msg, 
                                 pal_reason_desc, 
                                 pal_remarks,
                                 pal_spprt_type
                                )
                                  values	
                                (instcode,
                                 Y.CAP_PAN_CODE, 
                                 'Address Change',
                                 v_tran_code,
                                 v_delv_chnl,
                                 0,
                                 null,
                                 v_succ_flag, 
                                 lupduser, 
                                 sysdate,
                                 v_errmsg,
                                 'Address Change',
                                 'Address Change',
                                 'G'
                       );
                    exception
                    when others then
                      errmsg := 'Error while creating record in Audit Log table ' || substr(sqlerrm,1,150);                      	
                    end;
           ----End create audit logs records for primary accounts
              
              /**    **/
            END LOOP;
            --C3 LOOP
            --COMMIT;
            UPDATE CMS_ADDR_UPDATE
            SET cau_done_flag    = 'Y',
              cau_process_result = 'Processed '
            WHERE ROWID          = x.ROWID
            AND cau_done_flag    = 'N' ;
          EXCEPTION -- c1 Exception
          WHEN OTHERS THEN
            errmsg := SQLERRM ;
            UPDATE CMS_ADDR_UPDATE
            SET cau_done_flag    = 'E',
              cau_process_result = errmsg
            WHERE ROWID          = x.ROWID ;
          END ;
          -- c1 end
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
			  
			  IF V_ENCRYPT_ENABLE = 'Y' THEN
				v_encr_addr_lineone   := fn_emaps_main(B24ADDR1);
				v_encr_addr_linetwo   := fn_emaps_main(B24ADDR2);
				V_ENCR_ADDR_LINETHREE := FN_EMAPS_MAIN(B24ADDR3);
				V_ENCR_CITY           := FN_EMAPS_MAIN(X.CAU_CITY_NAME);
				V_ENCR_ZIP            := FN_EMAPS_MAIN(X.CAU_PIN_CODE);
				V_ENCR_PHONE_NO       := FN_EMAPS_MAIN(X.CAU_PHONE_ONE);
				V_ENCR_MOB_ONE        := FN_EMAPS_MAIN(X.CAU_PHONE_TWO);
				v_encr_email          := fn_emaps_main(X.CAU_EMAIL);
			  ELSE
				v_encr_addr_lineone   := B24ADDR1;
				v_encr_addr_linetwo   := B24ADDR2;
				V_ENCR_ADDR_LINETHREE := B24ADDR3;
				V_ENCR_CITY           := X.CAU_CITY_NAME;
				V_ENCR_ZIP            := X.CAU_PIN_CODE;
				V_ENCR_PHONE_NO       := X.CAU_PHONE_ONE;
				V_ENCR_MOB_ONE        := X.CAU_PHONE_TWO;
				v_encr_email          := X.CAU_EMAIL; 
			  END IF;
              SELECT CAM_BILL_ADDR
              INTO v_bill_addr
              FROM CMS_ACCT_MAST
              WHERE CAM_INST_CODE = instcode
              AND CAM_ACCT_NO     = x.CAU_ACCT_NO ;
              
              UPDATE CMS_ADDR_MAST
                 SET CAM_ADD_ONE  = v_encr_addr_lineone ,
                     CAM_ADD_TWO    = v_encr_addr_linetwo ,
                     CAM_ADD_THREE  = V_ENCR_ADDR_LINETHREE ,
                     CAM_PIN_CODE   = v_encr_zip ,
                     CAM_PHONE_ONE  = v_encr_phone_no ,
                     CAM_PHONE_TWO  = v_encr_mob_one ,
                     CAM_CITY_NAME  = NVL(V_ENCR_CITY,' ') ,
                     CAM_EMAIL      = v_encr_email,
                     CAM_CNTRY_CODE = (SELECT GCM_CNTRY_CODE
                                            FROM GEN_CNTRY_MAST
                                            WHERE GCM_CURR_CODE = X.CAU_CNTRY_CODE
                                            AND GCM_INST_CODE   = instcode),
                     CAM_STATE_SWITCH  = X.CAU_STATE_SWITCH,
                     CAM_ADD_ONE_ENCR = fn_emaps_main(B24ADDR1),
                     CAM_ADD_TWO_ENCR = fn_emaps_main(B24ADDR2),
                     CAM_CITY_NAME_ENCR = fn_emaps_main(X.CAU_CITY_NAME),
                     CAM_PIN_CODE_ENCR = fn_emaps_main(X.CAU_PIN_CODE),
                     CAM_EMAIL_ENCR = fn_emaps_main(X.CAU_EMAIL)
               WHERE cam_inst_code = instcode
                 AND CAM_ADDR_CODE   = v_bill_addr;
                 
              UPDATE CMS_ADDR_UPDATE
              SET cau_done_flag    = 'Y',
                cau_process_result = 'Processed '
              WHERE ROWID          = x.ROWID
              AND cau_done_flag    = 'N' ;
            EXCEPTION
            WHEN addr1_null_excp THEN --Ashwini 13 Jan 05
              v_errmsg := 'Error while Updating - ADDRESS ONE IS NULL' ;
              v_succ_flag:='E';
              UPDATE CMS_ADDR_UPDATE
              SET cau_done_flag    = 'E',
                cau_process_result = v_errmsg --errmsg
              WHERE ROWID          = x.ROWID ;
              -- End
            WHEN NO_DATA_FOUND THEN
              v_errmsg := 'NO SUCH ACCOUNT :'||x.cau_acct_no ;
              v_succ_flag:='E';
              UPDATE CMS_ADDR_UPDATE
              SET cau_done_flag    = 'E',
                cau_process_result = v_errmsg
              WHERE ROWID          = x.ROWID ;
            WHEN OTHERS THEN
              v_errmsg := 'Err:'||SQLERRM ;
              v_succ_flag:='E';
              UPDATE CMS_ADDR_UPDATE
              SET cau_done_flag    = 'E',
                cau_process_result = v_errmsg
              WHERE ROWID          = x.ROWID ;
            END ;
            -- Secondary Acct -- 2
          ELSE
            v_errmsg := 'From sp_split_addr(Secondary Acct) -- '||errmsg;
            v_succ_flag:='E';
            UPDATE CMS_ADDR_UPDATE
            SET cau_done_flag    = 'E',
              cau_process_result = v_errmsg
            WHERE ROWID          = x.ROWID ;
          END IF ;
        END IF ;
        -- Secondary Accts
        --Change done By Christopher to update adress of secondary Accounts ..Change Ends  .
     EXCEPTION 
     WHEN OTHERS THEN
                     
                    v_errmsg := 'Error while selecting from cms_appl_pan '|| substr(sqlerrm,1,150);
     
      END;
      -- Instant card
    END IF;
    -- instant card
    --start create audit logs records for secondary accounts
                    begin
                      insert into PROCESS_AUDIT_LOG
                                (
                                 pal_inst_code,
                                 pal_card_no, 
                                 pal_activity_type, 
                                 pal_transaction_code,
                                 pal_delv_chnl, 
                                 pal_tran_amt, 
                                 pal_source,
                                 pal_success_flag, 
                                 pal_ins_user, 
                                 pal_ins_date,
                                 pal_process_msg, 
                                 pal_reason_desc, 
                                 pal_remarks,
                                 pal_spprt_type
                                )
                                  values	
                                (instcode,
                                 null, 
                                 'Address Change',
                                 v_tran_code,
                                 v_delv_chnl,
                                 0,
                                 null,
                                 v_succ_flag, 
                                 lupduser, 
                                 sysdate,
                                 v_errmsg,
                                 'Address Change',
                                 'Acct No '|| x.CAU_ACCT_NO||' have no pans.',
                                 'G'
                       );
                    exception
                    when others then
                      errmsg := 'Error while creating record in Audit Log table ' || substr(sqlerrm,1,150);                      	
                    end;
   
  END LOOP ;
  --c1 LOOP
  -- Ashwini 28 Dec 2004  commented for taking successful report
  --DELETE FROM cms_addr_update where cau_done_flag = 'Y' ;
EXCEPTION
WHEN OTHERS THEN
  errmsg := 'Main Excp -- '||SQLERRM;
END;
/
show error