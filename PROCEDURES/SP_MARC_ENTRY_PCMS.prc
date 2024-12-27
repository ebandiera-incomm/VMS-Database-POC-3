CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Marc_Entry_Pcms (
   prm_instcode   IN       NUMBER,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
) IS
/**************************************************
     * Created Date     : 11/Feb/2009.
     * Created By       : Kaustubh.
     * PURPOSE          : Application Processing .
     * LAST MODIFICATION DONE BY :
     * LAST MODIFICATION DATE    :
 **************************************************/
--   v_cust_id          MCCODE.MCCODE%TYPE;--  v_merchent_code      MCCODE.MCCODE%TYPE;
   v_gcm_cntry_code     GEN_CNTRY_MAST.gcm_cntry_code%TYPE;
   v_comm_addrcode      CMS_ADDR_MAST.cam_addr_code%TYPE;
   v_other_addrcode     CMS_ADDR_MAST.cam_addr_code%TYPE;
   v_switch_acct_type   CMS_ACCT_TYPE.cat_switch_type%TYPE       DEFAULT '11';
   v_switch_acct_stat   CMS_ACCT_STAT.cas_switch_statcode%TYPE   DEFAULT '3';
   v_acct_type          CMS_ACCT_TYPE.cat_type_code%TYPE;
   v_acct_stat          CMS_ACCT_MAST.cam_stat_code%TYPE;
   v_acct_numb          CMS_ACCT_MAST.cam_acct_no%TYPE;
   v_acct_id            CMS_ACCT_MAST.cam_acct_id%TYPE;
   v_dup_flag           VARCHAR2 (1);
   v_prod_code          CMS_PROD_MAST.cpm_prod_code%TYPE;
   v_prod_cattype       CMS_PROD_CATTYPE.cpc_card_type%TYPE;
   v_inst_bin           CMS_PROD_BIN.cpb_inst_bin%TYPE;
   v_prod_ccc           CMS_PROD_CCC.cpc_prod_sname%TYPE;
   v_custcatg           CMS_PROD_CCC.cpc_cust_catg%TYPE;
   v_appl_code          CMS_APPL_MAST.cam_appl_code%TYPE;
   --v_errmsg             VARCHAR2 (300);
   v_savepoint          NUMBER                                   DEFAULT 1;
   v_gender             VARCHAR2 (1);
   v_expryparam         CMS_INST_PARAM.cip_param_value%TYPE;
   v_holdposn           CMS_CUST_ACCT.cca_hold_posn%TYPE;
   v_brancheck          NUMBER (1);
   exp_reject_record    EXCEPTION;

   CURSOR c (prm_inst_code IN NUMBER) IS
      SELECT pmi_inst_code, pmi_file_name, pmi_row_id, pmi_appl_code,
             pmi_appl_no, pmi_pan_code, pmi_mbr_numb, pmi_crd_stat,
             pmi_exp_dat, pmi_rec_typ, pmi_crd_typ, pmi_requester_name,
             pmi_prod_code, pmi_card_type, pmi_seg12_branch_num, pmi_fiid,
             pmi_title, pmi_seg12_name_line1,               --Properiter name
                                             pmi_seg12_name_line2,
             pmi_birth_date, pmi_mother_name, pmi_hobbies, pmi_cust_id,
                                                              --Merchent code
             pmi_comm_type, pmi_seg12_addr_line1, pmi_seg12_addr_line2,
             pmi_seg12_city, pmi_seg12_state, pmi_seg12_postal_code,
             pmi_seg12_country_code, pmi_seg12_mobileno,
             pmi_seg12_homephone_no, pmi_seg12_officephone_no,
             pmi_seg12_emailid, pmi_prod_amt, pmi_fee_amt, pmi_tot_amt,
             pmi_payment_mode, pmi_instrument_no, pmi_instrument_amt,
             pmi_drawn_date, pmi_payref_no, pmi_emp_id, pmi_kyc_reason,
             pmi_kyc_flag, pmi_addon_flag, pmi_virtual_acct,
             pmi_document_verify, pmi_exchange_rate, pmi_upld_stat,
             pmi_approved, pmi_maker_user_id, pmi_maker_date,
             pmi_checker_user_id, pmi_cheker_date, pmi_auth_user_id,
             pmi_auth_date, pmi_ins_user, pmi_ins_date, pmi_lupd_user,
             pmi_lupd_date, pmi_comments, pmi_marc_catg_code, pmi_marc_desc,
             pmi_activation_status, pmi_marc_prod_type, pmi_marc_code, ROWID r
        FROM PCMS_MARC_INFO_ENTRY
       WHERE pmi_approved = 'A'
         AND pmi_inst_code = prm_inst_code
         AND pmi_upld_stat = 'P';
