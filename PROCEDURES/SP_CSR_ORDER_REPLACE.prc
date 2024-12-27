create or replace PROCEDURE        VMSCMS.SP_CSR_ORDER_REPLACE (
    prm_inst_code            IN     NUMBER,
    prm_msg                  IN     VARCHAR2,
    prm_rrn                  IN     VARCHAR2,
    prm_delivery_channel     IN     VARCHAR2,
    prm_term_id              IN     VARCHAR2,
    prm_txn_code             IN     VARCHAR2,
    prm_txn_mode             IN     VARCHAR2,
    prm_tran_date            IN     VARCHAR2,
    prm_tran_time            IN     VARCHAR2,
    prm_card_no              IN     VARCHAR2,
    prm_bank_code            IN     VARCHAR2,
    prm_txn_amt              IN     NUMBER,
    prm_mcc_code             IN     VARCHAR2,
    prm_curr_code            IN     VARCHAR2,
    prm_prod_id              IN     VARCHAR2,
    prm_expry_date           IN     VARCHAR2,
    prm_stan                 IN     VARCHAR2,
    prm_mbr_numb             IN     VARCHAR2,
    prm_rvsl_code            IN     NUMBER,
    prm_call_id              IN     NUMBER,
    prm_ipaddress            IN     VARCHAR2,
    prm_ins_user             IN     NUMBER,
    prm_remark               IN     VARCHAR2,
    prm_fee_flag             IN     VARCHAR2, -- added by sagar to handle fee related changes on 28-Aug-2012
    prm_auth_id                 OUT VARCHAR2,
    prm_resp_code               OUT VARCHAR2,
    prm_resp_msg                OUT VARCHAR2,
    prm_capture_date            OUT DATE,
    prm_fee_amt              IN OUT VARCHAR2,
    prm_avail_bal               OUT VARCHAR2,
    prm_ledger_bal              OUT VARCHAR2,
    prm_process_msg             OUT VARCHAR2,
    --Sn Added for FSS-5135
    prm_oldcard_expry           OUT DATE,
    prm_newcard_expry           OUT DATE,
    prm_replacement_option      OUT VARCHAR2,
    --En Added for FSS-5135
    prm_np_flag              IN     VARCHAR2 DEFAULT 'N'   --Added for VMS-104
                                                        )
