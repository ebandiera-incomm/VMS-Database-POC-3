CREATE OR REPLACE
PROCEDURE                               vmscms.update_partner_id(p_hour_in IN NUMBER,p_rownum_in IN NUMBER,p_null_prod_in in varchar2) IS
    l_prod_code           cms_appl_pan.cap_prod_code%TYPE;
    exp_reject_record     EXCEPTION;
    l_err_msg             VARCHAR2(500);
    l_start_time          DATE;
BEGIN

    l_start_time := sysdate;
    
    LOOP
        FOR I_IDX IN ( SELECT * FROM CMS_CUST_MAST WHERE CCM_PARTNER_ID IS NULL 
        AND CCM_CUST_CODE IN (SELECT CAP_CUST_CODE FROM CMS_APPL_PAN)
        AND  ROWNUM <=p_rownum_in)
        LOOP
            BEGIN

                BEGIN
                    SELECT cap_prod_code
                    INTO l_prod_code
                    FROM( SELECT cap_prod_code
                            FROM  cms_appl_pan
                            WHERE cap_cust_code =i_idx.ccm_cust_code
                            AND cap_inst_code      = 1
                            AND cap_active_date   IS NOT NULL
                            AND cap_card_stat <>'9'
                            ORDER BY cap_active_date DESC)
                    WHERE ROWNUM=1;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        BEGIN
                            SELECT cap_prod_code
                            INTO l_prod_code
                            FROM (SELECT cap_prod_code
                                  FROM cms_appl_pan
                                  WHERE cap_cust_code =i_idx.ccm_cust_code
                                  AND cap_inst_code      = 1
                                  ORDER BY cap_pangen_date DESC)
                            WHERE ROWNUM=1;
                        EXCEPTION
                            WHEN OTHERS THEN
                                l_err_msg   := 'Error while selecting the prod code '||SUBSTR(SQLERRM, 1, 200);
                                RAISE exp_reject_record;
                        END;
                    WHEN OTHERS THEN
                         l_err_msg := 'Error while selecting the product code'||substr(SQLERRM,1,200);
                         RAISE exp_reject_record;
                END;
                BEGIN
                    UPDATE cms_cust_mast
                      SET ccm_partner_id=
                        CASE
                          WHEN l_prod_code IN ('MP51','MP52','MP53','MP54','MP56', 'XP02','XP03','XP04','VP72','VP74','VP76','VP79')
                          THEN 1
                          WHEN l_prod_code='VP75'
                          THEN 2
                          WHEN l_prod_code='VP73'
                          THEN 3
                          WHEN l_prod_code IN ('VP77','VP78','MP55')
                          THEN 7
                          WHEN l_prod_code='MP01'
                          THEN 8
                        END,
                    ccm_lupd_date=SYSDATE
                    WHERE ccm_cust_code=i_idx.ccm_cust_code
                    AND ccm_inst_code=1;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_err_msg := 'Error while updating partner id'||substr(SQLERRM,1,200);
                        RAISE exp_reject_record;
                END;
                
                COMMIT;
                
            EXCEPTION
                WHEN exp_reject_record THEN
                    ROLLBACK;
                WHEN OTHERS THEN
                    ROLLBACK;
            END;
            
        END LOOP;
         
        IF  ROUND(SYSDATE-l_start_time,2) > round(p_hour_in/24,2) THEN
            EXIT;
        END IF;
        
        IF upper(p_null_prod_in)='Y' THEN
                FOR i_idx IN (SELECT DISTINCT CUSTOMER_CARD_NO FROM TRANSACTIONLOG WHERE 
                           CUSTOMER_CARD_NO IS NOT NULL AND PARTNER_ID IS NULL AND LENGTH(CUSTOMER_CARD_NO) > 16
                          and productid is null and CUSTOMER_CARD_NO in (select cap_pan_code from cms_appl_pan)
                           and ROWNUM<=p_rownum_in)
                LOOP
                BEGIN
                    BEGIN
                        SELECT cap_prod_code
                        INTO l_prod_code
                        FROM cms_appl_pan
                        WHERE cap_pan_code=i_idx.CUSTOMER_CARD_NO
                        AND cap_inst_code=1;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_err_msg := 'Error while selecting product code'||substr(SQLERRM,1,200);
                            RAISE exp_reject_record;
                        
                    END;
                    BEGIN
                        UPDATE transactionlog
                        SET partner_id=
                          CASE
                            WHEN l_prod_code IN ('MP51','MP52','MP53','MP54','MP56', 'XP02','XP03','XP04','VP72','VP74','VP76','VP79')
                            THEN 1
                            WHEN l_prod_code ='VP75'
                            THEN 2
                            WHEN l_prod_code ='VP73'
                            THEN 3
                            WHEN l_prod_code  IN ('VP77','VP78','MP55')
                            THEN 7
                            WHEN l_prod_code ='MP01'
                            THEN 8
                          END,
                        add_lupd_date=SYSDATE
                        WHERE customer_card_no=i_idx.customer_card_no;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_err_msg := 'Error while updating the transactionlog'||substr(SQLERRM,1,200);
                            RAISE exp_reject_record;
                    END; 
                EXCEPTION
                    WHEN  exp_reject_record THEN
                        ROLLBACK;
                    WHEN others THEN
                        ROLLBACK;  
                END;
                COMMIT;
              END LOOP; 
        END IF;
        
        
        IF upper(p_null_prod_in)='N' THEN
            FOR i_idx IN (SELECT DISTINCT CUSTOMER_CARD_NO,productid FROM TRANSACTIONLOG WHERE 
                           CUSTOMER_CARD_NO IS NOT NULL AND PARTNER_ID IS NULL AND LENGTH(CUSTOMER_CARD_NO) > 16
                          and productid is not null and ROWNUM<=p_rownum_in)
            LOOP
                begin
                        
                    BEGIN
                        UPDATE transactionlog
                        SET partner_id=
                          CASE
                            WHEN i_idx.productid IN ('MP51','MP52','MP53','MP54','MP56', 'XP02','XP03','XP04','VP72','VP74','VP76','VP79')
                            THEN 1
                            WHEN i_idx.productid ='VP75'
                            THEN 2
                            WHEN i_idx.productid ='VP73'
                            THEN 3
                            WHEN i_idx.productid  IN ('VP77','VP78','MP55')
                            THEN 7
                            WHEN i_idx.productid ='MP01'
                            THEN 8
                          END,
                        add_lupd_date=SYSDATE
                        WHERE customer_card_no=i_idx.customer_card_no;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_err_msg := 'Error while updating the transactionlog'||substr(SQLERRM,1,200);
                            RAISE exp_reject_record;
                    END; 
                EXCEPTION
                    WHEN  exp_reject_record THEN
                        ROLLBACK;
                    WHEN others THEN
                        ROLLBACK;  
                END;
                COMMIT;
            END LOOP; 
        END IF;
        
        
        IF  ROUND(SYSDATE-L_START_TIME,2) > ROUND(P_HOUR_IN/24,2) THEN
            EXIT;
        END IF;
        
        FOR I_IDX IN (SELECT distinct CCM_PAN_CODE FROM CMS_CALLLOG_MAST 
        WHERE CCM_PARTNER_ID IS NULL
        AND CCM_PAN_CODE in (select cap_pan_code from cms_appl_pan)
        AND LENGTH(CCM_PAN_CODE) > 16
        and ROWNUM<=p_rownum_in
        )
        LOOP
            BEGIN
                  BEGIN
                        SELECT cap_prod_code
                        INTO l_prod_code
                        FROM cms_appl_pan
                        WHERE cap_pan_code=i_idx.CCM_PAN_CODE
                        AND cap_inst_code=1;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_err_msg := 'Error while selecting product code'||substr(SQLERRM,1,200);
                            RAISE exp_reject_record;
                    END;
                    BEGIN
                        UPDATE cms_calllog_mast
                        SET ccm_partner_id=
                          CASE
                            WHEN l_prod_code IN ('MP51','MP52','MP53','MP54','MP56', 'XP02','XP03','XP04','VP72','VP74','VP76','VP79')
                            THEN 1
                            WHEN l_prod_code='VP75'
                            THEN 2
                            WHEN l_prod_code='VP73'
                            THEN 3
                            WHEN l_prod_code IN ('VP77','VP78','MP55')
                            THEN 7
                            WHEN l_prod_code='MP01'
                            THEN 8
                            END,
                        ccm_lupd_date=sysdate
                        WHERE ccm_pan_code=i_idx.CCM_PAN_CODE
                        AND ccm_inst_code=1;
                    EXCEPTION
                        WHEN others THEN
                            l_err_msg := 'Error while updating the cms_calllog_mast'||substr(SQLERRM,1,200);
                            RAISE exp_reject_record;
                    END;
                
                BEGIN
                    UPDATE cms_calllog_details
                    SET ccd_partner_id=CASE
                          WHEN l_prod_code IN ('MP51','MP52','MP53','MP54','MP56', 'XP02','XP03','XP04','VP72','VP74','VP76','VP79')
                          THEN 1
                          WHEN l_prod_code='VP75'
                          THEN 2
                          WHEN l_prod_code='VP73'
                          THEN 3
                          WHEN l_prod_code IN ('VP77','VP78','MP55')
                          THEN 7
                          WHEN l_prod_code='MP01'
                          THEN 8
                          end,
                    ccd_lupd_date=sysdate
                    WHERE ccd_pan_code=i_idx.CCM_PAN_CODE
                    AND ccd_inst_code=1;
                EXCEPTION
                    WHEN others THEN
                        l_err_msg := 'Error while updating the cms_calllog_mast'||substr(SQLERRM,1,200);
                        RAISE exp_reject_record;
                END;
                
            EXCEPTION
                WHEN  exp_reject_record THEN
                    ROLLBACK;
                WHEN others THEN
                    ROLLBACK;  
            END;

            COMMIT;
        END LOOP; 
        
        IF  ROUND(SYSDATE-L_START_TIME,2) > ROUND(P_HOUR_IN/24,2) THEN
        
            EXIT;
        END IF;
        
    END LOOP;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        l_err_msg := 'Error from main'||substr(SQLERRM,1,200);
        dbms_output.put_line(l_err_msg);
END;
/
show error