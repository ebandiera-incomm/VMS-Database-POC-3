CREATE OR REPLACE PROCEDURE vmscms.update_card_id(p_hour_in number) IS
    l_start_time          DATE;
BEGIN
    l_start_time := sysdate;

    LOOP
        FOR l_row_idx IN ( SELECT ROWID rid FROM cms_appl_pan
                                        WHERE cap_card_id IS NULL AND ROWNUM <= 1000)
        LOOP
                BEGIN
                    UPDATE cms_appl_pan
                    SET cap_card_id=LPAD(seq_card_id.nextval,12,'0')
                    WHERE rowid=l_row_idx.rid;
                EXCEPTION
                    WHEN OTHERS THEN
                        ROLLBACK;
                END;
                COMMIT;
        END LOOP;

        IF  ROUND(SYSDATE-l_start_time,2) > round(p_hour_in/24,2) THEN
            EXIT;
        END IF;
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;
/
show error