IS
    /**********************************************************************************************
      * VERSION                  :  1.0
      * DATE OF CREATION         : 4/May/2012
      * PURPOSE                  : Call logging for reissue with new pan
      * CREATED BY               : Sagar More
      * Mofication Reason        : ipaddress,remark log in transactionlog
      * LAST MODIFICATION DONE BY : Amit Sonar
      * LAST MODIFICATION DATE    : 06-Oct-2012
      * Build Number              :

      * Modified By      : Sagar M.
      * Modified Date    : 19-Apr-2013
      * Modified for     : Defect 10871
      * Modified Reason  : Logging of below details handled in tranasctionlog
                              1) Product code,Product category code,Card status,Acct Type,drcr flag,account number
                              2) Timestamp and Amount values logging correction
      * Reviewer         : Dhiraj
      * Reviewed Date    : 17-Apr-2013
      * Build Number     : RI0024.1_B0013

        * Modified by          : MageshKumar S.
        * Modified Date        : 19-July-16
        * Modified For         : FSS-4423
        * Modified reason      : Token LifeCycle Changes
        * Reviewer             : Saravanan/Spankaj
        * Build Number         : VMSGPRHOSTCSD4.6_B0001

        * Modified by          : MageshKumar S.
        * Modified Date        : 02-Aug-16
        * Modified For         : FSS-4423 Additional Changes
        * Modified reason      : Token LifeCycle Changes
        * Reviewer             : Saravanan/Spankaj
        * Build Number         : VMSGPRHOSTCSD4.6_B0002

        * Modified by          : Pankaj S.
        * Modified Date        : 16-May-17
        * Modified For         : FSS-5135 -Changes in Card replacement / renewal logic
        * Reviewer             : Saravanan
        * Build Number         : VMSGPRHOST_17.05

        * Modified by          : Pankaj S.
        * Modified Date        : 29-Aug-17
        * Modified For         : VMS-104:Card Replacement with Incoming Amount Logic
        * Reviewer             : Saravanan
        * Build Number         : VMSGPRHOST_17.12

      * Modified By      : Pankaj S.
         * Modified Date    : 05/01/2018
         * Purpose          : VMS-104
         * Reviewer         : Saravanan
         * Release Number   : VMSGPRHOST17.12

        * Modified by      : UBAIDUR RAHMAN.H
        * Modified Date    : 06-May-2021
        * Modified For     : VMS-4223 - B2B Replace card for virtual product is not creating card in Active status
        * Reviewer         : Saravanankumar
        * Build Number     : VMSR46_B0002

       * Modified By      : venkat Singamaneni
        * Modified Date    : 4-4-2022
        * Purpose          : Archival changes.
        * Reviewer         : Saravana Kumar A
        * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991

       * Modified By      : John Gingrich
        * Modified Date    : 7-20-2022
        * Purpose          : Instant Inactivity Fee
        * Reviewer         :
        * Build Number   : VMSGR66_B0001 for VMS-6072/FSP-1536
      **************************************************************************************************/
    v_table_list          VARCHAR2 (2000);
    v_colm_list           VARCHAR2 (2000);
    v_colm_qury           VARCHAR2 (4000);
    v_old_value           VARCHAR2 (4000);
    v_new_value           VARCHAR2 (4000);
    v_value               VARCHAR2 (4000);
    v_new_detl_old_card   VARCHAR2 (2000);
    v_new_card_value      VARCHAR2 (2000);
    v_call_seq            NUMBER (3);
    v_hash_pan            cms_appl_pan.cap_pan_code%TYPE;
    v_hash_new_pan        cms_appl_pan.cap_pan_code%TYPE;
    v_encr_pan            cms_appl_pan.cap_pan_code_encr%TYPE;
    v_resp_code           VARCHAR2 (3);
    v_resp_msg            VARCHAR2 (300);
    excp_rej_record       EXCEPTION;
    v_cap_acct_no         cms_appl_pan.cap_acct_no%TYPE;
    v_prod_code           cms_appl_pan.cap_prod_code%TYPE;
    v_prod_cattype        cms_appl_pan.cap_card_type%TYPE;
    v_proxynumber         cms_appl_pan.cap_proxy_number%TYPE;
    v_acct_balance        cms_acct_mast.cam_acct_bal%TYPE;
    v_ledger_balance      cms_acct_mast.cam_ledger_bal%TYPE;
    v_newcard_stat        cms_appl_pan.cap_card_stat%TYPE;
    v_new_pan             VARCHAR2 (50);            --changed for 21 digit pan
    v_spnd_acctno         cms_appl_pan.cap_acct_no%TYPE;
    -- ADDED BY GANESH ON 19-JUL-12
    v_fee_amt             cms_statements_log.csl_trans_amount%TYPE; -- Added by sagar on 21-Aug-2012 to fetch addtional fee details
    v_cam_acct_no         cms_acct_mast.cam_acct_no%TYPE;
    v_chk_clawback        VARCHAR2 (2);
    v_clawback_amt        CMS_CHARGE_DTL.ccd_clawback_amnt%TYPE;
    v_cam_type_code       cms_acct_mast.cam_type_code%TYPE; -- Added on 17-Apr-2013 for defect 10871
    v_timestamp           TIMESTAMP;  -- Added on 17-Apr-2013 for defect 10871
    V_APPLPAN_CARDSTAT    CMS_APPL_PAN.CAP_CARD_STAT%TYPE; --Added for defect 10871
    V_Closed_Pan          VARCHAR2 (50);            --changed for 21 digit pan
    V_Renew_Option        VARCHAR2 (50);
    v_txn_code            VARCHAR2 (50);

    v_Retperiod           DATE;                   --Added for VMS-5733/FSP-991
    v_Retdate             DATE;                   --Added for VMS-5733/FSP-991
    V_TOGGLE_VALUE        VARCHAR2 (50);                  --Added for VMS-6072
    V_COUNT               NUMBER;                         --Added for VMS-6072