BEGIN
   prm_errmsg := 'OK';                                     --<< MAIN BEGIN >>

   ----------------------------------------------- --SN  Loop for record pending for processing--------------------------------------------------------------------
   FOR i IN c (prm_instcode) LOOP
      DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP----');
----------------------------------------------------------------------Initialize the common loop variable--------------------------------------------------------------------
      prm_errmsg := 'OK';
      SAVEPOINT v_savepoint;

      BEGIN                                               --<< LOOP C BEGIN>>
----------------------------------------------------------------------Sn  Check product , prodtype & cust catg--------------------------------------------------------------------
  --------------------------------------------------------------------  -- Sn find prod--------------------------------------------------------------------
         DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP');

         /* BEGIN
             SELECT cpm_prod_code
               INTO v_prod_code
               FROM CMS_PROD_MAST
              WHERE cpm_inst_code = prm_instcode
                AND cpm_prod_code = i.pmi_prod_code;
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                prm_errmsg :=
                      'Product code'
                   || i.pmi_prod_code
                   || 'is not defined in the master';
                DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 1' || prm_errmsg);
                RAISE exp_reject_record;
             WHEN OTHERS
             THEN
                prm_errmsg :=
                   'Error while selecting product '
                   || SUBSTR (SQLERRM, 1, 200);
                DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 2' || prm_errmsg);
                RAISE exp_reject_record;
          END;*/

         -- En find prod-- Sn check in prod bin
         /*    BEGIN
                SELECT cpb_inst_bin
                  INTO v_inst_bin
                  FROM CMS_PROD_BIN
                 WHERE cpb_inst_code = prm_instcode
                   AND cpb_prod_code = i.pmi_prod_code;
             EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                   prm_errmsg :=
                         'Product code'
                      || i.pmi_prod_code
                      || 'is not attached to BIN'
                      || i.pmi_pan_code;
                   DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 3' || prm_errmsg);
                   RAISE exp_reject_record;
                WHEN OTHERS
                THEN
                   prm_errmsg :=
                         'Error while selecting product and bin dtl '
                      || SUBSTR (SQLERRM, 1, 200);
                   DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 4' || prm_errmsg);
                   RAISE exp_reject_record;
             END;*/

         -- En check in prod bin
               -- Sn find prod cattype
         /*      BEGIN
                  SELECT cpc_card_type
                    INTO v_prod_cattype
                    FROM CMS_PROD_CATTYPE
                   WHERE cpc_inst_code = prm_instcode
                     AND cpc_prod_code = i.pmi_prod_code
                     AND cpc_card_type = i.pmi_card_type;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     prm_errmsg :=
                           'Product code'
                        || i.pmi_prod_code
                        || 'is not attached to cattype'
                        || i.pmi_card_type;
                     DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 5' || prm_errmsg);
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     prm_errmsg :=
                           'Error while selecting product cattype '
                        || SUBSTR (SQLERRM, 1, 200);
                     DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 6' || prm_errmsg);
                     RAISE exp_reject_record;
               END;*/

         -- En find prod cattype
            --Sn find the default cust catg
         /*   BEGIN
               SELECT ccc_catg_code
                 INTO v_custcatg
                 FROM CMS_CUST_CATG
                WHERE ccc_inst_code = prm_instcode AND ccc_catg_sname = 'DEF';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  prm_errmsg := 'Catg code is not defined ' || 'DEF';
                  DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 7' || prm_errmsg);
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while selecting custcatg from master '
                     || SUBSTR (SQLERRM, 1, 200);
                  DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 8' || prm_errmsg);
                  RAISE exp_reject_record;
            END;*/

         --En find the default cust
            -- Sn find entry in prod ccc
         /*   BEGIN
               SELECT cpc_prod_sname
                 INTO v_prod_ccc
                 FROM CMS_PROD_CCC
                WHERE cpc_inst_code = prm_instcode
                  AND cpc_prod_code = i.pmi_prod_code
                  AND cpc_card_type = i.pmi_card_type
                  AND cpc_cust_catg = v_custcatg;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     INSERT INTO CMS_PROD_CCC
                                 (cpc_inst_code, cpc_cust_catg, cpc_card_type,
                                  cpc_prod_code, cpc_ins_user, cpc_ins_date,
                                  cpc_lupd_user, cpc_lupd_date, cpc_vendor,
                                  cpc_stock, cpc_prod_sname
                                 )
                          VALUES (prm_instcode, v_custcatg, i.pmi_card_type,
                                  i.pmi_prod_code, prm_lupduser, SYSDATE,
                                  prm_lupduser, SYSDATE, 'A',
                                  'A', 'Default'
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        prm_errmsg := 'Error while creating a entry in prod_ccc';
                        DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 9' || prm_errmsg);
                        RAISE exp_reject_record;
                  END;
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while selecting prodccc detail from master '
                     || SUBSTR (SQLERRM, 1, 200);
                  DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 10' || prm_errmsg);
                  RAISE exp_reject_record;
            END; */

         -- En find entry in prod ccc
         --En Check Product , prod type & cust catg

         --Sn find Branch
         /*   BEGIN
               SELECT 1
                 INTO v_brancheck
                 FROM CMS_BRAN_MAST
                WHERE cbm_bran_locn = 'IIT CH';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  prm_errmsg := 'Branch code not defined for IIT CH LOCATION';
                  DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 11' || prm_errmsg);
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while selecting branch code for  '
                     || '1181'
                     || '  '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END; */

         ----------------------------------------------------------------------En find Branch--------------------------------------------------------------------
         
        
