CREATE OR REPLACE PROCEDURE VMSCMS.prc_test
AS
   v_check          BOOLEAN;
   v_apnd           BOOLEAN;
   v_dum            NUMBER (2);
   v_confg          VARCHAR2 (500);

   TYPE int_ind_type IS TABLE OF VARCHAR (2);

   int_ind_values   int_ind_type   := int_ind_type ('1', 'NS', '0', 'A');

   TYPE pinsign_type IS TABLE OF VARCHAR (2);

   pinsign_values   pinsign_type   := pinsign_type ('P', 'NS', 'S', 'A');
BEGIN
   v_check := TRUE;
   DBMS_OUTPUT.put_line
      ('CARD_APPL_STATUS   TXN_CODE   DEL_CHAN   PROD_CODE   CARD_TYPE   MCC_CODE   INT_IND   PIN_SIGN   STAT_FLAG'
      );

   FOR i IN (SELECT DISTINCT ccs_card_status
                        FROM cms_cardissuance_status
                       WHERE ccs_card_status = 16)
   LOOP
      v_check := FALSE;
      v_confg := NULL;

      BEGIN
         SELECT 1
           INTO v_dum
           FROM gpr_valid_cardstat
          WHERE gvc_card_stat = i.ccs_card_status;

         v_apnd := FALSE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_check := TRUE;
            v_apnd := TRUE;
         WHEN TOO_MANY_ROWS
         THEN
            NULL;
      END;

      FOR j IN (SELECT ctm_tran_code
                  FROM cms_transaction_mast
                 WHERE ctm_tran_code = '11')
      LOOP
         IF v_apnd
         THEN
            NULL;
         ELSE
            BEGIN
               SELECT 1
                 INTO v_dum
                 FROM gpr_valid_cardstat
                WHERE gvc_card_stat = i.ccs_card_status
                  AND gvc_tran_code = j.ctm_tran_code;

               v_apnd := FALSE;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_apnd := TRUE;
                  v_check := TRUE;
               WHEN TOO_MANY_ROWS
               THEN
                  NULL;
            END;
         END IF;

         FOR k IN (SELECT cdm_channel_code
                     FROM cms_delchannel_mast
                    WHERE cdm_channel_code = '08')
         LOOP
            IF v_apnd
            THEN
               NULL;
            ELSE
               BEGIN
                  SELECT 1
                    INTO v_dum
                    FROM gpr_valid_cardstat
                   WHERE gvc_card_stat = i.ccs_card_status
                     AND gvc_tran_code = j.ctm_tran_code
                     AND gvc_delivery_channel = k.cdm_channel_code;

                  v_apnd := FALSE;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_apnd := TRUE;
                     v_check := TRUE;
                  WHEN TOO_MANY_ROWS
                  THEN
                     NULL;
               END;
            END IF;

            FOR l IN (SELECT cpm_prod_code
                        FROM cms_prod_mast
                       WHERE cpm_prod_code = 'AP28')
            LOOP
               IF v_apnd
               THEN
                  NULL;
               ELSE
                  BEGIN
                     SELECT 1
                       INTO v_dum
                       FROM gpr_valid_cardstat
                      WHERE gvc_card_stat = i.ccs_card_status
                        AND gvc_tran_code = j.ctm_tran_code
                        AND gvc_delivery_channel = k.cdm_channel_code
                        AND gvc_prod_code = l.cpm_prod_code;

                     v_apnd := FALSE;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_apnd := TRUE;
                        v_check := TRUE;
                     WHEN TOO_MANY_ROWS
                     THEN
                        NULL;
                  END;
               END IF;

               FOR m IN (SELECT cpc_card_type
                           FROM cms_prod_cattype
                          WHERE cpc_card_type = 1)
               LOOP
                  IF v_apnd
                  THEN
                     NULL;
                  ELSE
                     BEGIN
                        SELECT 1
                          INTO v_dum
                          FROM gpr_valid_cardstat
                         WHERE gvc_card_stat = i.ccs_card_status
                           AND gvc_tran_code = j.ctm_tran_code
                           AND gvc_delivery_channel = k.cdm_channel_code
                           AND gvc_prod_code = l.cpm_prod_code
                           AND gvc_card_type = m.cpc_card_type;

                        v_apnd := FALSE;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_apnd := TRUE;
                           v_check := TRUE;
                        WHEN TOO_MANY_ROWS
                        THEN
                           NULL;
                     END;
                  END IF;

                  FOR n IN (SELECT cmt_mcc_code, cmt_mcc_id
                              FROM cms_mcc_tran
                             WHERE cmt_mcc_id = '1411')
                  LOOP
                     IF v_apnd
                     THEN
                        NULL;
                     ELSE
                        BEGIN
                           SELECT 1
                             INTO v_dum
                             FROM gpr_valid_cardstat
                            WHERE gvc_card_stat = i.ccs_card_status
                              AND gvc_tran_code = j.ctm_tran_code
                              AND gvc_delivery_channel = k.cdm_channel_code
                              AND gvc_prod_code = l.cpm_prod_code
                              AND gvc_card_type = m.cpc_card_type
                              AND gvc_mcc_id = n.cmt_mcc_id;

                           v_apnd := FALSE;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              v_apnd := TRUE;
                              v_check := TRUE;
                           WHEN TOO_MANY_ROWS
                           THEN
                              NULL;
                        END;
                     END IF;

                     FOR o IN 1 .. int_ind_values.COUNT ()
                     LOOP
                        IF v_apnd
                        THEN
                           NULL;
                        ELSE
                           BEGIN
                              SELECT 1
                                INTO v_dum
                                FROM gpr_valid_cardstat
                               WHERE gvc_card_stat = i.ccs_card_status
                                 AND gvc_tran_code = j.ctm_tran_code
                                 AND gvc_delivery_channel = k.cdm_channel_code
                                 AND gvc_prod_code = l.cpm_prod_code
                                 AND gvc_card_type = m.cpc_card_type
                                 AND gvc_mcc_id = n.cmt_mcc_id
                                 AND gvc_int_ind = int_ind_values (o);

                              v_apnd := FALSE;
                           EXCEPTION
                              WHEN NO_DATA_FOUND
                              THEN
                                 v_apnd := TRUE;
                                 v_check := TRUE;
                              WHEN TOO_MANY_ROWS
                              THEN
                                 NULL;
                           END;
                        END IF;

                        FOR p IN 1 .. pinsign_values.COUNT ()
                        LOOP
                           IF v_apnd
                           THEN
                              v_confg :=
                                    LPAD (i.ccs_card_status, 10, '  ')
                                 || LPAD (j.ctm_tran_code, 20, ' ')
                                 || LPAD (k.cdm_channel_code, 11, ' ')
                                 || LPAD (l.cpm_prod_code, 13, ' ')
                                 || LPAD (m.cpc_card_type, 10, ' ')
                                 || LPAD (n.cmt_mcc_code, 15, ' ')
                                 || LPAD (int_ind_values (o), 10, ' ')
                                 || LPAD (pinsign_values (p), 10, ' ')
                                 || LPAD ('A', 10, ' ');
                           ELSE
                              BEGIN
                                 SELECT 1
                                   INTO v_dum
                                   FROM gpr_valid_cardstat
                                  WHERE gvc_card_stat = i.ccs_card_status
                                    AND gvc_tran_code = j.ctm_tran_code
                                    AND gvc_delivery_channel =
                                                            k.cdm_channel_code
                                    AND gvc_prod_code = l.cpm_prod_code
                                    AND gvc_card_type = m.cpc_card_type
                                    AND gvc_mcc_id = n.cmt_mcc_id
                                    AND gvc_int_ind = int_ind_values (o)
                                    AND gvc_pinsign = pinsign_values (p);

                                 v_apnd := FALSE;
                              EXCEPTION
                                 WHEN NO_DATA_FOUND
                                 THEN
                                    v_apnd := TRUE;
                                    v_check := TRUE;
                                 WHEN TOO_MANY_ROWS
                                 THEN
                                    NULL;
                              END;
                           END IF;

                           IF v_check
                           THEN
                              DBMS_OUTPUT.put_line (v_confg);
                           END IF;
                        END LOOP;
                     END LOOP;
                  END LOOP;
               END LOOP;
            END LOOP;
         END LOOP;
      END LOOP;
   END LOOP;

   DBMS_OUTPUT.put_line ('OK');
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.put_line ('Error');
END;
/

SHOW ERRORS;


