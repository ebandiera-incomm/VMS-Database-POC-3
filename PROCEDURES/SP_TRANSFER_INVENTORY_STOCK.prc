CREATE OR REPLACE PROCEDURE VMSCMS.sp_transfer_inventory_stock (
   prm_inst_code           NUMBER,
   prm_ordr_refrno         VARCHAR2,
   prm_ins_user            NUMBER,
   prm_err_msg       OUT   VARCHAR2
)
IS

   /*************************************************
       * Created Date     :  19-June-2012
       * Created By       : Ganesh Shekade
       * PURPOSE          : For Inventory Stock Transafer 
       * Modified By      : Dhiraj G
       * Modified Date    : 8-Aug-2012
       * Modified Reason  : Store id changes for MMPOS activation
       * Reviewer         :
       * Reviewed Date    :
       * Build  No.       : RI0013.1_B0003
       
       * Created Date     : 23-05-2014
       * Created By       : MageshKumar S
       * PURPOSE          : MVHOST-898
       * Reviewer         : spankaj
       * Build  No.       : RI0027.3_B0001
   *************************************************/
   v_crd_cnt          cms_merinv_transfer.cmt_nocards_transafer%TYPE;
   v_from_locn        cms_merinv_transfer.cmt_from_location%TYPE;
   v_to_locn          cms_merinv_transfer.cmt_to_location%TYPE;
   v_card_quantity    cms_merinv_transfer.cmt_nocards_transafer%TYPE;
   v_from_card_no     cms_merinv_transfer.cmt_from_cardno%TYPE;
   v_to_card_no       cms_merinv_transfer.cmt_to_cardno%TYPE;
   v_fromlocn_stock   cms_merinv_stock.cms_curr_stock%TYPE;
   v_tolocn_stock     cms_merinv_stock.cms_curr_stock%TYPE;
   v_mer_id           cms_merinv_prodcat.cmp_mer_id%TYPE;
   v_merprodcat_id    cms_merinv_transfer.cmt_merprodcat_id%TYPE;
   v_from_proxy_no    cms_merinv_transfer.CMT_FROM_PROXYNO%TYPE;
   v_to_proxy_no      cms_merinv_transfer.CMT_TO_PROXYNO%TYPE;
