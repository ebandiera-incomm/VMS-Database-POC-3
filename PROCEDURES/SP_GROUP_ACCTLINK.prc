CREATE OR REPLACE PROCEDURE VMSCMS.sp_group_acctlink (
   instcode   IN       VARCHAR2,
   lupduser   IN       VARCHAR2,
   errmsg     OUT      VARCHAR2
)
AS
   v_mbrnumb           VARCHAR2 (3);
   v_remark            cms_pan_spprt.cps_func_remark%TYPE;
   v_spprtrsn          cms_pan_spprt.cps_spprt_rsncode%TYPE;
   v_cap_card_stat     cms_appl_pan.cap_card_stat%TYPE;
   v_cardstat_desc     VARCHAR2 (10);
   v_cap_cafgen_flag   cms_appl_pan.cap_cafgen_flag%TYPE;
   v_cap_appl_bran     cms_appl_pan.cap_appl_bran%TYPE;
   v_cap_bill_addr     cms_appl_pan.cap_bill_addr%TYPE;
   v_cap_acct_id       cms_appl_pan.cap_acct_id%TYPE;
   v_cam_acct_id       cms_acct_mast.cam_acct_id%TYPE;
   v_cca_cust_code     cms_cust_acct.cca_cust_code%TYPE;
   holdposn            NUMBER;
   dum                 NUMBER;
   v_resoncode         VARCHAR2 (10);
   v_savepoint         NUMBER;
   v_succ_flag         VARCHAR2 (1);
   v_reasondesc        cms_spprt_reasons.csr_reasondesc%TYPE;
   v_txn_type          VARCHAR2 (2);
   v_txn_mode          VARCHAR2 (2);
   v_del_channel       VARCHAR2 (2);
   v_txn_code          VARCHAR2 (2);
   V_new_acctposn      VARCHAR2 (2);  --added by sagar on 29-04-2010 for value in "new_account_pos" column
   v_cam_type_code     VARCHAR2 (2); --added by sagar on 29-04-2010 for value in "new_account_typ" column
   exp_reject_record   EXCEPTION;
               

   CURSOR c1
   IS
      SELECT cal_pan_code, cal_acct_no, cal_file_name, cal_mbr_numb,
             cal_remark, ROWID
        FROM cms_group_acctlink_temp
       WHERE cal_pin_link = 'N' AND cal_process_flag = 'N';
