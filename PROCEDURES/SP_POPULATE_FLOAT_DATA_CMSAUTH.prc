CREATE OR REPLACE PROCEDURE VMSCMS.sp_populate_float_data_cmsauth (
   prm_inst_code               NUMBER,
   prm_curr_code               VARCHAR2,
   prm_gl_code                 VARCHAR2,
   prm_gl_desc                 VARCHAR2,
   prm_subgl_code              VARCHAR2,                                -- New
   prm_subgl_desc              VARCHAR2,
   prm_flaot_flag              VARCHAR2,
   prm_orgnl_tran_type         VARCHAR2,
   prm_ins_date                DATE,
   prm_txn_amount              NUMBER,
   prm_txn_code                VARCHAR2,
   prm_rvsl_code               NUMBER,
   prm_msg_typ                 VARCHAR2,
   prm_delivery_channel        VARCHAR2,
   --   PRM_TRAN_TYPE          VARCHAR2,
   prm_errmsg            OUT   VARCHAR2
)
IS
   CURSOR c3
   IS
      SELECT DISTINCT ctd_tran_id, ctd_tran_desc
--,CTD_TRAN_TYPE
      FROM            cms_tmode_dtl
                WHERE ctd_tranhead_flag = 'L' AND ctd_tran_code = prm_txn_code
                --AND ctd_reversal_code=prm_rvsl_code AND ctd_msg_type=prm_msg_typ --commented for incomm by srini
               AND ctd_msg_type=prm_msg_typ  AND ctd_delivery_channel=prm_delivery_channel;

   v_totamt       NUMBER;
   v_credit_amt   NUMBER;
   v_debit_amt    NUMBER;
   v_cnt          NUMBER;
   v_tran_type    VARCHAR2 (2);