BEGIN
   prm_err_msg := 'OK';

   BEGIN
      SELECT cmt_nocards_transafer, cmt_from_location, cmt_to_location,
             TRIM (cmt_from_cardno), TRIM (cmt_to_cardno), cmp_mer_id,
             cmt_merprodcat_id, CMT_FROM_PROXYNO, CMT_TO_PROXYNO
        INTO v_crd_cnt, v_from_locn, v_to_locn,
             v_from_card_no, v_to_card_no, v_mer_id,
             v_merprodcat_id, v_from_proxy_no, v_to_proxy_no -- ADded for MVHOST-898
        FROM cms_merinv_transfer, cms_merinv_prodcat
       WHERE cmt_inst_code = prm_inst_code
         AND cmt_authorize_flag = 'A'
         AND cmt_process_flag = 'N'
         AND cmp_merprodcat_id  = cmt_merprodcat_id
         AND cmt_ordr_refrno = prm_ordr_refrno;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_err_msg := 'Invalid Order Reference Number ';
         RETURN;
      WHEN OTHERS
      THEN
         prm_err_msg :=
               'Error while selecting merchant detail from merchant inventory transfer for  '
            || v_merprodcat_id
            || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   BEGIN
      SELECT cms_curr_stock
        INTO v_fromlocn_stock
        FROM cms_merinv_stock
       WHERE cms_inst_code = prm_inst_code
         AND cms_location_id = v_from_locn
         AND cms_merprodcat_id = v_merprodcat_id;

      IF v_fromlocn_stock >= v_crd_cnt
      THEN
         UPDATE cms_merinv_stock
            SET cms_curr_stock = cms_curr_stock - v_crd_cnt
          WHERE cms_inst_code = prm_inst_code
            AND cms_location_id = v_from_locn
            AND cms_merprodcat_id = v_merprodcat_id;

         IF SQL%ROWCOUNT = 0
         THEN
            prm_err_msg :=
               'Error while updating stock in merchant inventory stock for from location ';
            RETURN;
         END IF;
      ELSE
         prm_err_msg :=
               'Requested no of stock not avilable in from location  '
            || v_from_locn;
         RETURN;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_err_msg := 'From location does not exist  ';
         RETURN;
      WHEN OTHERS
      THEN
         prm_err_msg :=
               'Error while selecting merchant detail from merchant inventory stock for  '
            || v_merprodcat_id
            || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   BEGIN
      SELECT cms_curr_stock
        INTO v_tolocn_stock
        FROM cms_merinv_stock
       WHERE cms_inst_code = prm_inst_code
         AND cms_location_id = v_to_locn
         AND cms_merprodcat_id = v_merprodcat_id;

      UPDATE cms_merinv_stock
         SET cms_curr_stock = cms_curr_stock + v_crd_cnt
       WHERE cms_inst_code = prm_inst_code
         AND cms_location_id = v_to_locn
         AND cms_merprodcat_id = v_merprodcat_id;

      IF SQL%ROWCOUNT = 0
      THEN
         prm_err_msg :=
            'Error while updating stock in merchant inventory stock for to location ';
         RETURN;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_err_msg := 'To location does not exist  ';
         RETURN;
      WHEN OTHERS
      THEN
         prm_err_msg :=
               'Error while selecting merchant detail from merchant inventory stock for  '
            || v_merprodcat_id
            || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;
  if (v_from_proxy_no is null) THEN -- ADDED for MVHOST-898
     BEGIN
      FOR i IN
         (SELECT a.ROWID row_id ,CMM_APPL_CODE
            FROM cms_merinv_merpan a
           WHERE SUBSTR (fn_dmaps_main (cmm_pancode_encr),1,LENGTH (fn_dmaps_main (cmm_pancode_encr)) - 1) 
                        BETWEEN SUBSTR (v_from_card_no,1,LENGTH (v_from_card_no) - 1)
                              AND SUBSTR (v_to_card_no,1,LENGTH (v_to_card_no) - 1)
             AND trunc(cmm_expiry_date) > TRUNC (SYSDATE)
             AND cmm_mer_id = v_mer_id
             AND cmm_location_id = v_from_locn)
      LOOP
         BEGIN
            UPDATE cms_merinv_merpan b
               SET cmm_location_id = v_to_locn,
                   CMM_TORDR_REFRNO = prm_ordr_refrno
             WHERE b.ROWID = i.row_id;

            IF SQL%ROWCOUNT = 0
            THEN
               prm_err_msg :=
                     'No rows updated while merchant inventory details update for location  '
                  || v_to_locn;
               RETURN;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_err_msg :=
                     'Error while updating merchant inventory details for location  '
                  || v_to_locn
                  || ' as '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
            -- Start Added on 080821012 for Store Id Change CR  
         BEGIN
            UPDATE cms_caf_info_entry b
               set CCI_STORE_ID = V_TO_LOCN
             where CCI_APPL_CODE = to_char(I.CMM_APPL_CODE) ; --to_char added for number to varchar2 changes
             --and cci_file_name = prm_ordr_refrno ;
      

            IF SQL%ROWCOUNT = 0
            THEN
               prm_err_msg :=
                     'No rows updated while Caf info inventory inventory details update for Store Id  '
                  || v_to_locn;
               RETURN;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_err_msg :=
                     'Error while updating Caf info inventory inventory details update for Store Id  '
                  || v_to_locn
                  || ' as '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
         -- End  Added on 080821012 for Store Id Change CR
         
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_err_msg :=
               'Eror whilw updating inventory details '
            || SUBSTR (SQLERRM, 1, 300);
   END;
  ELSE
   BEGIN
      FOR i IN
         (SELECT a.ROWID row_id ,CMM_APPL_CODE
            FROM cms_merinv_merpan a, cms_appl_pan b
       WHERE  a.cmm_pan_code = b.cap_pan_code
            and a.CMM_INST_CODE = b.CAP_INST_CODE
            AND  to_number(b.cap_proxy_number) between  v_from_proxy_no and v_to_proxy_no
             AND trunc(cmm_expiry_date) > TRUNC (SYSDATE)
             AND cmm_mer_id = v_mer_id
             AND cmm_location_id = v_from_locn)
      LOOP
         BEGIN
            UPDATE cms_merinv_merpan b
               SET cmm_location_id = v_to_locn,
                   CMM_TORDR_REFRNO = prm_ordr_refrno
             WHERE b.ROWID = i.row_id;

            IF SQL%ROWCOUNT = 0
            THEN
               prm_err_msg :=
                     'No rows updated while merchant inventory details update for location  '
                  || v_to_locn;
               RETURN;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_err_msg :=
                     'Error while updating merchant inventory details for location  '
                  || v_to_locn
                  || ' as '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
            -- Start Added on 080821012 for Store Id Change CR  
         BEGIN
            UPDATE cms_caf_info_entry b
               set CCI_STORE_ID = V_TO_LOCN
             where CCI_APPL_CODE = to_char(I.CMM_APPL_CODE) ; --to_char added for number to varchar2 changes
             --and cci_file_name = prm_ordr_refrno ;
      

            IF SQL%ROWCOUNT = 0
            THEN
               prm_err_msg :=
                     'No rows updated while Caf info inventory inventory details update for Store Id  '
                  || v_to_locn;
               RETURN;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_err_msg :=
                     'Error while updating Caf info inventory inventory details update for Store Id  '
                  || v_to_locn
                  || ' as '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
         -- End  Added on 080821012 for Store Id Change CR
         
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_err_msg :=
               'Eror whilw updating inventory details '
            || SUBSTR (SQLERRM, 1, 300);
   END;
  END IF; --MVHOST-898
   BEGIN
      UPDATE cms_merinv_transfer
         SET cmt_process_flag = 'P'
       WHERE cmt_inst_code = prm_inst_code
         AND cmt_authorize_flag = 'A'
         AND cmt_process_flag = 'N'
         AND cmt_merprodcat_id = v_merprodcat_id
         AND cmt_ordr_refrno = prm_ordr_refrno;

      IF SQL%ROWCOUNT = 0
      THEN
         prm_err_msg :=
            'Process flag not updated for merprod cat id ' || v_merprodcat_id;
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_err_msg :=
               'Error while updating process flag for merprod cat id   '
            || v_merprodcat_id
            || ' as '
            || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_err_msg :=
            'Error from main procedure for merchant inventory stock transfer '
         || SUBSTR (SQLERRM, 1, 300);
END;
/
show error;