BEGIN
   --BEGIN 1.1
   errmsg := 'OK';
   v_remark := 'Group Account Link';

   ------------------------------------Sn create a record in pan spprt ----------------------------------
   SELECT csr_spprt_rsncode, csr_reasondesc
     INTO v_resoncode, v_reasondesc
     FROM cms_spprt_reasons
    WHERE csr_spprt_key = 'LINK' AND ROWNUM < 2;

   -------------------------------En create a record in pan spprt----------------------------------

   ------------------------------ Sn get Function Master----------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM cms_func_mast
       WHERE cfm_func_code = 'LINK';
   EXCEPTION
      WHEN OTHERS
      THEN
         errmsg := 'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         RETURN;
   END;

   ------------------------------ En get Function Master----------------------------
   FOR x IN c1
   LOOP
      BEGIN
         v_savepoint := v_savepoint + 1;
         SAVEPOINT v_savepoint;

         BEGIN                                                    --begin 1.2
            SELECT cap_card_stat, cap_cafgen_flag, cap_appl_bran,
                   cap_bill_addr, cap_acct_id, cap_cust_code
              INTO v_cap_card_stat, v_cap_cafgen_flag, v_cap_appl_bran,
                   v_cap_bill_addr, v_cap_acct_id, v_cca_cust_code
              FROM cms_appl_pan
             WHERE cap_pan_code = x.cal_pan_code
               AND cap_mbr_numb = x.cal_mbr_numb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               errmsg := 'pan code is not found in appl pan';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               errmsg := 'pan code is not found in appl pan' || SQLERRM;
               RAISE exp_reject_record;
         END;

         BEGIN                                                     --BEGIN 1.3
            IF v_cap_card_stat = '1'
            THEN
               IF v_cap_cafgen_flag = 'Y'
               THEN
                  BEGIN
                     SELECT cam_acct_id
                       INTO v_cam_acct_id
                       FROM cms_acct_mast
                      WHERE cam_inst_code = 1 AND cam_acct_no = x.cal_acct_no;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        errmsg := 'No record found on acct mast';
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        errmsg := 'No record found on acct mast' || SQLERRM;
                        RAISE exp_reject_record;
                  END;

                  sp_create_holder (instcode,
                                    v_cca_cust_code,
                                    v_cam_acct_id,
                                    NULL,
                                    1,
                                    holdposn,
                                    errmsg
                                   );

                  IF errmsg = 'OK'
                  THEN
                     sp_link_acct (instcode,
                                   x.cal_pan_code,
                                   x.cal_mbr_numb,
                                   v_cam_acct_id,
                                   v_resoncode,
                                   x.cal_remark,
                                   lupduser,
                                   0,
                                   v_new_acctposn,
                                   errmsg
                                  );

                     IF errmsg = 'OK'
                     THEN
                        v_succ_flag := 'S';
                        errmsg := 'SUCCESSFULLY LINKED';

                        UPDATE cms_group_acctlink_temp
                           SET cal_result = 'SUCCESSFULLY LINKED',
                               cal_process_flag = 'S'
                         WHERE ROWID = x.ROWID;
                         
                         /***start***** added by sagar on 29-apr-2010***************/
                         
                        begin----begin 001 starts here to get value for new acct type  
                         
                                 select cam_type_code into v_cam_type_code from cms_acct_mast
                                 where  cam_inst_code=instcode
                                 and cam_acct_no=x.cal_acct_no;
                         
                         exception when no_data_found then
                         errmsg := 'value for new account type not found for account no='||' '||x.cal_acct_no||' '||'and instcode='||' '||instcode;
                         raise exp_reject_record;
                         
                         end;--begin 001 ends  here 
                                                
                         /***end***** added by sagar on 29-apr-2010***************/

                         
                         /***start***** added insert by sagar on 29-apr-2010***************/
                         
                             
                           INSERT INTO cms_acct_link_detail
                                            (cad_inst_code, cad_card_no, cad_file_name,
                                             cad_remarks, cad_msg24_flag, cad_process_flag,
                                             cad_process_msg, cad_process_mode, cad_new_acct_no,
                                             cad_ins_user, cad_ins_date, cad_lupd_user,
                                             cad_lupd_date,cad_new_acct_type,cad_new_acct_posn
                                            )
                                    VALUES (instcode, x.cal_pan_code, x.cal_file_name,
                                     x.cal_remark, 'N', 'S',
                                     errmsg, 'G', x.cal_acct_no,
                                     lupduser, SYSDATE, lupduser,
                                     SYSDATE,v_cam_type_code,v_new_acctposn
                                    );
                         
                         
                         /***end***** added insert by sagar on 29-apr-2010***************/
                         
                     ELSE
                        errmsg := 'From  SP_LINK_ACCT' || errmsg;
                        RAISE exp_reject_record;
                     END IF;
                  ELSE
                     errmsg := 'From  SP_CREATE_HOLDER' || errmsg;
                     RAISE exp_reject_record;
                  END IF;
               ELSE
                  errmsg :=
                        'CAF has to Generated atleast once for this pan'
                     || x.cal_pan_code;
                  RAISE exp_reject_record;
               END IF;
            ELSE
               errmsg := 'Card Not Available as 1 (Open)';
               RAISE exp_reject_record;
            END IF;
         END;                                                        --END 1.3
      EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK TO v_savepoint;
            v_succ_flag := 'E';

            UPDATE cms_group_acctlink_temp
               SET cal_result = errmsg,
                   cal_process_flag = 'E'
             WHERE ROWID = x.ROWID;

            INSERT INTO cms_acct_link_detail
                        (cad_inst_code, cad_card_no, cad_file_name,
                         cad_remarks, cad_msg24_flag, cad_process_flag,
                         cad_process_msg, cad_process_mode, cad_new_acct_no,
                         cad_ins_user, cad_ins_date, cad_lupd_user,
                         cad_lupd_date
                        )
                 VALUES (instcode, x.cal_pan_code, x.cal_file_name,
                         x.cal_remark, 'N', 'E',
                         errmsg, 'G', x.cal_acct_no,
                         lupduser, SYSDATE, lupduser,
                         SYSDATE
                        );
         WHEN NO_DATA_FOUND
         THEN
            ROLLBACK TO v_savepoint;
            v_succ_flag := 'E';
            errmsg := 'EXCP 1.2  NO SUCH PAN FOUND ' || x.cal_pan_code;

            UPDATE cms_group_acctlink_temp
               SET cal_result = errmsg,
                   cal_process_flag = 'E'
             WHERE ROWID = x.ROWID;

            INSERT INTO cms_acct_link_detail
                        (cad_inst_code, cad_card_no, cad_file_name,
                         cad_remarks, cad_msg24_flag, cad_process_flag,
                         cad_process_msg, cad_process_mode, cad_new_acct_no,
                         cad_ins_user, cad_ins_date, cad_lupd_user,
                         cad_lupd_date
                        )
                 VALUES (instcode, x.cal_pan_code, x.cal_file_name,
                         x.cal_remark, 'N', 'E',
                         errmsg, 'G', x.cal_acct_no,
                         lupduser, SYSDATE, lupduser,
                         SYSDATE
                        );
         WHEN OTHERS
         THEN
            ROLLBACK TO v_savepoint;
            v_succ_flag := 'E';
            errmsg := 'EXCP 1.2' || SQLERRM;

            UPDATE cms_group_acctlink_temp
               SET cal_result = errmsg,
                   cal_process_flag = 'E'
             WHERE ROWID = x.ROWID;

            INSERT INTO cms_acct_link_detail
                        (cad_inst_code, cad_card_no, cad_file_name,
                         cad_remarks, cad_msg24_flag, cad_process_flag,
                         cad_process_msg, cad_process_mode, cad_new_acct_no,
                         cad_ins_user, cad_ins_date, cad_lupd_user,
                         cad_lupd_date
                        )
                 VALUES (instcode, x.cal_pan_code, x.cal_file_name,
                         x.cal_remark, 'N', 'E',
                         errmsg, 'G', x.cal_acct_no,
                         lupduser, SYSDATE, lupduser,
                         SYSDATE
                        );
      END;

      BEGIN
         INSERT INTO pcms_audit_log
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date,
                      pal_process_msg, pal_reason_desc, pal_remarks,
                      pal_spprt_type
                     )
              VALUES (x.cal_pan_code, v_remark, v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_succ_flag, lupduser, SYSDATE,
                      errmsg, v_reasondesc, x.cal_remark,
                      'G'
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE cms_group_acctlink_temp
               SET cal_process_flag = 'E',
                   cal_result = 'Error while inserting into Audit log'
             WHERE ROWID = x.ROWID;
      END;                                                           --end 1.2
   END LOOP;
END;                                                                 --END 1.1
/


