create or replace
PACKAGE body vmscms.VMSRULE
AS
    PROCEDURE INSERT_RULE(
        p_rule_id_in     IN NUMBER,
        P_RULE_NAME_IN   IN VARCHAR2,
        P_RULE_EXP_IN    IN VARCHAR2,
        P_TRANS_TYPE_IN  IN VARCHAR2,
        P_ACTION_TYPE_IN IN VARCHAR2,
        p_json_req_in in clob,
        P_RULE_DETAIL_IN IN RULE_TYPE_TAB,
        p_user_in in number,
        p_resp_msg_out OUT VARCHAR2)
    AS
      v_rule_id VMS_RULE_MAST.VRM_RULE_ID%type;
    BEGIN
      p_resp_msg_out  :='OK';
      IF P_RULE_ID_IN IS NULL THEN
        BEGIN
            SELECT nvl(MAX(VRM_RULE_ID),0)+1
            INTO V_RULE_ID
            FROM VMS_RULE_MAST;
        EXCEPTION
        WHEN OTHERS THEN
          p_resp_msg_out:='Error while getting rule id'||SUBSTR(sqlerrm,1,200);
          return;
        END;
        BEGIN
          INSERT
          INTO VMS_RULE_MAST
            (
              VRM_RULE_ID,
              VRM_RULE_NAME,
              VRM_RULE_EXP,
              VRM_TRANSACTION_TYPE,
              VRM_ACTION_TYPE,
              vrm_json_req,
              VRM_INS_USER,
              VRM_INS_DATE
            )
            VALUES
            (
              V_RULE_ID,
              upper(P_RULE_NAME_IN),
              P_RULE_EXP_IN,
              P_TRANS_TYPE_IN,
              P_ACTION_TYPE_IN,
              p_json_req_in,
              P_USER_IN,
              sysdate
            );
        EXCEPTION
        WHEN OTHERS THEN
          rollback;
          P_RESP_MSG_OUT:='Error while inserting into VMS_RULE_MAST'||SUBSTR(SQLERRM,1,200);
          RETURN;
        END;
        
        BEGIN
          FOR i IN 1..P_RULE_DETAIL_IN.COUNT
          LOOP
            BEGIN
              INSERT
              INTO VMS_RULE_MAST_DETAILS
              (
                VRD_RULE_ID,
                VRD_RULE_DET_ID,
                VRD_RULE_FILTER,
                vrd_ins_user,
                vrd_ins_date
              )
              VALUES
              (
                V_RULE_ID,
                P_RULE_DETAIL_IN(i).RULE_DETAIL_ID,
                fn_emaps_main(P_RULE_DETAIL_IN(I).RULE_FILTER),
                p_user_in,
                sysdate
              );
           EXCEPTION
              WHEN OTHERS THEN
                  rollback;
                  P_RESP_MSG_OUT:='Error while inserting into  VMS_RULE_MAST_DETAILS'||SUBSTR(SQLERRM,1,200);
                  RETURN;
          END;
       END LOOP;
          commit;
       EXCEPTION
        WHEN OTHERS THEN
          P_RESP_MSG_OUT:='Error while inserting into  VMS_RULE_MAST_DETAILS'||SUBSTR(SQLERRM,1,200);
          RETURN;
      END;
      
      ELSE
        BEGIN
            UPDATE VMS_RULE_MAST
              SET VRM_RULE_NAME=upper(P_RULE_NAME_IN),
              VRM_RULE_EXP=P_RULE_EXP_IN,
              VRM_TRANSACTION_TYPE=P_TRANS_TYPE_IN,
              VRM_ACTION_TYPE=P_ACTION_TYPE_IN,
              vrm_json_req=p_json_req_in,
              VRM_LUPD_USER=P_USER_IN,
              VRM_JSONREQ_FLAG=null,
              VRM_LUPD_DATE=SYSDATE
            WHERE VRM_RULE_ID=P_RULE_ID_IN;
        EXCEPTION
            WHEN OTHERS THEN
                P_RESP_MSG_OUT:='Error while updating VMS_RULE_MAST'||SUBSTR(SQLERRM,1,200);
                rollback;
                return;
        end;
        
        BEGIN
            insert into VMS_RULE_MAST_DETAILS_HIST(vrh_rule_id,vrh_rule_det_id,vrh_rule_filter,
            vrh_ins_user,vrh_ins_date,vrh_lupd_user,vrh_lupd_date)
            select VRD_RULE_ID,VRD_RULE_DET_ID,VRD_RULE_FILTER,VRD_INS_USER,VRD_INS_DATE,
            VRD_LUPD_USER,VRD_LUPD_DATE
            from VMS_RULE_MAST_DETAILS
            where VRD_RULE_ID=P_RULE_ID_IN;
        EXCEPTION
            WHEN OTHERS THEN
                rollback;
                P_RESP_MSG_OUT:='Error while inserting into VMS_RULE_MAST_DETAILS_HIST'||SUBSTR(SQLERRM,1,200);
                return;
        end;
        
        BEGIN
          DELETE FROM VMS_RULE_MAST_DETAILS WHERE VRD_RULE_ID=P_RULE_ID_IN;
        EXCEPTION
        WHEN OTHERS THEN
          P_RESP_MSG_OUT:='Error while deleting from VMS_RULE_MAST_DETAILS'||SUBSTR(SQLERRM,1,200);
          ROLLBACK;
          RETURN;
        END;
        
        BEGIN
          FOR i IN 1..P_RULE_DETAIL_IN.COUNT
          LOOP
            BEGIN
              INSERT
              INTO VMS_RULE_MAST_DETAILS
              (
                VRD_RULE_ID,
                VRD_RULE_DET_ID,
                VRD_RULE_FILTER,
                vrd_ins_user,
                vrd_ins_date
              )
              VALUES
              (
                P_RULE_ID_IN,
                P_RULE_DETAIL_IN(i).RULE_DETAIL_ID,
                fn_emaps_main(P_RULE_DETAIL_IN(I).RULE_FILTER),
                p_user_in,
                sysdate
              );
           EXCEPTION
              WHEN OTHERS THEN
                  rollback;
                  P_RESP_MSG_OUT:='Error while inserting into  VMS_RULE_MAST_DETAILS'||SUBSTR(SQLERRM,1,200);
                  RETURN;
          END;
          END LOOP;
        EXCEPTION
          WHEN OTHERS THEN
            P_RESP_MSG_OUT:='Error while inserting into  VMS_RULE_MAST_DETAILS'||SUBSTR(SQLERRM,1,200);
            RETURN;
        END;
        
        commit;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        p_resp_msg_out:='Error in main'||SUBSTR(sqlerrm,1,200);
    END;
    
    procedure insert_rule_set(p_rule_set_id_in in number,
                             p_rule_set_name_in IN VARCHAR2,
                             p_added_rule_ids_in IN VARCHAR2,
                             p_delete_rule_ids_in in varchar2,
                             p_user_in in number,
                             p_resp_msg_out out varchar2)
    as
    v_rule_set_id VMS_RULESET_MAST.VRS_RULESET_ID%type;
    begin
    p_resp_msg_out  :='OK';
        IF p_rule_set_id_in IS NULL THEN
        
            
            BEGIN
              SELECT nvl(MAX(VRS_RULESET_ID),0)+1  
              INTO v_rule_set_id 
              FROM VMS_RULESET_MAST;
              
            EXCEPTION
                WHEN OTHERS THEN
                p_resp_msg_out:='Error while getting rule id'||SUBSTR(sqlerrm,1,200);
                RETURN;
            END;
            
            BEGIN
              INSERT
              INTO VMS_RULESET_MAST
             (
                VRS_RULESET_ID,
                VRS_RULESET_NAME,
                VRS_INS_USER,
                VRS_INS_DATE
              )
              VALUES
              (
                v_rule_set_id,
                upper(p_rule_set_name_in),
                p_user_in,
                sysdate
              );
          EXCEPTION
            WHEN OTHERS THEN
            rollback;
            P_RESP_MSG_OUT:='Error while inserting into VMS_RULESET_MAST'||SUBSTR(SQLERRM,1,200);
            return;
          END;
          
          
          BEGIN
              FOR i IN ((SELECT regexp_substr(p_added_rule_ids_in,'[^,]+', 1, LEVEL) AS rule_id FROM DUAL
                                    CONNECT BY regexp_substr(p_added_rule_ids_in, '[^,]+', 1, LEVEL) IS NOT NULL))
              LOOP
                BEGIN
                  INSERT
                  INTO VMS_RULESET_MAST_DETAILS
                  (
                    VSD_RULESET_ID,
                    VSD_RULEID,
                    vsd_ins_user,
                    vsd_ins_date
                  )
                  VALUES
                (
                  v_rule_set_id,
                  i.rule_id,
                  p_user_in,
                  sysdate
                );
            EXCEPTION
              WHEN OTHERS THEN
                  rollback;
                  P_RESP_MSG_OUT:='Error while inserting into  VMS_RULESET_MAST_DETAILS'||SUBSTR(SQLERRM,1,200);
                  RETURN;
            END;
          END LOOP;
          EXCEPTION
            WHEN OTHERS THEN
              rollback;
              P_RESP_MSG_OUT:='Error while inserting into  VMS_RULESET_MAST_DETAILS'||SUBSTR(SQLERRM,1,200);
              RETURN;
          END;
          
          commit;
        else
            BEGIN
              UPDATE VMS_RULESET_MAST
                SET VRS_RULESET_NAME=upper(p_rule_set_name_in),
                VRS_LUPD_USER=p_user_in,
                VRS_LUPD_DATE=sysdate
              WHERE VRS_RULESET_ID=p_rule_set_id_in;
            EXCEPTION
                WHEN OTHERS THEN
                  rollback;
                  P_RESP_MSG_OUT:='Error while updating VMS_RULE_MAST'||SUBSTR(SQLERRM,1,200);
                  return;
            END;
            IF p_delete_rule_ids_in IS NOT NULL THEN
                BEGIN
                  insert into VMS_RULESET_MAST_DETAILS_HIST(VRH_RULESET_ID,VRH_RULEID,VRH_INS_USER,
                  VRH_INS_DATE)
                  SELECT VSD_RULESET_ID,VSD_RULEID,VSD_INS_USER,
                  VSD_INS_DATE
                  from VMS_RULESET_MAST_DETAILS
                  WHERE VSD_RULESET_ID=p_rule_set_id_in
                  AND vsd_ruleid IN (SELECT regexp_substr(p_delete_rule_ids_in,'[^,]+', 1, LEVEL) FROM DUAL
                                    CONNECT BY regexp_substr(p_delete_rule_ids_in, '[^,]+', 1, LEVEL) IS NOT NULL);
                EXCEPTION
                WHEN OTHERS THEN
                    rollback;
                    P_RESP_MSG_OUT:='Error while inserting into VMS_RULESET_MAST_DETAILS_HIST'||SUBSTR(SQLERRM,1,200);
                    return;
                end;
                
                BEGIN
                  DELETE FROM VMS_RULESET_MAST_DETAILS 
                  WHERE VSD_RULESET_ID=p_rule_set_id_in
                  AND vsd_ruleid IN (SELECT regexp_substr(p_delete_rule_ids_in,'[^,]+', 1, LEVEL) FROM DUAL
                                    CONNECT BY regexp_substr(p_delete_rule_ids_in, '[^,]+', 1, LEVEL) IS NOT NULL);
                EXCEPTION
                  WHEN OTHERS THEN
                    P_RESP_MSG_OUT:='Error while deleting from VMS_RULESET_MAST_DETAILS'||SUBSTR(SQLERRM,1,200);
                    ROLLBACK;
                    RETURN;
                END;
                
                BEGIN
                    FOR i IN (SELECT cpm_prod_code FROM cms_prod_mast
                              WHERE cpm_ruleset_id=p_rule_set_id_in) loop
                              
                         BEGIN   
                            INSERT INTO VMS_PRODCAT_RULE_MAPPING_HIST(VPH_PROD_CODE,vph_rule_set_id,
                                                    VPH_MAPPING_LEVEL,VPH_PROD_CATTYPE,
                                                     VPH_RULE_ID,VPH_PRIORITY,vph_ins_user,vph_ins_date)
                            SELECT  VPR_PROD_CODE,p_rule_set_id_in,VPR_MAPPING_LEVEL,VPR_PROD_CATTYPE,
                                    VPR_RULE_ID,VPR_PRIORITY,vpr_ins_user,vpr_ins_date
                            FROM VMS_PRODCAT_RULE_MAPPING
                            WHERE vpr_prod_code=i.cpm_prod_code
                            AND vpr_prod_cattype=0
                            AND vpr_rule_id IN (SELECT regexp_substr(p_delete_rule_ids_in,'[^,]+', 1, LEVEL) FROM DUAL
                                    CONNECT BY regexp_substr(p_delete_rule_ids_in, '[^,]+', 1, LEVEL) IS NOT NULL);
                        
                        EXCEPTION
                            WHEN OTHERS THEN
                                rollback;
                                p_resp_msg_out:='Error while inserting into VMS_PRODCAT_RULE_MAPPING_HIST'||substr(sqlerrm,1,200);
                                RETURN; 
                        END;
                        
                        
                        BEGIN
                            DELETE FROM vms_prodcat_rule_mapping
                            WHERE vpr_prod_code=i.cpm_prod_code
                            AND vpr_prod_cattype=0
                            AND vpr_rule_id IN (SELECT regexp_substr(p_delete_rule_ids_in,'[^,]+', 1, LEVEL) FROM DUAL
                                    CONNECT BY regexp_substr(p_delete_rule_ids_in, '[^,]+', 1, LEVEL) IS NOT NULL);
                            
                        exception
                            WHEN others THEN
                                P_RESP_MSG_OUT:='Error while deleting from vms_prodcat_rule_mapping'||SUBSTR(SQLERRM,1,200);
                                ROLLBACK;
                                RETURN;
                        END;
                        
                    END loop;
                exception
                    WHEN others THEN
                        P_RESP_MSG_OUT:='Error while deleting from vms_prodcat_rule_mapping'||SUBSTR(SQLERRM,1,200);
                        ROLLBACK;
                        RETURN;
                END;
                
                BEGIN
                    FOR i IN (SELECT cpc_prod_code,cpc_card_type FROM cms_prod_cattype
                              WHERE cpc_ruleset_id=p_rule_set_id_in) loop
                              
                       BEGIN   
                            INSERT INTO VMS_PRODCAT_RULE_MAPPING_HIST(VPH_PROD_CODE,vph_rule_set_id,
                                                    VPH_MAPPING_LEVEL,VPH_PROD_CATTYPE,
                                                     VPH_RULE_ID,VPH_PRIORITY,vph_ins_user,vph_ins_date)
                            SELECT  VPR_PROD_CODE,p_rule_set_id_in,VPR_MAPPING_LEVEL,VPR_PROD_CATTYPE,
                                    VPR_RULE_ID,VPR_PRIORITY,vpr_ins_user,vpr_ins_date
                            FROM VMS_PRODCAT_RULE_MAPPING
                            WHERE vpr_prod_code=i.cpc_prod_code
                            AND vpr_prod_cattype=i.cpc_card_type
                            AND vpr_rule_id IN (SELECT regexp_substr(p_delete_rule_ids_in,'[^,]+', 1, LEVEL) FROM DUAL
                                    CONNECT BY regexp_substr(p_delete_rule_ids_in, '[^,]+', 1, LEVEL) IS NOT NULL);
                        
                        EXCEPTION
                            WHEN OTHERS THEN
                                p_resp_msg_out:='Error while inserting into VMS_PRODCAT_RULE_MAPPING_HIST'||substr(sqlerrm,1,200);
                                RETURN; 
                        END;     
                        
                        BEGIN
                            DELETE FROM vms_prodcat_rule_mapping
                            WHERE vpr_prod_code=i.cpc_prod_code
                            AND vpr_prod_cattype=i.cpc_card_type
                            AND vpr_rule_id IN (SELECT regexp_substr(p_delete_rule_ids_in,'[^,]+', 1, LEVEL) FROM DUAL
                                    CONNECT BY regexp_substr(p_delete_rule_ids_in, '[^,]+', 1, LEVEL) IS NOT NULL);
                            
                        exception
                            WHEN others THEN
                                P_RESP_MSG_OUT:='Error while deleting from vms_prodcat_rule_mapping-prod cattype'||SUBSTR(SQLERRM,1,200);
                                ROLLBACK;
                                RETURN;
                        END;
                        
                    END loop;
                exception
                    WHEN others THEN
                        P_RESP_MSG_OUT:='Error while deleting from vms_prodcat_rule_mapping-prod cattype'||SUBSTR(SQLERRM,1,200);
                        ROLLBACK;
                        RETURN;
                END;
 
            end if;
           
            IF p_added_rule_ids_in IS NOT NULL THEN
                  FOR i IN ((SELECT regexp_substr(p_added_rule_ids_in,'[^,]+', 1, LEVEL) AS rule_id FROM DUAL
                                    CONNECT BY regexp_substr(p_added_rule_ids_in, '[^,]+', 1, LEVEL) IS NOT NULL))
                  LOOP
                    BEGIN
                      INSERT
                      INTO VMS_RULESET_MAST_DETAILS
                      (
                        VSD_RULESET_ID,
                        VSD_RULEID,
                        vsd_ins_user,
                        vsd_ins_date
                      )
                      VALUES
                    (
                      p_rule_set_id_in,
                      i.rule_id,
                      p_user_in,
                      sysdate
                    );
                EXCEPTION
                  WHEN OTHERS THEN
                      rollback;
                      P_RESP_MSG_OUT:='Error while inserting into  VMS_RULESET_MAST_DETAILS'||SUBSTR(SQLERRM,1,200);
                      RETURN;
                END;
              END LOOP;
              
              BEGIN
                  FOR i IN (SELECT cpm_prod_code FROM cms_prod_mast
                            WHERE cpm_ruleset_id=p_rule_set_id_in) loop
                      BEGIN
                          for J in ((select REGEXP_SUBSTR(P_ADDED_RULE_IDS_IN,'[^,]+', 1, level) as RULE_ID from DUAL
                                    CONNECT BY regexp_substr(p_added_rule_ids_in, '[^,]+', 1, LEVEL) IS NOT NULL))
                          LOOP
                              INSERT INTO VMS_PRODCAT_RULE_MAPPING(VPR_PROD_CODE,VPR_MAPPING_LEVEL,VPR_PROD_CATTYPE,
                                                              VPR_RULE_ID,vpr_priority,vpr_ins_user,
                                                              vpr_ins_date)
                                VALUES(i.cpm_prod_code,'P',0,
                                j.rule_id,(SELECT nvl(MAX(vpr_priority),0)+1 FROM 
                                VMS_PRODCAT_RULE_MAPPING where vpr_prod_code=i.cpm_prod_code and vpr_prod_cattype=0),p_user_in,sysdate);
                          end loop;
                      exception
                          WHEN others THEN
                              P_RESP_MSG_OUT:='Error while inserting into vms_prodcat_rule_mapping-'||SUBSTR(SQLERRM,1,200);
                              ROLLBACK;
                              RETURN;
                      END;
                  end loop;
              exception
                  WHEN others THEN
                      P_RESP_MSG_OUT:='Error while inserting into vms_prodcat_rule_mapping-'||SUBSTR(SQLERRM,1,200);
                      ROLLBACK;
                      RETURN;
              END;
              
              
              BEGIN
                  FOR i IN (SELECT cpc_prod_code,cpc_card_type FROM cms_prod_cattype
                            WHERE cpc_ruleset_id=p_rule_set_id_in) loop
                      BEGIN
                      FOR j IN ((SELECT regexp_substr(p_added_rule_ids_in,'[^,]+', 1, LEVEL) AS rule_id FROM DUAL
                                    CONNECT BY regexp_substr(p_added_rule_ids_in, '[^,]+', 1, LEVEL) IS NOT NULL))
                      loop
                              INSERT INTO VMS_PRODCAT_RULE_MAPPING(VPR_PROD_CODE,VPR_MAPPING_LEVEL,VPR_PROD_CATTYPE,
                                                              VPR_RULE_ID,vpr_priority,vpr_ins_user,
                                                              vpr_ins_date)
                                VALUES(i.cpc_prod_code,'PC',i.cpc_card_type,
                                j.rule_id,(SELECT nvl(MAX(vpr_priority),0)+1 FROM 
                                VMS_PRODCAT_RULE_MAPPING WHERE vpr_prod_code=i.cpc_prod_code AND vpr_prod_cattype=i.cpc_card_type),p_user_in,SYSDATE);
                    end loop;
                      exception
                          WHEN others THEN
                              P_RESP_MSG_OUT:='Error while inserting into vms_prodcat_rule_mapping-'||SUBSTR(SQLERRM,1,200);
                              ROLLBACK;
                              RETURN;
                      END;
                 end loop;
                      
              exception
                  WHEN others THEN
                      P_RESP_MSG_OUT:='Error while inserting into vms_prodcat_rule_mapping-'||SUBSTR(SQLERRM,1,200);
                      ROLLBACK;
                      RETURN;
              END;
          END IF;
        commit;
       end if;
    
    exception
        when others then
            p_resp_msg_out:='Error in main'||SUBSTR(sqlerrm,1,200);
    end;
    
     PROCEDURE attach_detach_rule(p_attach_detach_type_in in varchar2,
                        p_prod_code_in IN cms_prod_mast.cpm_prod_code%TYPE,
                        p_prod_category_in IN CMS_PROD_CATTYPE.cpc_card_type%TYPE,
                        p_mapping_level_in in varchar2,
                        p_rule_set_id_in in number,
                        p_rule_details_in IN rule_set_type_tab,
                        p_user_in IN NUMBER,
                        p_resp_msg_out out VARCHAR2)
    AS 
      v_rule_set_id cms_prod_mast.CPM_RULESET_ID%type;
    BEGIN
    p_resp_msg_out:='OK';
      IF p_attach_detach_type_in='A' THEN
        begin
            IF p_mapping_level_in='P' THEN
                BEGIN
                    UPDATE cms_prod_mast
                    SET CPM_RULESET_ID=p_rule_set_id_in
                    WHERE cpm_inst_code=1
                    AND cpm_prod_code=p_prod_code_in
                    RETURNING (SELECT CPM_RULESET_ID FROM cms_prod_mast
                                 WHERE cpm_inst_code=1
                                AND cpm_prod_code=p_prod_code_in) into v_rule_set_id;
                exception
                    WHEN others THEN
                        ROLLBACK;
                        p_resp_msg_out:='Error while updating cms_prod_mast'||substr(sqlerrm,1,200);
                        return;
                END;
                
                BEGIN   
                    INSERT INTO VMS_PRODCAT_RULE_MAPPING_HIST(VPH_PROD_CODE,vph_rule_set_id,
                                            VPH_MAPPING_LEVEL,VPH_PROD_CATTYPE,
                                             VPH_RULE_ID,VPH_PRIORITY,vph_ins_user,vph_ins_date)
                    SELECT  VPR_PROD_CODE,v_rule_set_id,VPR_MAPPING_LEVEL,VPR_PROD_CATTYPE,
                            VPR_RULE_ID,VPR_PRIORITY,vpr_ins_user,vpr_ins_date
                    FROM VMS_PRODCAT_RULE_MAPPING
                    WHERE VPR_PROD_CODE=p_prod_code_in
                    and VPR_PROD_CATTYPE=0;
                
                EXCEPTION
                    WHEN OTHERS THEN
                        rollback;
                        p_resp_msg_out:='Error while inserting into VMS_PRODCAT_RULE_MAPPING_HIST'||substr(sqlerrm,1,200);
                        return; 
                END;
                
                BEGIN
                      DELETE FROM VMS_PRODCAT_RULE_MAPPING
                      WHERE VPR_PROD_CODE=p_prod_code_in
                      and VPR_PROD_CATTYPE =0;
                exception
                    WHEN others THEN
                        rollback;
                        p_resp_msg_out:='Error while deleting from VMS_PRODCAT_RULE_MAPPING'||substr(sqlerrm,1,200);
                        return;
                END;
                
                
                BEGIN
                    FOR i IN 1..p_rule_details_in.count loop
                        BEGIN
                         INSERT INTO VMS_PRODCAT_RULE_MAPPING(VPR_PROD_CODE,VPR_MAPPING_LEVEL,VPR_PROD_CATTYPE,
                                                              VPR_RULE_ID,vpr_priority,vpr_ins_user,
                                                              vpr_ins_date)
                          VALUES(p_prod_code_in,p_mapping_level_in,nvl(p_prod_category_in,0),
                                p_rule_details_in(i).rule_id,p_rule_details_in(i).execution_order,p_user_in,sysdate);
                         exception
                            WHEN others THEN
                                  ROLLBACK;
                                  p_resp_msg_out:='Error while inserting into VMS_PRODCAT_RULE_MAPPING'||substr(sqlerrm,1,200);
                                  return;
                         END;
                     END loop;
                exception
                    WHEN others THEN
                        ROLLBACK;
                        p_resp_msg_out:='Error while inserting into VMS_PRODCAT_RULE_MAPPING'||substr(sqlerrm,1,200);
                        return;
                END;
                
                commit;
             elsif p_mapping_level_in='PC' THEN
                BEGIN
                    UPDATE cms_prod_cattype
                    SET CPC_RULESET_ID=p_rule_set_id_in
                    where cpc_inst_code=1
                    AND cpc_prod_code=p_prod_code_in
                    AND  cpc_card_type=nvl(p_prod_category_in,0)
                    returning (select cpc_ruleset_id from cms_prod_cattype
                                where cpc_inst_code=1
                                AND cpc_prod_code=p_prod_code_in
                                AND  cpc_card_type=nvl(p_prod_category_in,0)) into v_rule_set_id;
                exception
                    WHEN others THEN
                        ROLLBACK;
                        p_resp_msg_out:='Error while updating cms_prod_cattype'||substr(sqlerrm,1,200);
                        return;
                END;
                
                BEGIN
                    INSERT INTO VMS_PRODCAT_RULE_MAPPING_HIST(VPH_PROD_CODE,
                                            VPH_MAPPING_LEVEL,VPH_PROD_CATTYPE,vph_rule_set_id,
                                            VPH_RULE_ID,VPH_PRIORITY,vph_ins_user,vph_ins_date)
                    SELECT  VPR_PROD_CODE,VPR_MAPPING_LEVEL,VPR_PROD_CATTYPE,v_rule_set_id,
                            VPR_RULE_ID,VPR_PRIORITY,vpr_ins_user,vpr_ins_date
                    FROM VMS_PRODCAT_RULE_MAPPING
                    WHERE VPR_PROD_CODE=p_prod_code_in
                    and VPR_PROD_CATTYPE=p_prod_category_in;
                
                EXCEPTION
                    WHEN OTHERS THEN
                        rollback;
                        p_resp_msg_out:='Error while inserting into VMS_PRODCAT_RULE_MAPPING_HIST'||substr(sqlerrm,1,200);
                        return; 
                END;
                
                BEGIN
                      DELETE FROM VMS_PRODCAT_RULE_MAPPING
                      WHERE VPR_PROD_CODE=p_prod_code_in
                      and VPR_PROD_CATTYPE=p_prod_category_in;
                exception
                    WHEN others THEN
                        rollback;
                        p_resp_msg_out:='Error while deleting from VMS_PRODCAT_RULE_MAPPING'||substr(sqlerrm,1,200);
                        RETURN;
                END;
                
                BEGIN
                    FOR i IN 1..p_rule_details_in.count loop
                        BEGIN
                         INSERT INTO VMS_PRODCAT_RULE_MAPPING(VPR_PROD_CODE,VPR_MAPPING_LEVEL,VPR_PROD_CATTYPE,
                                                              VPR_RULE_ID,vpr_priority,vpr_ins_user,
                                                              vpr_ins_date)
                          VALUES(p_prod_code_in,p_mapping_level_in,p_prod_category_in,
                                p_rule_details_in(i).rule_id,p_rule_details_in(i).execution_order,p_user_in,sysdate);
                         exception
                            WHEN others THEN
                                  ROLLBACK;
                                  p_resp_msg_out:='Error while inserting into VMS_PRODCAT_RULE_MAPPING'||substr(sqlerrm,1,200);
                                  return;
                         END;
                     END loop;
                exception
                    WHEN others THEN
                        ROLLBACK;
                        p_resp_msg_out:='Error while inserting into VMS_PRODCAT_RULE_MAPPING'||substr(sqlerrm,1,200);
                        RETURN;
                END;
              commit;
             END IF;
          exception
              WHEN others THEN
                  p_resp_msg_out:='Error while attaching rule to product or product category level'||substr(sqlerrm,1,200);
                  RETURN;
          END;
     elsif p_attach_detach_type_in='D' THEN
        BEGIN
            if p_mapping_level_in='P' then
                BEGIN
                    UPDATE cms_prod_mast
                    SET CPM_RULESET_ID=null
                    WHERE cpm_inst_code=1
                    AND cpm_prod_code=p_prod_code_in
                    returning (select CPM_RULESET_ID from cms_prod_mast
                               WHERE cpm_inst_code=1
                               AND cpm_prod_code=p_prod_code_in) into v_rule_set_id;
                exception
                    WHEN others THEN
                      rollback;
                      p_resp_msg_out:='Error while updating cms_prod_mast'||substr(sqlerrm,1,200);
                      RETURN;  
                END;
                
                BEGIN   
                    INSERT INTO VMS_PRODCAT_RULE_MAPPING_HIST(VPH_PROD_CODE,vph_rule_set_id,
                                            VPH_MAPPING_LEVEL,VPH_PROD_CATTYPE,
                                             VPH_RULE_ID,VPH_PRIORITY,vph_ins_user,vph_ins_date)
                    SELECT  VPR_PROD_CODE,v_rule_set_id,VPR_MAPPING_LEVEL,VPR_PROD_CATTYPE,
                            VPR_RULE_ID,VPR_PRIORITY,vpr_ins_user,vpr_ins_date
                    FROM VMS_PRODCAT_RULE_MAPPING
                    WHERE VPR_PROD_CODE=p_prod_code_in
                    and VPR_PROD_CATTYPE=0;
                
                EXCEPTION
                    WHEN OTHERS THEN
                        rollback;
                        p_resp_msg_out:='Error while inserting into VMS_PRODCAT_RULE_MAPPING_HIST'||substr(sqlerrm,1,200);
                        return; 
                END;
                
                
                BEGIN
                    DELETE FROM VMS_PRODCAT_RULE_MAPPING
                    WHERE VPR_PROD_CODE=p_prod_code_in
                    and VPR_PROD_CATTYPE=0;
                exception
                    WHEN others THEN
                      rollback;
                      p_resp_msg_out:='Error while deleting from  VMS_PRODCAT_RULE_MAPPING'||substr(sqlerrm,1,200);
                      RETURN;
                END;
                
                commit;
            elsif p_mapping_level_in='PC' then
                BEGIN
                    UPDATE cms_prod_cattype
                    SET CPC_RULESET_ID=null
                    where cpc_inst_code=1
                    AND cpc_prod_code=p_prod_code_in
                    AND  cpc_card_type=p_prod_category_in
                    RETURNING (SELECT cpc_ruleset_id FROM
                               cms_prod_cattype 
                               where cpc_inst_code=1
                               AND cpc_prod_code=p_prod_code_in
                               AND  cpc_card_type=p_prod_category_in) into v_rule_set_id;
                exception
                    WHEN others THEN
                      rollback;
                      p_resp_msg_out:='Error while updating cms_prod_cattype'||substr(sqlerrm,1,200);
                      RETURN;
                END;
                
                
                BEGIN
                    INSERT INTO VMS_PRODCAT_RULE_MAPPING_HIST(VPH_PROD_CODE,
                                            VPH_MAPPING_LEVEL,VPH_PROD_CATTYPE,vph_rule_set_id,
                                            VPH_RULE_ID,VPH_PRIORITY,vph_ins_user,vph_ins_date)
                    SELECT  VPR_PROD_CODE,VPR_MAPPING_LEVEL,VPR_PROD_CATTYPE,v_rule_set_id,
                            VPR_RULE_ID,VPR_PRIORITY,vpr_ins_user,vpr_ins_date
                    FROM VMS_PRODCAT_RULE_MAPPING
                    WHERE VPR_PROD_CODE=p_prod_code_in
                    and VPR_PROD_CATTYPE=p_prod_category_in;
                
                EXCEPTION
                    WHEN OTHERS THEN
                        rollback;
                        p_resp_msg_out:='Error while inserting into VMS_PRODCAT_RULE_MAPPING_HIST'||substr(sqlerrm,1,200);
                        RETURN; 
                END;
                
                BEGIN
                    DELETE FROM VMS_PRODCAT_RULE_MAPPING
                    WHERE VPR_PROD_CODE=p_prod_code_in
                    AND VPR_PROD_CATTYPE=p_prod_category_in;
                exception
                    WHEN others THEN
                      rollback;
                      p_resp_msg_out:='Error while deleting from  VMS_PRODCAT_RULE_MAPPING'||substr(sqlerrm,1,200);
                      RETURN;
                END;
                
                commit;
            END IF;
         
        exception
              WHEN others THEN
                  p_resp_msg_out:='Error while detaching rule from product or product category level'||substr(sqlerrm,1,200);
                  RETURN;
        END;
      commit;
      END IF;
        
    exception
        WHEN others THEN
           p_resp_msg_out:='Error in Main '||substr(sqlerrm,1,200); 
    END;
    
    PROCEDURE VIEW_ATTACHRULESET(TAB_RULE_SET_OUT OUT TAB_RULE_SET,
                                 p_resp_msg_out out VARCHAR2)
    AS
    v_prod_cattype cms_prod_cattype.cpc_card_type%TYPE;
    v_ruleset_id vms_ruleset_mast.vrs_ruleset_id%TYPE;
    v_ruleset_name vms_ruleset_mast.vrs_ruleset_name%TYPE;
    v_index NUMBER:=0;
    v_index1 NUMBER:=0;
    v_index2 NUMBER:=0;
    v_tab_rule_details tab_rule_details;
    v_tab_rule_set_details TAB_RULE_SET_DETAILS;
    v_rule_name vms_rule_mast.vrm_rule_name%TYPE;
    v_rule_exp vms_rule_mast.vrm_rule_exp%TYPE;
    v_transaction_type vms_rule_mast.vrm_transaction_type%TYPE;
    v_action_type vms_rule_mast.vrm_action_type%TYPE;
    v_json_req vms_rule_mast.vrm_json_req%TYPE;

    BEGIN
    p_resp_msg_out:='OK';
    v_tab_rule_details:=tab_rule_details();
    V_TAB_RULE_SET_DETAILS:=TAB_RULE_SET_DETAILS();
    TAB_RULE_SET_OUT:=TAB_RULE_SET();


       for I in (select distinct VPR_PROD_CODE,VPR_PROD_CATTYPE,vpr_mapping_level from VMS_PRODCAT_RULE_MAPPING)
          LOOP
             begin
                    FOR j IN (SELECT DISTINCT VPR_PROD_CATTYPE,VPR_PROD_CODE,
                    decode(VPR_MAPPING_LEVEL,'P',cpm_ruleset_id,e.CPc_RULESET_ID) cpm_ruleset_id,vrs_ruleset_name,vpr_rule_id,vrm_rule_name,vpr_priority,
                    VRM_RULE_EXP,VRM_TRANSACTION_TYPE,VRM_ACTION_TYPE
                    FROM VMS_PRODCAT_RULE_MAPPING A,CMS_PROD_MAST B,VMS_RULESET_MAST C,VMS_RULE_MAST D,CMS_PROD_CATTYPE E
                    WHERE ((VPR_MAPPING_LEVEL='P' AND A.VPR_PROD_CODE=B.CPM_PROD_CODE  AND B.CPM_RULESET_ID=C.VRS_RULESET_ID) OR
                     (VPR_MAPPING_LEVEL='PC' AND E.CPC_RULESET_ID=C.VRS_RULESET_ID AND A.VPR_PROD_CODE=E.CPC_PROD_CODE AND A.VPR_PROD_CATTYPE=E.CPC_CARD_TYPE))
                    AND VPR_PROD_CODE=i.VPR_PROD_CODE
                    and cpm_prod_code=cpc_prod_code
                   AND VPR_MAPPING_LEVEL=i.vpr_mapping_level
                   AND VPR_PROD_CATTYPE=i.VPR_PROD_CATTYPE
                    and a.VPR_RULE_ID=D.VRM_RULE_ID order by VPR_PROD_CODE,vpr_prod_cattype)
                    LOOP
                      begin


                                   V_TAB_RULE_DETAILS:=TAB_RULE_DETAILS();
                                   V_INDEX:=0;
                           FOR k IN (SELECT vrd_rule_det_id,fn_dmaps_main(vrd_rule_filter) vrd_rule_filter
                                      FROM vms_rule_mast_details
                                      WHERE vrd_rule_id=j.vpr_rule_id)
                            loop
                                BEGIN
                                  v_tab_rule_details.extend;
                                  V_INDEX:=V_INDEX+1;
                                  v_tab_rule_details(v_index):= RULE_DETAILS(k.vrd_rule_det_id,k.vrd_rule_filter);
                                exception
                                    WHEN others THEN
                                        p_resp_msg_out:='Error while forming rule details'||substr(sqlerrm,1,200);
                                        return;
                                END;

                            END loop;

                          v_tab_rule_set_details.EXTEND;
                          V_INDEX1:=V_INDEX1+1;
                          v_tab_rule_set_details(V_INDEX1):=
                          RULE_SET_DETAILS(j.vpr_rule_id,j.vrm_rule_name,j.vpr_priority,
                          j.vrm_rule_exp,j.vrm_transaction_type,j.vrm_action_type,v_tab_rule_details);

                          v_prod_cattype:=j.vpr_prod_cattype;
                          v_ruleset_id :=j.cpm_ruleset_id;
                          v_ruleset_name:=j.vrs_ruleset_name;

                      exception
                          WHEN others THEN
                              P_RESP_MSG_OUT:='Error while forming rule set details'||SUBSTR(SQLERRM,1,200);
                              return;
                      end;
                   END loop;
                  TAB_RULE_SET_OUT.EXTEND;
                  V_INDEX2:=V_INDEX2+1;
                  TAB_RULE_SET_OUT(v_index2):=RULE_SET(i.vpr_prod_code,v_prod_cattype,v_ruleset_id,v_ruleset_name,v_tab_rule_set_details);



                                   V_TAB_RULE_SET_DETAILS:=TAB_RULE_SET_DETAILS();

                                   V_INDEX1:=0;
                exception
                    WHEN others THEN
                        p_resp_msg_out:='Error while forming rule set details'||substr(sqlerrm,1,200);
                        return;
                end;
          END loop;
    exception
        WHEN others THEN
            p_resp_msg_out:='Error in main'||substr(sqlerrm,1,200);
            return;
    END;