BEGIN
    v_resp_msg := 'OK';                        --added by sagar on 14-Sep-2012

    IF prm_fee_flag = 'N'
    THEN
        prm_process_msg := 'FEE NOT APPLIED';
    END IF;


    BEGIN
        BEGIN
            v_hash_pan := gethash (prm_card_no);
        EXCEPTION
            WHEN OTHERS
            THEN
                v_resp_code := '21';
                v_resp_msg :=
                       'Error while converting pan into hash'
                    || SUBSTR (SQLERRM, 1, 100);
                RAISE excp_rej_record;
        END;

        BEGIN
            v_encr_pan := fn_emaps_main (prm_card_no);
        EXCEPTION
            WHEN OTHERS
            THEN
                v_resp_code := '21';
                v_resp_msg :=
                       'Error while converting pan into encr '
                    || SUBSTR (SQLERRM, 1, 100);
                RAISE excp_rej_record;
        END;

        /*  call log info   start */
        BEGIN
            SELECT cut_table_list, cut_colm_list, cut_colm_qury
              INTO v_table_list, v_colm_list, v_colm_qury
              FROM cms_calllogquery_mast
             WHERE     cut_inst_code = prm_inst_code
                   AND cut_devl_chnl = prm_delivery_channel
                   AND cut_txn_code = prm_txn_code;

            DBMS_OUTPUT.put_line (v_colm_qury);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_resp_code := '49';
                v_resp_msg :=
                    'Column list not found in cms_calllogquery_mast ';
                RAISE excp_rej_record;
            WHEN OTHERS
            THEN
                v_resp_msg :=
                       'Error while finding Column list '
                    || SUBSTR (SQLERRM, 1, 100);
                v_resp_code := '21';
                RAISE excp_rej_record;
        END;

        BEGIN
            EXECUTE IMMEDIATE v_colm_qury
                INTO v_old_value
                USING prm_inst_code, v_hash_pan;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_resp_msg :=
                       'Error while selecting old values -- '
                    || '---'
                    || SUBSTR (SQLERRM, 1, 100);
                v_resp_code := '21';
                RAISE excp_rej_record;
        END;

        BEGIN
            SELECT Cpc_Renew_Replace_Option, cap_card_stat
              INTO v_renew_option, V_APPLPAN_CARDSTAT
              FROM Cms_Prod_Cattype, Cms_Appl_Pan
             WHERE     Cpc_Inst_Code = Cap_Inst_Code
                   AND Cpc_Prod_Code = Cap_Prod_Code
                   AND Cpc_Card_Type = Cap_Card_Type
                   AND Cap_Pan_Code = v_hash_pan;


            IF V_Renew_Option = 'SP' AND V_APPLPAN_CARDSTAT <> '2'
            THEN
                v_txn_code := '21';                           -- same pan code
            ELSE
                v_txn_code := Prm_Txn_Code;               -- new pan tran code
            END IF;

            DBMS_OUTPUT.put_line (v_renew_option);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_Resp_Code := '49';
                v_resp_msg := 'Replace option not found ';
                RAISE excp_rej_record;
            WHEN OTHERS
            THEN
                V_Resp_Msg :=
                       'Error while finding Renew replace option '
                    || SUBSTR (SQLERRM, 1, 100);
                v_resp_code := '21';
                RAISE Excp_Rej_Record;
        END;

        BEGIN
            sp_chw_order_replace (prm_inst_code,
                                  prm_msg,
                                  prm_rrn,
                                  prm_delivery_channel,
                                  prm_term_id,
                                  v_txn_code,
                                  prm_txn_mode,
                                  prm_tran_date,
                                  prm_tran_time,
                                  prm_card_no,
                                  prm_bank_code,
                                  prm_txn_amt,
                                  prm_mcc_code,
                                  prm_curr_code,
                                  prm_prod_id,
                                  prm_expry_date,
                                  prm_stan,
                                  prm_mbr_numb,
                                  prm_rvsl_code,
                                  prm_ipaddress,
                                  prm_auth_id,
                                  prm_resp_code,
                                  prm_resp_msg,
                                  prm_capture_date,
                                  v_closed_pan,
                                  --Sn Added for FSS-5135
                                  prm_oldcard_expry,
                                  prm_newcard_expry,
                                  prm_replacement_option,
                                  --En Added for FSS-5135
                                  prm_fee_flag,
                                  prm_np_flag              --Added for VMS-104
                                             );

            IF prm_resp_code = '00'
            THEN
                v_new_pan := TRIM (prm_resp_msg);
                prm_resp_msg := v_resp_msg;   -- added by sagar on 14-Sep-2012
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_resp_code := '21';
                v_resp_msg :=
                       'while calling reissue process '
                    || SUBSTR (SQLERRM, 1, 100);
                RAISE excp_rej_record;
        END;

        IF prm_resp_code = '00'
        THEN
            --v_new_pan := TRIM (prm_resp_msg);
            IF prm_replacement_option != 'SP'
            THEN
                BEGIN
                    v_hash_new_pan := gethash (v_new_pan);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        v_resp_code := '21';
                        v_resp_msg :=
                               'Error while converting pan into hash'
                            || SUBSTR (SQLERRM, 1, 100);
                        RAISE excp_rej_record;
                END;
            END IF;

            BEGIN
                EXECUTE IMMEDIATE v_colm_qury
                    INTO v_new_detl_old_card
                    USING prm_inst_code, v_hash_pan;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_resp_msg :=
                           'Error while selecting new details of old card -- '
                        || '---'
                        || SUBSTR (SQLERRM, 1, 100);
                    v_resp_code := '21';
                    RAISE excp_rej_record;
            END;

            IF prm_replacement_option != 'SP'
            THEN
                BEGIN
                    EXECUTE IMMEDIATE v_colm_qury
                        INTO v_new_card_value
                        USING prm_inst_code, v_hash_new_pan;

                    v_new_value :=
                        v_new_detl_old_card || '~' || v_new_card_value;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        v_resp_msg :=
                               'Error while selecting values of new card -- '
                            || '---'
                            || SUBSTR (SQLERRM, 1, 100);
                        v_resp_code := '21';
                        RAISE excp_rej_record;
                END;
            END IF;

            -- SN : ADDED BY Ganesh on 18-JUL-12
            BEGIN
                SELECT cap_acct_no
                  INTO v_spnd_acctno
                  FROM cms_appl_pan
                 WHERE     cap_pan_code = v_hash_pan
                       AND cap_inst_code = prm_inst_code
                       AND cap_mbr_numb = prm_mbr_numb;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    v_resp_code := '21';
                    v_resp_msg :=
                        'Spending Account Number Not Found For the Card in PAN Master ';
                    RAISE excp_rej_record;
                WHEN OTHERS
                THEN
                    v_resp_code := '21';
                    v_resp_msg :=
                           'Error While Selecting Spending account Number for Card '
                        || SUBSTR (SQLERRM, 1, 100);
                    RAISE excp_rej_record;
            END;

            IF prm_call_id IS NOT NULL
            THEN
                -- EN : ADDED BY Ganesh on 18-JUL-12
                BEGIN
                    BEGIN
                        SELECT NVL (MAX (ccd_call_seq), 0) + 1
                          INTO v_call_seq
                          FROM cms_calllog_details
                         WHERE     ccd_inst_code = ccd_inst_code
                               AND ccd_call_id = prm_call_id
                               AND ccd_pan_code = v_hash_pan;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            v_resp_msg :=
                                'record is not present in cms_calllog_details  ';
                            v_resp_code := '49';
                            RAISE excp_rej_record;
                        WHEN OTHERS
                        THEN
                            v_resp_msg :=
                                   'Error while selecting frmo cms_calllog_details '
                                || SUBSTR (SQLERRM, 1, 100);
                            v_resp_code := '21';
                            RAISE excp_rej_record;
                    END;

                    INSERT INTO cms_calllog_details (ccd_inst_code,
                                                     ccd_call_id,
                                                     ccd_pan_code,
                                                     ccd_call_seq,
                                                     ccd_rrn,
                                                     ccd_devl_chnl,
                                                     ccd_txn_code,
                                                     ccd_tran_date,
                                                     ccd_tran_time,
                                                     ccd_tbl_names,
                                                     ccd_colm_name,
                                                     ccd_old_value,
                                                     ccd_new_value,
                                                     ccd_comments,
                                                     ccd_ins_user,
                                                     ccd_ins_date,
                                                     ccd_lupd_user,
                                                     ccd_lupd_date,
                                                     ccd_acct_no -- CCD_ACCT_NO ADDED BY GANESH ON 18-JUL-2012
                                                                )
                         VALUES (prm_inst_code,
                                 prm_call_id,
                                 v_hash_pan,
                                 V_Call_Seq,
                                 Prm_Rrn,
                                 Prm_Delivery_Channel,
                                 --prm_txn_code, prm_tran_date, prm_tran_time,
                                 v_txn_code,
                                 prm_tran_date,
                                 prm_tran_time,
                                 v_table_list,
                                 v_colm_list,
                                 v_old_value,
                                 v_new_value,
                                 prm_remark,
                                 prm_ins_user,
                                 SYSDATE,
                                 prm_ins_user,
                                 SYSDATE,
                                 v_spnd_acctno -- V_SPND_ACCTNO ADDED BY GANESH ON 18-JUL-2012
                                              );
                EXCEPTION
                    WHEN excp_rej_record
                    THEN
                        RAISE;
                    WHEN OTHERS
                    THEN
                        v_resp_code := '21';
                        v_resp_msg :=
                               ' Error while inserting into cms_calllog_details '
                            || SUBSTR (SQLERRM, 1, 100);
                        RAISE excp_rej_record;
                END;
            END IF;
        END IF;

        -------------------------------------------------------------------
        --SN: Added by sagar on 28-Aug-2012 to fetch additional fee details
        -------------------------------------------------------------------


        BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO prm_avail_bal, prm_ledger_bal
              FROM cms_acct_mast
             WHERE     cam_inst_code = prm_inst_code
                   AND cam_acct_no =
                       (SELECT cap_acct_no
                          FROM cms_appl_pan
                         WHERE     cap_inst_code = prm_inst_code
                               AND cap_pan_code = v_hash_pan);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                prm_avail_bal := NULL;
                prm_ledger_bal := NULL;
            WHEN OTHERS
            THEN
                v_resp_code := '21';             -- added by sgar on 25SEP2012
                v_resp_msg :=
                       'Error While Fetching Balance '
                    || SUBSTR (SQLERRM, 1, 100);
                -- rollback;
                RAISE excp_rej_record;
        END;



        IF prm_fee_flag = 'Y'
        THEN
            BEGIN
                v_Retdate :=
                    TO_DATE (SUBSTR (TRIM (prm_tran_date), 1, 8), 'yyyymmdd');

                SELECT (ADD_MONTHS (TRUNC (SYSDATE, 'MM'),
                                    '-' || RETENTION_PERIOD))
                  INTO v_Retperiod
                  FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL
                 WHERE     OPERATION_TYPE = 'ARCHIVE'
                       AND OBJECT_NAME = 'CMS_STATEMENTS_LOG_EBR';



                IF (v_Retdate > v_Retperiod)
                THEN
                    SELECT csl_trans_amount
                      INTO v_fee_amt
                      FROM cms_statements_log
                     WHERE     csl_pan_no = v_hash_pan
                           AND csl_rrn = prm_rrn
                           AND csl_business_date = prm_tran_date
                           AND csl_business_time = prm_tran_time
                           AND txn_fee_flag = 'Y'
                           AND Csl_Delivery_Channel = Prm_Delivery_Channel
                           --  and    csl_txn_code         = prm_txn_code;
                           AND csl_txn_code = v_txn_code;
                ELSE
                    SELECT csl_trans_amount
                      INTO v_fee_amt
                      FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
                     WHERE     csl_pan_no = v_hash_pan
                           AND csl_rrn = prm_rrn
                           AND csl_business_date = prm_tran_date
                           AND csl_business_time = prm_tran_time
                           AND txn_fee_flag = 'Y'
                           AND Csl_Delivery_Channel = Prm_Delivery_Channel
                           --  and    csl_txn_code         = prm_txn_code;
                           AND csl_txn_code = v_txn_code;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    BEGIN
                        SELECT 1, ccd_clawback_amnt
                          INTO v_chk_clawback, v_clawback_amt
                          FROM CMS_CHARGE_DTL
                         WHERE     ccd_pan_code = v_hash_pan
                               AND ccd_rrn = prm_rrn
                               AND ccd_acct_no = v_cam_acct_no
                               AND Ccd_Delivery_Channel =
                                   Prm_Delivery_Channel
                               -- and   ccd_txn_code = prm_txn_code
                               AND ccd_txn_code = v_txn_code
                               AND ccd_clawback = 'Y';

                        IF v_clawback_amt >= prm_fee_amt
                        THEN
                            prm_process_msg :=
                                'Fee Amount Will Be Collected Through Clawback';
                        END IF;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            prm_process_msg := 'Fee not debited';
                            v_fee_amt := 0;
                        WHEN OTHERS
                        THEN
                            v_resp_msg :=
                                   'Error While clawback check '
                                || SUBSTR (SQLERRM, 1, 100);
                            --rollback;
                            v_resp_code := '21'; -- added by sgar on 25SEP2012
                            RAISE excp_rej_record;
                    END;
                WHEN excp_rej_record
                THEN
                    RAISE;
                WHEN OTHERS
                THEN
                    v_resp_msg :=
                           'Error While fetching fee amount '
                        || SUBSTR (SQLERRM, 1, 100);
                    --rollback;
                    v_resp_code := '21';         -- added by sgar on 25SEP2012
                    RAISE excp_rej_record;
            END;


            BEGIN
                IF prm_process_msg IS NULL
                THEN
                    IF prm_fee_amt = v_fee_amt
                    THEN
                        prm_process_msg := 'Fee Debited Successfully';
                        prm_fee_amt := v_fee_amt;
                    ELSIF v_fee_amt = 0
                    THEN
                        prm_process_msg := 'Fee not Debited. Complementary';
                        prm_fee_amt := v_fee_amt;
                    ELSIF prm_fee_amt > v_fee_amt
                    THEN
                        prm_process_msg :=
                            'Fee Debited Partially. Balance fee Will Be Collected Through Clawback';
                        prm_fee_amt := v_fee_amt;
                    END IF;
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_resp_msg :=
                           'Error while assigning fee amt and message '
                        || SUBSTR (SQLERRM, 1, 100);
                    --rollback;
                    v_resp_code := '21';         -- added by sgar on 25SEP2012
                    RAISE excp_rej_record;
            END;
        END IF;

        -------------------------------------------------------------------
        --EN: Added by sagar on 28-Aug-2012 to fetch additional fee details
        -------------------------------------------------------------------


        --------------------------------------
        --SN: Added by sagar on 25-Sep-2012
        --------------------------------------


        BEGIN
            v_Retdate :=
                TO_DATE (SUBSTR (TRIM (prm_tran_date), 1, 8), 'yyyymmdd');

            SELECT (ADD_MONTHS (TRUNC (SYSDATE, 'MM'),
                                '-' || RETENTION_PERIOD))
              INTO v_Retperiod
              FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL
             WHERE     OPERATION_TYPE = 'ARCHIVE'
                   AND OBJECT_NAME = 'TRANSACTIONLOG_EBR';



            IF (v_Retdate > v_Retperiod)
            THEN
                UPDATE transactionlog
                   SET remark = prm_remark,
                       add_ins_user = prm_ins_user,
                       add_lupd_user = prm_ins_user,
                       ipaddress = prm_ipaddress --added by amit on 06-Oct-2012 to log ipaddress in transactionlog table
                 WHERE     instcode = prm_inst_code
                       AND customer_card_no = v_hash_pan
                       AND rrn = prm_rrn
                       AND business_date = prm_tran_date
                       AND business_time = prm_tran_time
                       AND Delivery_Channel = Prm_Delivery_Channel
                       --    AND txn_code = prm_txn_code;
                       AND txn_code = v_txn_code;
            ELSE
                UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
                   SET remark = prm_remark,
                       add_ins_user = prm_ins_user,
                       add_lupd_user = prm_ins_user,
                       ipaddress = prm_ipaddress --added by amit on 06-Oct-2012 to log ipaddress in transactionlog table
                 WHERE     instcode = prm_inst_code
                       AND customer_card_no = v_hash_pan
                       AND rrn = prm_rrn
                       AND business_date = prm_tran_date
                       AND business_time = prm_tran_time
                       AND Delivery_Channel = Prm_Delivery_Channel
                       --    AND txn_code = prm_txn_code;
                       AND txn_code = v_txn_code;
            END IF;

            IF SQL%ROWCOUNT = 0
            THEN
                v_resp_code := '21';
                v_resp_msg := 'Txn not updated in transactiolog for remark';
                RAISE excp_rej_record;
            END IF;
        EXCEPTION
            WHEN excp_rej_record
            THEN
                RAISE;
            WHEN OTHERS
            THEN
                v_resp_code := '21';
                v_resp_msg :=
                       'Error while updating into transactiolog '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE excp_rej_record;
        END;
    --------------------------------------
    --EN: Added by sagar on 25-Sep-2012
    --------------------------------------

    ------------------------------------------------------------------------------------------------------------------------------------------------
    EXCEPTION
        WHEN excp_rej_record
        THEN
            ROLLBACK;

            BEGIN
                SELECT cms_iso_respcde
                  INTO prm_resp_code
                  FROM cms_response_mast
                 WHERE     cms_inst_code = prm_inst_code
                       AND cms_delivery_channel = prm_delivery_channel
                       AND cms_response_id = v_resp_code;

                prm_resp_msg := v_resp_msg;
            EXCEPTION
                WHEN OTHERS
                THEN
                    prm_resp_msg :=
                           'Problem while selecting data from response master2 '
                        || v_resp_code
                        || SUBSTR (SQLERRM, 1, 100);
                    prm_resp_code := '89';
                    RETURN;
            END;

            BEGIN
                SELECT cap_acct_no,
                       cap_prod_code,
                       cap_card_type,
                       cap_proxy_number,
                       cap_card_stat                  --Added for defect 10871
                  INTO v_cap_acct_no,
                       v_prod_code,
                       v_prod_cattype,
                       v_proxynumber,
                       v_applpan_cardstat             --Added for defect 10871
                  FROM cms_appl_pan
                 WHERE     cap_inst_code = prm_inst_code
                       AND cap_pan_code = v_hash_pan;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_cap_acct_no := NULL;
                    v_prod_code := NULL;
                    v_prod_cattype := NULL;
                    v_proxynumber := NULL;
            END;

            BEGIN
                SELECT cam_acct_bal, cam_ledger_bal, cam_type_code --Added for defect 10871
                  INTO v_acct_balance, v_ledger_balance, v_cam_type_code --Added for defect 10871
                  FROM cms_acct_mast
                 WHERE     cam_inst_code = prm_inst_code
                       AND cam_acct_no = v_cap_acct_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_acct_balance := NULL;
                    v_ledger_balance := NULL;
            END;

            BEGIN
                INSERT INTO cms_transaction_log_dtl (
                                ctd_delivery_channel,
                                ctd_txn_code,
                                ctd_txn_type,
                                ctd_txn_mode,
                                ctd_business_date,
                                ctd_business_time,
                                ctd_customer_card_no,
                                ctd_txn_amount,
                                ctd_txn_curr,
                                ctd_actual_amount,
                                ctd_fee_amount,
                                ctd_waiver_amount,
                                ctd_servicetax_amount,
                                ctd_cess_amount,
                                ctd_bill_amount,
                                ctd_bill_curr,
                                ctd_process_flag,
                                ctd_process_msg,
                                ctd_rrn,
                                ctd_system_trace_audit_no,
                                ctd_customer_card_no_encr,
                                ctd_msg_type,
                                ctd_cust_acct_number,
                                ctd_inst_code,
                                ctd_lupd_date,
                                ctd_lupd_user,
                                ctd_ins_date,
                                ctd_ins_user)
                     --  VALUES (prm_delivery_channel, prm_txn_code, NULL,
                     VALUES (prm_delivery_channel,
                             v_txn_code,
                             NULL,
                             prm_txn_mode,
                             prm_tran_date,
                             prm_tran_time,
                             v_hash_pan,
                             NULL,
                             prm_curr_code,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             'E',
                             v_resp_msg,
                             prm_rrn,
                             prm_stan,
                             v_encr_pan,
                             prm_msg,
                             v_cap_acct_no,
                             prm_inst_code,
                             SYSDATE,
                             prm_ins_user,
                             SYSDATE,
                             prm_ins_user);
            EXCEPTION
                WHEN OTHERS
                THEN
                    prm_resp_code := '89';
                    prm_resp_msg :=
                           'Problem while inserting data into transaction log1  dtl'
                        || SUBSTR (SQLERRM, 1, 100);
                    ROLLBACK;
                    RETURN;
            END;

            --Sn create a entry in txn log
            BEGIN
                INSERT INTO transactionlog (msgtype,
                                            rrn,
                                            delivery_channel,
                                            date_time,
                                            txn_code,
                                            txn_type,
                                            txn_mode,
                                            txn_status,
                                            response_code,
                                            business_date,
                                            business_time,
                                            customer_card_no,
                                            total_amount,
                                            currencycode,
                                            productid,
                                            categoryid,
                                            auth_id,
                                            trans_desc,
                                            amount,
                                            system_trace_audit_no,
                                            instcode,
                                            cr_dr_flag,
                                            customer_card_no_encr,
                                            proxy_number,
                                            reversal_code,
                                            customer_acct_no,
                                            acct_balance,
                                            ledger_balance,
                                            response_id,
                                            error_msg,
                                            add_lupd_date,
                                            add_lupd_user,
                                            add_ins_date,
                                            add_ins_user,
                                            remark, --added by amit on 06-Oct-2012 to log remark
                                            ipaddress, --added by amit on 06-Oct-2012 to log ip
                                            cardstatus, --added for defect 10871
                                            acct_type, --added for defect 10871
                                            time_stamp --added for defect 10871
                                                      )
                         VALUES (
                                    prm_msg,
                                    prm_rrn,
                                    prm_delivery_channel,
                                    TO_DATE (
                                        prm_tran_date || ' ' || prm_tran_time,
                                        'yyyymmdd hh24:mi:ss'),
                                    --   prm_txn_code, NULL, prm_txn_mode,
                                    v_txn_code,
                                    NULL,
                                    prm_txn_mode,
                                    DECODE (prm_resp_code, '00', 'C', 'F'),
                                    prm_resp_code,
                                    prm_tran_date,
                                    prm_tran_time,
                                    v_hash_pan,
                                    TRIM (
                                        TO_CHAR (0, '99999999999999990.99')),
                                    prm_curr_code,
                                    v_prod_code,
                                    v_prod_cattype,
                                    prm_auth_id,
                                    prm_remark,
                                    TRIM (
                                        TO_CHAR (0, '999999999999999990.99')),
                                    prm_stan,
                                    prm_inst_code,
                                    'NA',
                                    v_encr_pan,
                                    v_proxynumber,
                                    '00',
                                    v_cap_acct_no,
                                    v_acct_balance,
                                    v_ledger_balance,
                                    v_resp_code,
                                    prm_resp_msg,
                                    SYSDATE,
                                    prm_ins_user,
                                    SYSDATE,
                                    prm_ins_user,
                                    prm_remark, --added by amit on 06-Oct-2012 to log remark
                                    prm_ipaddress, --added by amit on 06-Oct-2012 to log ip
                                    v_applpan_cardstat, --added for defect 10871
                                    v_cam_type_code,  --added for defect 10871
                                    v_timestamp       --added for defect 10871
                                               );
            EXCEPTION
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    prm_resp_code := '89';
                    prm_resp_msg :=
                           'Problem while inserting data into transaction log3 '
                        || SUBSTR (SQLERRM, 1, 100);
                    RETURN;
            END;
        --En create a entry in txn log
        WHEN OTHERS
        THEN
            ROLLBACK;

            BEGIN
                SELECT cms_iso_respcde
                  INTO prm_resp_code
                  FROM cms_response_mast
                 WHERE     cms_inst_code = prm_inst_code
                       AND cms_delivery_channel = prm_delivery_channel
                       AND cms_response_id = '21';

                prm_resp_msg :=
                       'Error from others exception '
                    || SUBSTR (SQLERRM, 1, 100);
            EXCEPTION
                WHEN OTHERS
                THEN
                    prm_resp_msg :=
                           'Problem while selecting data from response master3 '
                        || v_resp_code
                        || SUBSTR (SQLERRM, 1, 100);
                    prm_resp_code := '89';
                    RETURN;
            END;

            BEGIN
                SELECT cap_acct_no,
                       cap_prod_code,
                       cap_card_type,
                       cap_proxy_number
                  INTO v_cap_acct_no,
                       v_prod_code,
                       v_prod_cattype,
                       v_proxynumber
                  FROM cms_appl_pan
                 WHERE     cap_inst_code = prm_inst_code
                       AND cap_pan_code = v_hash_pan;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_cap_acct_no := NULL;
                    v_prod_code := NULL;
                    v_prod_cattype := NULL;
                    v_proxynumber := NULL;
            END;

            BEGIN
                SELECT cam_acct_bal, cam_ledger_bal
                  INTO v_acct_balance, v_ledger_balance
                  FROM cms_acct_mast
                 WHERE     cam_inst_code = prm_inst_code
                       AND cam_acct_no = v_cap_acct_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_acct_balance := NULL;
                    v_ledger_balance := NULL;
            END;

            BEGIN
                INSERT INTO cms_transaction_log_dtl (
                                ctd_delivery_channel,
                                ctd_txn_code,
                                ctd_txn_type,
                                ctd_txn_mode,
                                ctd_business_date,
                                ctd_business_time,
                                ctd_customer_card_no,
                                ctd_txn_amount,
                                ctd_txn_curr,
                                ctd_actual_amount,
                                ctd_fee_amount,
                                ctd_waiver_amount,
                                ctd_servicetax_amount,
                                ctd_cess_amount,
                                ctd_bill_amount,
                                ctd_bill_curr,
                                ctd_process_flag,
                                ctd_process_msg,
                                ctd_rrn,
                                ctd_system_trace_audit_no,
                                ctd_customer_card_no_encr,
                                ctd_msg_type,
                                ctd_cust_acct_number,
                                ctd_inst_code,
                                ctd_lupd_date,
                                ctd_lupd_user,
                                ctd_ins_date,
                                ctd_ins_user)
                     --  VALUES (prm_delivery_channel, prm_txn_code, NULL,
                     VALUES (prm_delivery_channel,
                             v_txn_code,
                             NULL,
                             prm_txn_mode,
                             prm_tran_date,
                             prm_tran_time,
                             v_hash_pan,
                             NULL,
                             prm_curr_code,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             'E',
                             v_resp_msg,
                             prm_rrn,
                             prm_stan,
                             v_encr_pan,
                             prm_msg,
                             v_cap_acct_no,
                             prm_inst_code,
                             SYSDATE,
                             prm_ins_user,
                             SYSDATE,
                             prm_ins_user);
            EXCEPTION
                WHEN OTHERS
                THEN
                    prm_resp_code := '89';
                    prm_resp_msg :=
                           'Problem while inserting data into transaction log1  dtl'
                        || SUBSTR (SQLERRM, 1, 100);
                    ROLLBACK;
                    RETURN;
            END;

            --Sn create a entry in txn log
            BEGIN
                INSERT INTO transactionlog (msgtype,
                                            rrn,
                                            delivery_channel,
                                            date_time,
                                            txn_code,
                                            txn_type,
                                            txn_mode,
                                            txn_status,
                                            response_code,
                                            business_date,
                                            business_time,
                                            customer_card_no,
                                            total_amount,
                                            currencycode,
                                            productid,
                                            categoryid,
                                            auth_id,
                                            trans_desc,
                                            amount,
                                            system_trace_audit_no,
                                            instcode,
                                            cr_dr_flag,
                                            customer_card_no_encr,
                                            proxy_number,
                                            reversal_code,
                                            customer_acct_no,
                                            acct_balance,
                                            ledger_balance,
                                            response_id,
                                            error_msg,
                                            add_lupd_date,
                                            add_lupd_user,
                                            add_ins_date,
                                            add_ins_user,
                                            remark, --added by amit on 06-Oct-2012 to log remark
                                            ipaddress, --added by amit on 06-Oct-2012 to log ip
                                            cardstatus, --added for defect 10871
                                            acct_type, --added for defect 10871
                                            time_stamp --added for defect 10871
                                                      )
                         VALUES (
                                    prm_msg,
                                    prm_rrn,
                                    prm_delivery_channel,
                                    TO_DATE (
                                        prm_tran_date || ' ' || prm_tran_time,
                                        'yyyymmdd hh24:mi:ss'),
                                    --    prm_txn_code, NULL, prm_txn_mode,
                                    v_txn_code,
                                    NULL,
                                    prm_txn_mode,
                                    DECODE (prm_resp_code, '00', 'C', 'F'),
                                    prm_resp_code,
                                    prm_tran_date,
                                    prm_tran_time,
                                    v_hash_pan,
                                    TRIM (
                                        TO_CHAR (0, '99999999999999990.99')),
                                    prm_curr_code,
                                    v_prod_code,
                                    v_prod_cattype,
                                    prm_auth_id,
                                    prm_remark,
                                    TRIM (
                                        TO_CHAR (0, '999999999999999990.99')),
                                    prm_stan,
                                    prm_inst_code,
                                    'NA',
                                    v_encr_pan,
                                    v_proxynumber,
                                    '00',
                                    v_cap_acct_no,
                                    v_acct_balance,
                                    v_ledger_balance,
                                    v_resp_code,
                                    prm_resp_msg,
                                    SYSDATE,
                                    prm_ins_user,
                                    SYSDATE,
                                    prm_ins_user,
                                    prm_remark, --added by amit on 06-Oct-2012 to log remark
                                    prm_ipaddress, --added by amit on 06-Oct-2012 to log ip
                                    v_applpan_cardstat, --added for defect 10871
                                    v_cam_type_code,  --added for defect 10871
                                    v_timestamp       --added for defect 10871
                                               );
            EXCEPTION
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    prm_resp_code := '89';
                    prm_resp_msg :=
                           'Problem while inserting data into transaction log3 '
                        || SUBSTR (SQLERRM, 1, 100);
                    RETURN;
            END;
    END;

    DBMS_OUTPUT.put_line (prm_resp_msg);

    BEGIN
        SELECT UPPER (TRIM (NVL (CIP_PARAM_VALUE, 'Y')))
          INTO V_TOGGLE_VALUE
          FROM VMSCMS.CMS_INST_PARAM
         WHERE CIP_INST_CODE = 1 AND CIP_PARAM_KEY = 'VMS_5657_TOGGLE';
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            V_TOGGLE_VALUE := 'Y';
    END;

    IF V_TOGGLE_VALUE = 'Y'
    THEN
        SELECT COUNT (*)
          INTO V_COUNT
          FROM VMS_DORMANTFEE_TXNS_CONFIG
         WHERE     VDT_PROD_CODE = V_PROD_CODE
               AND VDT_CARD_TYPE = v_prod_cattype
               AND VDT_DELIVERY_CHNNL = prm_delivery_channel
               AND VDT_TXN_CODE = PRM_TXN_CODE
               AND VDT_IS_ACTIVE = 1;

        IF V_COUNT != 0
        THEN
            UPDATE CMS_APPL_PAN
               SET CAP_LAST_TXNDATE = SYSDATE
             WHERE     CAP_PAN_CODE = V_HASH_PAN
                   AND CAP_INST_CODE = prm_inst_code
                   AND CAP_MBR_NUMB = prm_mbr_numb;
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        prm_resp_code := '89';
        prm_resp_msg := ' Error from mail' || SUBSTR (SQLERRM, 1, 100);
        RETURN;
END;
/