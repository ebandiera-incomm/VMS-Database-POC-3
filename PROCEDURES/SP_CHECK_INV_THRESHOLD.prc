CREATE OR REPLACE PROCEDURE VMSCMS.sp_check_inv_threshold (
   p_inst_code        IN       NUMBER,
   p_user_code        IN       NUMBER,
   p_raise_flag       IN       VARCHAR,
   p_autorepl_count   OUT      NUMBER,
   p_shufle_count     OUT      NUMBER,
   p_errmsg           OUT      VARCHAR
)
AS
/*************************************************************************************
     * Created Date      : 03/Jan/2014
     * Created By        : Sagar More.
     * Purpose           : To automatically create pan for those merchants of whom
                           threshold (Reorder value) is reached
     * Release Number    : RI0027_B0002

     * Modified by      : DHINAKARAN B
     * Modified for     : DFCHOST-344
     * Modified Date    : 07-MAR-2014
     * Reviewer         : DHIRAJ
     * Reviewed Date    :
     * Build Number     :

     * Modified by      : DHINAKARAN B
     * Modified for     : Implement the Review changes t combine the two queries with the single queries
     * Modified Date    : 11-MAR-2014
     * Reviewer         : Dhiraj
     * Reviewed Date    : 05-Mar-2014
     * Build Number     : RI0027.2_B0001
     
      * Modified by      : Deepa T
     * Modified for     : For the Mantis Issue :14105 of DFCHOST-344
     * Modified Date    : 17-APR-2014
     * Reviewer         : spankaj
     * Reviewed Date    : 18-April-2014
     * Build Number     : RI0027.2_B0006
****************************************************************************************/
   v_err                  VARCHAR2 (1000);
   v_order_ref_no         cms_merinv_ordr.cmo_ordr_refrno%TYPE;
   excp_rej_record        EXCEPTION;
   v_loop_chk             NUMBER;
   v_autorepl_count       NUMBER;
   v_expirycard_count     NUMBER;
   v_nocards_ordr         cms_merinv_ordr.cmo_nocards_ordr%TYPE;
   v_reorder_cards_ordr   NUMBER;
   v_cpc_serl_flag        cms_prod_cattype.cpc_serl_flag%TYPE;
   v_sufl_dtl             NUMBER                                  DEFAULT 0;