PROCEDURE di_ran_match(p_program_id_in in varchar2,
                          p_merchant_id_in in varchar2,
                          p_resp_msg_out out varchar2,
                          p_result_out out varchar2)
as
exp_reject_record exception;
l_effective_date VMS_RAN_PROGRAM_MERCHANT.vrp_effective_date%type;
l_expiration_date VMS_RAN_PROGRAM_MERCHANT.vrp_expiration_date%type;
begin
      p_resp_msg_out:='OK';
      begin
          select vrp_effective_date,vrp_expiration_date
          into l_effective_date,l_expiration_date
          from VMS_RAN_PROGRAM_MERCHANT
          where vrp_program_id=p_program_id_in
          and vrp_merchant_id=p_merchant_id_in;         
      exception
          when no_data_found then
              p_resp_msg_out:='There is no record with program id '||p_program_id_in||' and merchant id '||p_merchant_id_in;
              raise exp_reject_record;
          when others then
              p_resp_msg_out:='Error while selecting from VMS_RAN_PROGRAM_MERCHANT'||sqlerrm;
              raise exp_reject_record;
      end;
  
      if trunc(l_expiration_date)>=trunc(sysdate) then
          if trunc(l_effective_date)<=trunc(sysdate) then
              p_result_out:='true';
          else
              p_resp_msg_out:='Transaction date less than effective date '||trunc(l_effective_date);
              raise exp_reject_record;
          end if;
      else
          p_resp_msg_out:='Expired Merchant '||p_merchant_id_in||'-'||trunc(l_expiration_date);
          raise exp_reject_record;
      end if;
    