------------------------- SN : Insert For Merchant Code ------------------------------
        BEGIN
         INSERT INTO CMS_MERC_MAST( CMM_INST_CODE ,
             CMM_MERC_CODE ,
             CMM_MERC_CATG ,
             CMM_MERC_NAME ,
             CMM_MERC_PROD_TYPE ,
             CMM_INS_USER ,
             CMM_LUPD_USER)
           VALUES ( prm_instcode ,
             i.pmi_marc_code, 
             i.pmi_marc_catg_code ,
             UPPER(i.pmi_marc_desc) ,
             i.pmi_marc_prod_type ,
             prm_lupduser ,
             prm_lupduser );
        
        EXCEPTION --excp of main
        WHEN DUP_VAL_ON_INDEX THEN
             prm_errmsg := 'This Merchent Code ' || i.pmi_marc_code || ' is already present  ';
             RAISE exp_reject_record;
         WHEN OTHERS THEN
             prm_errmsg := 'This Merchent Code Addition Falied : ' || SQLERRM;
             RAISE exp_reject_record;
      END; 
      
------------------------- EN : Insert For Merchant Code ------------------------------
        


/*        Commented Since MCCODE belongs to Merchant Category


----------------------------------------------------------------------Sn find Merc Code And Merc Category Code--------------------------------------------------------------------
         BEGIN
            Sp_Create_Merc_Catg_Merc (i.pmi_marc_catg_code,
                                      i.pmi_marc_desc,
                                      i.pmi_activation_status,
                                      i.pmi_cust_id,
                                      prm_errmsg
                                     );
            DBMS_OUTPUT.PUT_LINE ('Merchent code ' || i.pmi_cust_id);

            IF prm_errmsg <> 'OK' THEN
               prm_errmsg := 'Error from create cutomer ' || prm_errmsg;
               DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 12' || prm_errmsg);
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record THEN
               RAISE;
            WHEN OTHERS THEN
               prm_errmsg :=
                   'Error while create customer ' || SUBSTR (SQLERRM, 1, 200);
               DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 13' || prm_errmsg);
               RAISE exp_reject_record;
         END;

-------------------------------------------------------------------- --En create customer--------------------------------------------------------------------

Commented Since MCCODE belongs to Merchant Category                     */



