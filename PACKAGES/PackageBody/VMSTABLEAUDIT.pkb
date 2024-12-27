create or replace
PACKAGE BODY        VMSCMS.vmstableaudit
IS
   -- Private type declarations

   -- Private constant declarations

   -- Private variable declarations

   -- Function and procedure implementations
   --PROCEDURE which builds a trigger on a table at run time..
   
   
/************************************************************************************************************

    * Modified by      : Venkata Naga Sai.S
    * Modified Date    : 02-April-2019
    * Modified For     : VMS-843
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR14_B0002 
	
*****************************************************************************************************************/
   
   
   
   
    PROCEDURE generate_audit_trg (p_grp_id_in          NUMBER,
                                 p_audt_flag          VARCHAR2,
                                 p_resp_msg_out   OUT VARCHAR2)
    AS
        L_TNAME                varchar2 (30);
        l_trgname              VARCHAR2 (30);
        L_TRIGGER              varchar2 (32767);
        L_TRIGGER_BODY         varchar2 (32767);
        L_TRIGGER_COLS         VARCHAR2 (32767);
        L_TRIGGER_INSERT       VARCHAR2 (32767);
        l_trigger_update       VARCHAR2 (32767);
        l_uniqueid             VARCHAR2 (32767);
        l_insuser              VARCHAR2 (30);
        l_lupduser             VARCHAR2 (30);
        l_crlf                 VARCHAR2 (2) := CHR (10);
        l_cnt                  NUMBER := 0;
        v_final_string         CLOB;
        l_trigger_declare      VARCHAR2 (32767) :=    'FOR EACH ROW '
            || l_crlf
            || 'DECLARE'
            || l_crlf
            || 'l_errmsg      VARCHAR2 (500) := ''0K'';'
            || l_crlf
            || 'l_action     VARCHAR2(2);'
            || l_crlf
            || 'l_tbl_id      NUMBER (5);'
            || l_crlf
            || 'l_user      NUMBER (5);'
            || l_crlf
            || 'l_unique_id  VARCHAR2(1000);'
            || l_crlf
            || 'excp_error    EXCEPTION;'
            || l_crlf
            || 'TYPE rec_trg_info IS RECORD'
            || l_crlf
            || '('
            || l_crlf
            || 'col_name    VARCHAR2 (60),'
            || l_crlf
            || 'old_value   clob,'
            || l_crlf
            || 'new_value   clob'
            || l_crlf
            || ');'
            || l_crlf
            || 'TYPE tab_trg_info IS TABLE OF rec_trg_info INDEX BY BINARY_INTEGER;'
            || l_crlf
            || ' l_trg_info    tab_trg_info;';
        l_loop                 VARCHAR2 (32767) :=    'FOR l_row_idx IN 1 .. l_trg_info.COUNT'
            || l_crlf
            || 'LOOP'
            || l_crlf
            || 'IF (l_action = ''U'' AND (NVL (l_trg_info (l_row_idx).old_value, ''0'') <> NVL (l_trg_info (l_row_idx).new_value, ''0''))) OR l_action = ''I'' OR  l_action = ''D''  THEN'
            || l_crlf
            || 'BEGIN'
            || l_crlf
            || 'INSERT INTO VMS_TABLEAUDT_INFO (vti_tbl_id, vti_unique_id, vti_col_name,vti_old_val, vti_new_val, vti_action_type, vti_action_user, vti_action_date )'
            || l_crlf
            || 'VALUES (l_tbl_id, l_unique_id,  l_trg_info (l_row_idx).col_name, TO_CHAR (l_trg_info (l_row_idx).old_value), TO_CHAR (l_trg_info (l_row_idx).new_value), l_action, nvl(l_user,1), SYSDATE);'
            || l_crlf
            || 'EXCEPTION'
            || l_crlf
            || 'WHEN OTHERS THEN'
            || l_crlf
            || 'l_errmsg := ''While populating audit info-'' || SUBSTR (SQLERRM, 1, 250);'
            || l_crlf
            || 'RAISE excp_error;'
            || l_crlf
            || 'END;'
            || l_crlf
            || 'END IF;'
            || l_crlf
            || 'END LOOP;';
        l_trigger_excp         VARCHAR2 (32767) :=    'EXCEPTION'
            || l_crlf
            || 'WHEN excp_error THEN'
            || l_crlf
            || 'raise_application_error (-20001, ''Error - '' || l_errmsg);'
            || l_crlf
            || 'WHEN OTHERS THEN'
            || l_crlf
            || 'l_errmsg := ''Main Error  - '' || SUBSTR (SQLERRM, 1, 250);'
            || l_crlf
            || 'raise_application_error (-20002, l_errmsg);'
            || l_crlf
            || 'END;';

        PROCEDURE lp_create_trg (lp_tname_in           VARCHAR2,
                           lp_trgname_in         VARCHAR2,
                           lp_cnt_in             NUMBER,
                           lp_final_str_in       CLOB,
                           lp_resp_meg_out   OUT VARCHAR2)
        IS
        l_old_trg   CLOB;
        l_chk_trg   NUMBER;
        PRAGMA AUTONOMOUS_TRANSACTION;
            
        BEGIN
            lp_resp_meg_out := 'OK';

        BEGIN
            SELECT COUNT (1)
              INTO l_chk_trg
              FROM user_triggers
             WHERE table_name = lp_tname_in AND trigger_name = lp_trgname_in;

            IF l_chk_trg <> 0 THEN
               SELECT DBMS_METADATA.get_ddl ('TRIGGER', lp_trgname_in)
                 INTO l_old_trg
                 FROM DUAL;

               EXECUTE IMMEDIATE 'DROP TRIGGER VMSCMS.' || lp_trgname_in;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
               lp_resp_meg_out :='Error while dropping old trigger  - '|| SUBSTR (SQLERRM, 1, 250);
               RETURN;
        END;
                         
        IF lp_cnt_in = 0 THEN
            RETURN;
        END IF;

        BEGIN
            execute immediate LP_FINAL_STR_IN;
                         
        EXCEPTION
            when OTHERS then
                lp_resp_meg_out :='Error while creating trigger - '|| SUBSTR (SQLERRM, 1, 250);

                EXECUTE IMMEDIATE 'DROP TRIGGER VMSCMS.' || lp_trgname_in;

                IF l_chk_trg <> 0 THEN
                    EXECUTE IMMEDIATE l_old_trg;
                END IF;

                RETURN;
        END;

        BEGIN
            SELECT text
              INTO lp_resp_meg_out
              FROM user_errors
             WHERE NAME = lp_trgname_in AND TYPE = 'TRIGGER';

            EXECUTE IMMEDIATE 'DROP TRIGGER VMSCMS.' || lp_trgname_in;

            IF l_chk_trg <> 0 THEN
               EXECUTE IMMEDIATE l_old_trg;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               lp_resp_meg_out := 'OK';
            END;
        EXCEPTION
    WHEN OTHERS THEN
        lp_resp_meg_out :='lp_create_trg Main Error  - ' || SUBSTR (SQLERRM, 1, 250);
    END lp_create_trg;
        
    BEGIN
        p_resp_msg_out := 'OK';

        FOR l_grprow_idx IN (SELECT vtm_tbl_id, vtm_tbl_name, vtm_unique_id
                                FROM vms_tableaudt_mast
                               WHERE vtm_grp_id = p_grp_id_in)
        LOOP
            BEGIN
                l_trgname := substr('TRG_AUDT' || SUBSTR (l_grprow_idx.vtm_tbl_name, 5),1,30);

                IF p_audt_flag = 'N' THEN
                    lp_create_trg (l_grprow_idx.vtm_tbl_name,
                                    l_trgname,
                                    0,
                                    v_final_string,
                                    p_resp_msg_out);
                ELSE
                    l_trigger := 'CREATE OR REPLACE TRIGGER VMSCMS.'
                        || l_trgname
                        || l_crlf
                        || 'AFTER INSERT OR UPDATE  OR DELETE ON  '
                        || l_crlf
                        || 'vmscms.'
                        || l_grprow_idx.vtm_tbl_name;
                                                          
                    l_trigger_body :='BEGIN'
                        || l_crlf
                        || 'l_tbl_id:='
                        || l_grprow_idx.vtm_tbl_id
                        || ';';
                              
                    IF INSTR (l_grprow_idx.vtm_unique_id, '~') > 0 THEN
                        FOR l_idx IN
                        (SELECT     REGEXP_SUBSTR(l_grprow_idx.vtm_unique_id,'[^~]+',1,LEVEL) AS colmn
                        FROM DUAL
                        CONNECT BY REGEXP_SUBSTR (l_grprow_idx.vtm_unique_id,'[^~]+',1,LEVEL) IS NOT NULL)
                        LOOP
                            IF l_uniqueid IS NULL THEN
                                l_uniqueid := ':NEW.' || l_idx.colmn;
                            ELSE
                                l_uniqueid := l_uniqueid || '||''~''||' || ':NEW.' || l_idx.colmn;
                            END IF;
                        END LOOP;    
                    ELSE
                   --     l_uniqueid := ':OLD.' || l_grprow_idx.vtm_unique_id;  
                    l_uniqueid := ':NEW.' || l_grprow_idx.vtm_unique_id; 
                    END IF;
                               
                    BEGIN
                        FOR l_row_idx
                        IN (SELECT * FROM vms_tableaudt_dictionary
                        WHERE vtd_tbl_id = l_grprow_idx.vtm_tbl_id)
                        LOOP
                            l_cnt := l_cnt + 1;
                            l_trigger_cols :=l_trigger_cols
                                || 'l_trg_info ('
                                || l_cnt
                                || ').col_name:='''
                                || UPPER (l_row_idx.vtd_col_name)
                                || ''';'
                                || l_crlf;

                            l_trigger_insert :=l_trigger_insert
                                || 'l_trg_info ('
                                || l_cnt
                                || ').new_value:=to_clob(:NEW.'
                                || l_row_idx.vtd_col_name
                                || ');'
                                || l_crlf;
                            l_trigger_update :=l_trigger_update
                                || 'l_trg_info ('
                                || l_cnt
                                || ').old_value:=to_clob(:OLD.'
                                || l_row_idx.vtd_col_name
                                || ');'
                                || l_crlf;
                        END LOOP;
                    EXCEPTION
                        WHEN OTHERS THEN
                            p_resp_msg_out :='Error while preparing column list  - '|| SUBSTR (SQLERRM, 1, 250);
                            RETURN;
                    END;

                    FOR l_row_idx
                        IN (SELECT column_name
                        FROM user_tab_cols
                        WHERE table_name = l_grprow_idx.vtm_tbl_name
                        AND (column_name LIKE '%INS_USER'
                        OR column_name LIKE '%LUPD_USER'))
                    LOOP
                        IF INSTR (l_row_idx.column_name, 'INS') > 0 THEN
                            l_insuser := l_row_idx.column_name;
                        ELSIF INSTR (l_row_idx.column_name, 'LUPD') > 0 THEN
                            l_lupduser := l_row_idx.column_name;
                        END IF;
                    END LOOP;

                    l_trigger_body :=l_trigger_body
                        || l_crlf
                        || l_trigger_cols
                        || l_crlf
                        || 'IF INSERTING THEN'
                        || l_crlf
                        || 'l_action:=''I'';'
                        || l_crlf
                        || 'l_unique_id :='||l_uniqueid||';'
                        || l_crlf
                        || l_trigger_insert
                        || l_crlf
                        || CASE WHEN l_insuser IS NOT NULL THEN
                        'l_user:=:NEW.' || l_insuser || ';' || l_crlf
                        END
                        || 'END IF;'
                        || l_crlf
                        || 'IF UPDATING THEN'
                        || l_crlf
                        || 'l_action:=''U'';'
                        || l_crlf
                        || 'l_unique_id :='||l_uniqueid||';'
                        || l_crlf
                        || l_trigger_update
                        || l_crlf
                        || l_trigger_insert
                        || l_crlf
                        || CASE WHEN l_lupduser IS NOT NULL THEN
                        'l_user:=:NEW.' || l_lupduser || ';' || l_crlf
                        END
                        || 'END IF;'
                        || l_crlf
                        || 'IF DELETING THEN'
                        || l_crlf
                        || 'l_action:=''D'';'
                        || l_crlf
                        || 'l_unique_id :='||replace(l_uniqueid,':NEW.',':OLD.')||';'
                        || l_crlf
                        || l_trigger_update
                        || l_crlf
                        || CASE WHEN l_lupduser IS NOT NULL THEN
                        'l_user:=:OLD.' || l_lupduser || ';' || l_crlf
                        END
                        || 'END IF;';

                    v_final_string :=l_trigger
                        || l_crlf
                        || l_trigger_declare
                        || l_crlf
                        || l_trigger_body
                        || l_crlf
                        || l_loop
                        || l_crlf
                        || l_trigger_excp;

                    lp_create_trg (l_grprow_idx.vtm_tbl_name,
                                l_trgname,
                                l_cnt,
                                v_final_string,
                                p_resp_msg_out);
                                
                    IF p_resp_msg_out <> 'OK' THEN
                        RETURN;
                    END IF;
                END IF;
                            
                l_uniqueid:=NULL;
                l_trigger_cols:=NULL;  
                l_trigger_body:=NULL;
                v_final_string:=NULL;
                l_trigger_insert:=NULL;
                l_trigger_update:=NULL;
                l_insuser:=NULL;
                l_lupduser:=NULL;
                l_cnt:=0;
            EXCEPTION
                WHEN OTHERS THEN
                p_resp_msg_out :='Error in main loop  - '|| SUBSTR (SQLERRM, 1, 250);
                RETURN;
            END;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            p_resp_msg_out := 'Main Error  - ' || SUBSTR (SQLERRM, 1, 250);
    END generate_audit_trg;
END vmstableaudit; 
/
SHOW ERROR