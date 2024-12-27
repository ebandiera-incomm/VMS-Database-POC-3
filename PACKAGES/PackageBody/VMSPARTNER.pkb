create or replace
PACKAGE BODY vmscms.VMSPARTNER IS

   -- Private type declarations

   -- Private constant declarations

   -- Private variable declarations

   -- Function and procedure implementations
   --FUNCTION validate returns 'Y' or 'N' depending on whether
   -- the passed in partner ID and Customer ID are a valid pair or not

   FUNCTION validate
   (
      p_partner_id_in  IN VARCHAR2,
      p_customer_id_in IN VARCHAR2
   ) RETURN VARCHAR2 IS
      l_result      VARCHAR2(10);
      l_partner_id  cms_product_param.cpp_partner_id%TYPE;
      l_customer_id cms_cust_mast.ccm_cust_id%TYPE;
   begin
      --vmsaudit.audit_procedure($$PLSQL_UNIT);
      l_customer_id := to_number(p_customer_id_in);
      SELECT c.cpp_partner_id
        INTO l_partner_id
        FROM cms_cust_mast a, cms_appl_mast b, cms_product_param c
       WHERE a.ccm_cust_id = l_customer_id
         AND a.ccm_inst_code = b.cam_inst_code
         AND a.ccm_cust_code = b.cam_cust_code
         AND b.cam_inst_code = c.cpp_inst_code
         AND b.cam_prod_code = c.cpp_prod_code;
   
      IF l_partner_id = p_partner_id_in
      THEN
         l_result := 'Y';
      ELSE
         l_result := 'N';
      END IF;
   
      RETURN l_result;
   EXCEPTION
      WHEN no_data_found THEN
         l_result := 'N';
         RETURN l_result;
      WHEN OTHERS THEN
         l_result := 'N';
         RETURN l_result;
   END validate;


PROCEDURE attach_detach_prid_grid
(    
    p_partner_id_in   IN VARCHAR2,
    p_added_group_ids_in  IN VARCHAR2,
    p_delete_group_ids_in IN VARCHAR2,
    p_user_in            IN NUMBER,
    p_resp_msg_out OUT VARCHAR2
  )
AS
  l_cnt number;
BEGIN
  p_resp_msg_out      :='OK';
    begin
        select count(1)
          into  l_cnt from 
          VMS_PARTNER_ID_MAST
       where VPI_PARTNER_ID=p_partner_id_in;
    EXCEPTION
     WHEN OTHERS THEN
      p_resp_msg_out:='Error while taking count of partner id'||SUBSTR(sqlerrm,1,200);
      RETURN;
     END;
  if l_cnt=0 then
    BEGIN
      INSERT
      INTO VMS_PARTNER_ID_MAST
        (
          VPI_PARTNER_SNO,
          VPI_PARTNER_ID,
          VPI_INS_USER,
          VPI_INS_DATE,
          VPI_LUPD_USER,
          VPI_LUPD_DATE
        )
        VALUES
        (
         SEQ_PARTNER_SNO.NEXTVAL,
          p_partner_id_in,
          p_user_in,
          sysdate,
          P_USER_IN,
          sysdate
        );
    EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      P_RESP_MSG_OUT:='Error while inserting into VMS_PARTNER_ID_MAST'||SUBSTR(SQLERRM,1,200);
      RETURN;
    END;
  end if;
  
  IF p_delete_group_ids_in IS NOT NULL THEN
    BEGIN
          DELETE
          FROM VMS_GROUPID_PARTNERID_MAP
          WHERE VGP_PARTNER_ID=p_partner_id_in
          AND VGP_GROUP_ACCESS_NAME  IN
            (SELECT regexp_substr(p_delete_group_ids_in,'[^,]+', 1, LEVEL)
            FROM DUAL
              CONNECT BY regexp_substr(p_delete_group_ids_in, '[^,]+', 1, LEVEL) IS NOT NULL
            );
      
    EXCEPTION
        WHEN OTHERS THEN
          P_RESP_MSG_OUT:='Error while deleting from VMS_GROUPID_PARTNERID_MAP'||SUBSTR(SQLERRM,1,200);
          ROLLBACK;
          RETURN;
   END;
   
  END IF;
  
  if p_added_group_ids_in is not null then
    BEGIN
      FOR i IN
      (
        (SELECT regexp_substr(p_added_group_ids_in,'[^,]+', 1, LEVEL) AS group_id
        FROM DUAL
          CONNECT BY regexp_substr(p_added_group_ids_in, '[^,]+', 1, LEVEL) IS NOT NULL
        )
        )
        LOOP
          BEGIN
            INSERT
            INTO VMS_GROUPID_PARTNERID_MAP
              (
                VGP_PARTNER_ID,
                VGP_GROUP_ACCESS_NAME,
                VGP_INS_USER,
                VGP_INS_DATE,
                VGP_LUPD_USER,
                VGP_LUPD_DATE
              )
              VALUES
              (
                p_partner_id_in,
                i.group_id,
                p_user_in,
                sysdate,
                P_USER_IN,
                sysdate
              );
          EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
            P_RESP_MSG_OUT:='Error while inserting into  VMS_GROUPID_PARTNERID_MAP'||SUBSTR(SQLERRM,1,200);
            RETURN;
          END;
        END LOOP;
      EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        P_RESP_MSG_OUT:='Error while inserting into  VMS_GROUPID_PARTNERID_MAP'||SUBSTR(SQLERRM,1,200);
        RETURN;
      END;
      
      
  end if;
    
  COMMIT;
EXCEPTION
      WHEN OTHERS THEN
        p_resp_msg_out:='Error in main'||SUBSTR(sqlerrm,1,200);
END;
END VMSPARTNER;
/
show error