v_gcm_cntry_code := i.pmi_seg12_country_code;

--Commented By Vikrant, Since Country Code is Passed As Parameter tp Procedure
/*  
         ----------------------------------------------------------------------Sn find country--------------------------------------------------------------------
         BEGIN
            SELECT gcm_cntry_code
              INTO v_gcm_cntry_code
              FROM GEN_CNTRY_MAST
             WHERE gcm_curr_code = i.pmi_seg12_country_code;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               prm_errmsg :=
                  'Country code not defined for  '
                  || i.pmi_seg12_country_code;
               DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 14' || prm_errmsg);
               RAISE exp_reject_record;
            WHEN OTHERS THEN
               prm_errmsg :=
                     'Error while selecting country code for '
                  || i.pmi_seg12_country_code
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

 ----------------------------------------------------------------------En find country--------------------------------------------------------------------
 */
 
----------------------------------------------------------------------Sn create communication address--------------------------------------------------------------------
         IF i.pmi_seg12_addr_line1 IS NOT NULL THEN
            BEGIN
               DBMS_OUTPUT.PUT_LINE ('Merchent code ' || i.pmi_cust_id);
               Sp_Create_Mercaddr (prm_instcode,
                                   i.pmi_marc_code,
                                   i.pmi_seg12_name_line1,
                                   i.pmi_seg12_addr_line1,
                                   i.pmi_seg12_addr_line2,
                                   i.pmi_seg12_name_line2,
                                   i.pmi_seg12_postal_code,
                                   i.pmi_seg12_homephone_no,
                                   i.pmi_seg12_officephone_no,
                                   i.pmi_seg12_emailid,
                                   v_gcm_cntry_code,
                                   i.pmi_seg12_city,
                                   i.pmi_seg12_state,
                                   NULL,
                                   'P',
                                   prm_lupduser,
                                   i.pmi_seg12_mobileno,
                                   v_comm_addrcode,
                                   prm_errmsg
                                  );
               DBMS_OUTPUT.PUT_LINE ('v_comm_addrcode' || v_comm_addrcode);

               IF prm_errmsg <> 'OK' THEN
                  prm_errmsg :=
                     'Error from create communication address ' || prm_errmsg;
                  DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 14' || prm_errmsg);
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record THEN
                  RAISE;
               WHEN OTHERS THEN
                  prm_errmsg :=
                        'Error while create communication address '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;

----------------------------------------------------------------------En create communication address--------------------------------------------------------------------

         ---------------------------------------------------------------------- Sn create account--------------------------------------------------------------------
   ----------------------------------------------------------------------Sn select acct type--------------------------------------------------------------------
         BEGIN
            SELECT cat_type_code
              INTO v_acct_type
              FROM CMS_ACCT_TYPE
             WHERE cat_inst_code = prm_instcode
               AND cat_switch_type = v_switch_acct_type;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               prm_errmsg :=
                          'Acct type not defined for  ' || v_switch_acct_type;
               DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 15' || prm_errmsg);
               RAISE exp_reject_record;
            WHEN OTHERS THEN
               prm_errmsg :=
                     'Error while selecting accttype '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

 ---------------------------------------------------------------------En select acct type--------------------------------------------------------------------
-------------------------------------------------------------------- --Sn select acct stat--------------------------------------------------------------------
         BEGIN
            SELECT cas_stat_code
              INTO v_acct_stat
              FROM CMS_ACCT_STAT
             WHERE cas_inst_code = prm_instcode
               AND cas_switch_statcode = v_switch_acct_stat;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               prm_errmsg :=
                          'Acct stat not defined for  ' || v_switch_acct_type;
               DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 16' || prm_errmsg);
               RAISE exp_reject_record;
            WHEN OTHERS THEN
               prm_errmsg :=
                     'Error while selecting accttype '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