exception
    when exp_reject_record then
         p_result_out:='false'; 
    when others then
          p_resp_msg_out:='Error in Main'||sqlerrm;
          p_result_out:='false';
end;

    
PROCEDURE VIEW_GLOBALRULESET(TAB_RULE_SET_OUT OUT GLOBAL_TAB_RULE_SET,
                                 p_resp_msg_out out VARCHAR2)
    AS
    v_prod_cattype cms_prod_cattype.cpc_card_type%TYPE;
    v_ruleset_id vms_ruleset_mast.vrs_ruleset_id%TYPE;
    v_ruleset_name vms_ruleset_mast.vrs_ruleset_name%TYPE;
    v_index NUMBER:=0;
    v_index1 NUMBER:=0;
    v_index2 NUMBER:=0;
    v_tab_rule_details tab_rule_details;
    v_tab_rule_set_details TAB_RULE_SET_DETAILS;
    v_rule_name vms_rule_mast.vrm_rule_name%TYPE;
    v_rule_exp vms_rule_mast.vrm_rule_exp%TYPE;
    v_transaction_type vms_rule_mast.vrm_transaction_type%TYPE;
    v_action_type vms_rule_mast.vrm_action_type%TYPE;
    v_json_req vms_rule_mast.vrm_json_req%TYPE;
     
    BEGIN
    p_resp_msg_out:='OK';
    v_tab_rule_details:=tab_rule_details();
    V_TAB_RULE_SET_DETAILS:=TAB_RULE_SET_DETAILS();
    TAB_RULE_SET_OUT:=GLOBAL_TAB_RULE_SET();
     for I IN(select distinct vrs_ruleset_id,vrs_ruleset_name from vms_ruleset_mast where vrs_rule_flag='G')
	 LOOP
             begin
                    FOR j IN (select distinct  vrm_rule_id,vrm_rule_name,
                    vrm_rule_exp,vrm_transaction_type,vrm_action_type from  
                     vms_ruleset_mast_details a,vms_rule_mast d
                     where a.vsd_ruleid=d.vrm_rule_id 
                      and vsd_ruleset_id=I.vrs_ruleset_id   order by vrm_rule_id   )
                    LOOP
                      begin
                                   V_TAB_RULE_DETAILS:=TAB_RULE_DETAILS();
                                   V_INDEX:=0;
                           FOR k IN (SELECT vrd_rule_det_id,fn_dmaps_main(vrd_rule_filter) vrd_rule_filter
                                      FROM vms_rule_mast_details
                                      WHERE vrd_rule_id=j.vrm_rule_id)
                            loop
                                BEGIN
                                  v_tab_rule_details.extend;
                                  V_INDEX:=V_INDEX+1;
                                  v_tab_rule_details(v_index):= RULE_DETAILS(k.vrd_rule_det_id,k.vrd_rule_filter);
                                exception
                                    WHEN others THEN
                                        p_resp_msg_out:='Error while forming rule details'||substr(sqlerrm,1,200);
                                        return;
                                END;
                            END loop;
                          v_tab_rule_set_details.EXTEND;
                          V_INDEX1:=V_INDEX1+1;
                          v_tab_rule_set_details(V_INDEX1):=
                          RULE_SET_DETAILS(j.vrm_rule_id,j.vrm_rule_name,v_index2,
                         j.vrm_rule_exp,j.vrm_transaction_type,j.vrm_action_type,v_tab_rule_details);
                      exception
                          WHEN others THEN
                              P_RESP_MSG_OUT:='Error while forming rule set details'||SUBSTR(SQLERRM,1,200);
                              return;
                      end;
                   END loop;
     
				   tab_rule_set_out.extend;
           v_ruleset_id :=I.vrs_ruleset_id;
           v_ruleset_name:=I.vrs_ruleset_name;
				   V_INDEX2:=V_INDEX2+1;
				   TAB_RULE_SET_OUT(v_index2):=GLOBAL_RULE_SET(v_ruleset_id,v_ruleset_name,v_tab_rule_set_details);
				   v_tab_rule_set_details:=tab_rule_set_details();
           V_INDEX1:=0;
   end;
   END LOOP;  
    exception
        WHEN others THEN
            p_resp_msg_out:='Error in main'||substr(sqlerrm,1,200);
            return;
    END;
    
END;
/
show error