BEGIN
   prm_errmsg := 'OK';

   IF prm_flaot_flag = 'F'
   THEN
      FOR i3 IN c3
      LOOP
         BEGIN                                           --<< LOOP BEGIN I3>>
            --    BEGIN
            v_tran_type := NULL;
            v_totamt := prm_txn_amount;

            --    v_tran_type :=  prm_tran_type;
                              /* SELECT  SUM(TOTAL_AMOUNT)
                         INTO         V_TOTAMT
                            FROM    TRANSACTIONLOG ,
                                  CMS_APPL_PAN ,
                                  CMS_BIN_PARAM ,
                                  CMS_PROD_MAST,
                                  CMS_TMODE_DTL,
                                  CMS_GL_ACCT_MAST
                                 WHERE  CAP_PROD_CODE = CPM_PROD_CODE
                                 AND    CAP_PAN_CODE  = CUSTOMER_CARD_NO
                                 AND     TRUNC(DATE_TIME) = TRUNC(PRM_INS_DATE)
                                 AND    CBP_PARAM_NAME = 'Currency'
                                 AND    CBP_PROFILE_CODE = CPM_PROFILE_CODE
                                 AND    CAP_PROD_CODE = CPM_PROD_CODE
                                 AND    CBP_PARAM_VALUE = PRM_CURR_CODE
                                 AND    CTD_TRAN_CODE   = TXN_CODE
                                 AND    CTD_TRAN_ID     = I3.CTD_TRAN_ID
                                 AND    CAP_PAN_CODE    = CGA_ACCT_CODE
                                 AND    CGA_GL_CODE     = TRIM(PRM_GL_CODE)
                                 AND    CGA_SUBGL_CODE  = TRIM(PRM_SUBGL_CODE)
                                 AND     RESPONSE_CODE = '00'; */
            BEGIN
               SELECT ctd_tran_type
                 INTO v_tran_type
                 FROM cms_tmode_dtl                            -- ISO TXN CODE
                WHERE ctd_tran_id = i3.ctd_tran_id
                  AND ctd_tran_code = prm_txn_code
                  and CTD_DELIVERY_CHANNEL = prm_delivery_channel;
            -- AND   CTD_TRAN_TYPE = prm_orgnl_tran_type;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                 -- PRM_ERRMSG := 'Error while selecting tran type';
                  v_tran_type := '';
                  --RETURN;
                  NULL;
            END;

            /*  IF  V_TOTAMT IS NULL THEN
            --  PRM_ERRMSG := 'Error while selecting data ';
            --  RETURN;
            V_TOTAMT := 0;
              END IF; */

            /*    EXCEPTION
                 WHEN OTHERS THEN
                 PRM_ERRMSG := 'Error from inner loop I3';
                 RETURN;
                END; */
           
         --END IF;

         --En insert a record into float report
            ---commented to for insert for a txn
            /* --Sn select gl entries from float report

               BEGIN
                   SELECT 1
                   INTO        v_cnt
                   FROM      CMS_FLOAT_SUBGLWISE_REPORT
                   WHERE   TRUNC(CFSR_TRAN_DATE)  = TRUNC(PRM_INS_DATE)
                   AND           CFSR_CURR_CODE             = PRM_CURR_CODE
                   AND           CFSR_GL_CODE                      = TRIM(PRM_GL_CODE)
                   AND           CFSR_SUBGL_CODE                =  TRIM(PRM_SUBGL_CODE)
                   AND        CFSR_PARAM_KEY                 =    I3.CTD_TRAN_DESC;

                   UPDATE CMS_FLOAT_SUBGLWISE_REPORT
                  SET           CFSR_CREDIT_AMOUNT =  CFSR_CREDIT_AMOUNT + V_CREDIT_AMT ,
                                 CFSR_DEBIT_AMOUNT    =  CFSR_DEBIT_AMOUNT   +   V_DEBIT_AMT
                  WHERE   TRUNC(CFSR_TRAN_DATE)  = TRUNC(PRM_INS_DATE)
                   AND           CFSR_CURR_CODE             = PRM_CURR_CODE
                   AND           CFSR_GL_CODE                      = TRIM(PRM_GL_CODE)
                   AND           CFSR_SUBGL_CODE                =  TRIM(PRM_SUBGL_CODE)
                   AND        CFSR_PARAM_KEY                 =    I3.CTD_TRAN_DESC;

                   IF SQL%ROWCOUNT = 0 THEN
                     PRM_ERRMSG := 'Error while updating float data';
                        RETURN;
                   END IF;


               EXCEPTION
               WHEN NO_DATA_FOUND THEN

                            INSERT INTO CMS_FLOAT_SUBGLWISE_REPORT
                              (
                                      CFSR_TRAN_DATE,
                                      CFSR_CURR_CODE,
                             CFSR_PARAM_KEY,
                                      CFSR_GL_CODE,
                                      CFSR_GL_DESC,
                             CFSR_SUBGL_CODE,
                             CFSR_SUBGL_DESC,
                                      CFSR_CREDIT_AMOUNT,
                                      CFSR_DEBIT_AMOUNT
                              )
                              VALUES
                                    ( TRUNC(PRM_INS_DATE ) ,
                                      PRM_CURR_CODE,
                             I3.CTD_TRAN_DESC,
                                     TRIM( PRM_GL_CODE),
                                      PRM_GL_DESC,
                            TRIM( PRM_SUBGL_CODE) ,
                            PRM_SUBGL_DESC,
                                      V_CREDIT_AMT,
                                      V_DEBIT_AMT
                                    );
           WHEN OTHERS THEN
            PRM_ERRMSG := 'Error while updating float data' || SUBSTR(SQLERRM, 1,300) ;
             RETURN;
            END;
         --En select gl entries from float report */
         
         
          BEGIN
               SELECT DECODE (v_tran_type, 'CR', NVL (v_totamt, 0), 0),
                      DECODE (v_tran_type, 'DR', NVL (v_totamt, 0), 0)
                 INTO v_credit_amt,
                      v_debit_amt
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg := 'Error while selecting acct_type';
                  RETURN;
            END;

            --Sn insert a record into float report
            --IF  V_CREDIT_AMT  = 0 AND V_DEBIT_AMT  = 0 THEN

            --NULL;
            --ELSE
            --IF prm_orgnl_tran_type = v_tran_type THEN
            BEGIN
               INSERT INTO cms_float_subglwise_detail
                           (cfsr_tran_date, cfsr_curr_code,
                            cfsr_param_key, cfsr_gl_code,
                            cfsr_gl_desc, cfsr_subgl_code,
                            cfsr_subgl_desc, cfsr_credit_amount,
                            cfsr_debit_amount
                           )
                    VALUES (TRUNC (prm_ins_date), prm_curr_code,
                            i3.ctd_tran_desc, TRIM (prm_gl_code),
                            prm_gl_desc, TRIM (prm_subgl_code),
                            prm_subgl_desc, v_credit_amt,
                            v_debit_amt
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while updating float data'
                     || SUBSTR (SQLERRM, 1, 300);
                  RETURN;
            END;
         EXCEPTION                                   --<< LOOP exception  I3>>
            WHEN OTHERS
            THEN
               prm_errmsg :=
                        'Error from iner loop I3' || SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;
      END LOOP;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'Error  main ' || SUBSTR (SQLERRM, 1, 300);
END;
/