----------------------------------------------------------------------En select acct stat--------------------------------------------------------------------
----------------------------------------------------------------------Sn get acct number--------------------------------------------------------------------
         BEGIN
            SELECT seq_acct_id.NEXTVAL
              INTO v_acct_numb
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS THEN
               prm_errmsg :=
                  'Error while selecting acctnum '
                  || SUBSTR (SQLERRM, 1, 200);
               DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 17' || prm_errmsg);
               RAISE exp_reject_record;
         END;

----------------------------------------------------------------------En get acct number--------------------------------------------------------------------
----------------------------------------------------------------------Sn create acct--------------------------------------------------------------------
         BEGIN
            Sp_Create_Acct_Pcms (prm_instcode,
                                 v_acct_numb,
                                 0,
                                 i.pmi_fiid,
                                 v_comm_addrcode,
                                 v_acct_type,
                                 v_acct_stat,
                                 prm_lupduser,
                                 v_dup_flag,
                                 v_acct_id,
                                 prm_errmsg
                                );

            IF prm_errmsg <> 'OK' THEN
               prm_errmsg := 'Error from create acct ' || prm_errmsg;
               DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 18' || prm_errmsg);
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record THEN
               RAISE;
            WHEN OTHERS THEN
               prm_errmsg :=
                       'Error while create acct ' || SUBSTR (SQLERRM, 1, 200);
               DBMS_OUTPUT.PUT_LINE ('IN SIDE LOOP 18' || prm_errmsg);
               RAISE exp_reject_record;
         END;

   ----------------------------------------------------------------------En create acct--------------------------------------------------------------------
----------------------------------------------------------------------Sn Add record in Marc Acct--------------------------------------------------------------------
         BEGIN
            INSERT INTO pcms_marc_acct
                        (pma_inst_code, pma_acct_no, pma_mccode,
                         pma_ins_user, pma_lupd_user
                        )
                 VALUES (prm_instcode, v_acct_id, i.pmi_marc_code,
                         prm_lupduser, prm_lupduser
                        );
         EXCEPTION
            WHEN OTHERS THEN
               prm_errmsg :=
                     'Error while  inserting record in Marc Acct   '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

----------------------------------------------------------------------En Add record in Marc Acct--------------------------------------------------------------------

         -------------------------------------------------------------------- --Sn mark the record as successful--------------------------------------------------------------------
         UPDATE PCMS_MARC_INFO_ENTRY
            SET pmi_approved = 'O',
                pmi_upld_stat = 'O',
                pmi_process_msg = 'Successful'
          WHERE ROWID = i.r;

----------------------------------------------------------------------En mark the record as successful--------------------------------------------------------------------
         v_savepoint := v_savepoint + 1;
      EXCEPTION                                       --<< LOOP C EXCEPTION >>
         WHEN exp_reject_record THEN
            ROLLBACK TO v_savepoint;
            DBMS_OUTPUT.PUT_LINE ('INSIDE EXCEPTION');

            UPDATE PCMS_MARC_INFO_ENTRY
               SET pmi_approved = 'E',
                   pmi_upld_stat = 'E',
                   pmi_process_msg = prm_errmsg
             WHERE ROWID = i.r;
         WHEN OTHERS THEN
            ROLLBACK TO v_savepoint;

            UPDATE PCMS_MARC_INFO_ENTRY
               SET pmi_approved = 'E',
                   pmi_upld_stat = 'E',
                   pmi_process_msg = prm_errmsg
             WHERE ROWID = i.r;
      END;                                                   --<< LOOP C END>>
----------------------------------------------------------------------En  Loop for record pending for processing--------------------------------------------------------------------
   END LOOP;
EXCEPTION                                               --<< MAIN EXCEPTION >>
   WHEN OTHERS THEN
      prm_errmsg := 'Exception from Main ' || SUBSTR (SQLERRM, 1, 300);
END;                                                          --<< MAIN END >>
/