BEGIN
   p_errmsg := 'SUCCESS';
   v_err := 'OK';
   v_loop_chk := 0;

   FOR i IN (SELECT cms_inst_code, cms_merprodcat_id, cms_location_id,
                    cms_reordr_levl, cms_reordr_value, cms_repl_flag,
                    cms_maxinv_levl, NVL (cms_curr_stock, 0) cms_curr_stock
               FROM cms_merinv_stock
              WHERE cms_inst_code = p_inst_code
                AND cms_repl_flag = 'Y'
                AND cms_curr_stock <= cms_reordr_levl)
   LOOP
      BEGIN
          v_cpc_serl_flag :=0;
          --Query was modified  based on the review comments
         BEGIN
           SELECT COUNT (CASE
                            WHEN cmo_authorize_flag = 'A' AND cmo_raise_flag = 'N'
                               THEN 1
                            ELSE 0
                         END
                        ) cnt,
                  NVL (SUM (CASE
                               WHEN cmo_authorize_flag = 'A'
                                    AND cmo_process_flag = 'N'
                                  THEN cmo_nocards_ordr
                               ELSE 0
                            END
                           ),
                       0
                      ) orders
             INTO v_autorepl_count, v_nocards_ordr
             FROM cms_merinv_ordr
            WHERE cmo_inst_code = i.cms_inst_code
              AND cmo_merprodcat_id = i.cms_merprodcat_id
              AND cmo_location_id = i.cms_location_id;
         EXCEPTION
           WHEN OTHERS
           THEN
              v_err :=
                    'EXCEPTION WHILE GETTING THE EXPIRY CARD COUNT '
                 || SUBSTR (SQLERRM, 1, 100);
              RAISE excp_rej_record;
         END;

         BEGIN
            SELECT COUNT (1)
              INTO v_expirycard_count
              FROM cms_merinv_merpan
             WHERE cmm_inst_code = i.cms_inst_code
               AND cmm_merprodcat_id = i.cms_merprodcat_id
               AND cmm_location_id = i.cms_location_id
               AND cmm_activation_flag = 'M'
               AND cmm_expiry_date < SYSDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err :=
                     'EXCEPTION WHILE GETTING THE EXPIRY CARD COUNT '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE excp_rej_record;
         END;

         BEGIN
            v_reorder_cards_ordr :=
                       i.cms_reordr_value + i.cms_curr_stock + v_nocards_ordr;

            IF v_reorder_cards_ordr > v_expirycard_count
            THEN
               v_reorder_cards_ordr :=
                                    v_reorder_cards_ordr - v_expirycard_count;
            END IF;

            IF v_reorder_cards_ordr > i.cms_maxinv_levl
            THEN
               v_err :=
                     'ORDER LESS NO OF CARDS  FOR THIS LOCATION ID:'
                  || i.cms_location_id
                  || ':PRODUCT CATEGORY ID:'
                  || i.cms_merprodcat_id;
               RAISE excp_rej_record;
            END IF;
         EXCEPTION
            WHEN excp_rej_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_err :=
                     'EXCEPTION WHILE OCCURED TO CALCULATE THE CARD NUMBER TO GENERATED'
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE excp_rej_record;
         END;

         BEGIN
            sp_requisition_id (TRUNC (SYSDATE), v_order_ref_no, v_err);

            IF v_err <> 'OK'
            THEN
               v_err := 'FROM SP_REQUISITION_ID ' || v_err;
               RAISE excp_rej_record;
            END IF;
         EXCEPTION
            WHEN excp_rej_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_err :=
                  'WHILE GENERATING ORDER_REF_NO '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE excp_rej_record;
         END;

         BEGIN
            SELECT cpc_serl_flag
              INTO v_cpc_serl_flag
              FROM cms_merinv_prodcat, cms_prod_cattype
             WHERE cmp_prod_code = cpc_prod_code
               AND cmp_prod_cattype = cpc_card_type
               AND cpc_inst_code = cmp_inst_code
               AND cmp_merprodcat_id = i.cms_merprodcat_id;
         EXCEPTION
            WHEN excp_rej_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_err :=
                  'WHILE GENERATING ORDER_REF_NO '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE excp_rej_record;
         END;

         BEGIN
            INSERT INTO cms_merinv_ordr
                        (cmo_inst_code, cmo_merprodcat_id,
                         cmo_location_id, cmo_nocards_ordr,
                         cmo_authorize_flag, cmo_authorize_date,
                         cmo_authorize_user, cmo_process_flag,
                         cmo_reject_reason, cmo_process_date,
                         cmo_process_user, cmo_lupd_date, cmo_lupd_user,
                         cmo_ins_date, cmo_ins_user, cmo_ordr_refrno,
                         cmo_success_records, cmo_error_records,
                         cmo_raise_flag
                        )
                 VALUES (p_inst_code, i.cms_merprodcat_id,
                         i.cms_location_id, i.cms_reordr_value,
                         'A', SYSDATE,
                         1, 'N',
                         NULL, SYSDATE,
                         1, SYSDATE, p_user_code,
                         SYSDATE, p_user_code, v_order_ref_no,
                         0, 0,
                         --'A'--Modified for the mantis ID :14105 of DFCHOST-344
                         p_raise_flag
                        );

            IF SQL%ROWCOUNT =1 THEN
            v_loop_chk := v_loop_chk + 1;
            END IF;

            IF v_cpc_serl_flag = 1
            THEN
               v_sufl_dtl := v_sufl_dtl + 1;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err :=
                     'WHILE INSERTING INTO INV ORDER '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE excp_rej_record;
         END;
      EXCEPTION
         WHEN excp_rej_record
         THEN
            INSERT INTO cms_threshold_errlog
                        (cte_merprodcat_id, cte_location_id, cte_ins_date, cte_msg,
                         cap_ins_user, cap_lupd_user, cte_lupd_date
                        )
                 VALUES (i.cms_merprodcat_id, i.cms_location_id, SYSDATE, v_err,
                         p_user_code, p_user_code, SYSDATE
                        );
         WHEN OTHERS
         THEN
            v_err := 'LOOP EXCP ' || SUBSTR (SQLERRM, 1, 100);

            INSERT INTO cms_threshold_errlog
                        (cte_merprodcat_id, cte_location_id, cte_ins_date, cte_msg,
                         cap_ins_user, cap_lupd_user, cte_lupd_date
                        )
                 VALUES (i.cms_merprodcat_id, i.cms_location_id, SYSDATE, v_err,
                         p_user_code, p_user_code, SYSDATE
                        );
      END;
   END LOOP;

   p_autorepl_count := v_loop_chk;
   p_shufle_count := v_sufl_dtl;
EXCEPTION
   WHEN OTHERS
   THEN
      p_errmsg := 'MAIN EXCP ' || SUBSTR (SQLERRM, 1, 100);
END;
/
SHOW ERROR