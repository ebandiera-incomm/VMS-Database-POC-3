create or replace PROCEDURE VMSCMS.POPULATE_ENCRYPTION (
   p_loopcounter_in    NUMBER,
   p_rownum_in         NUMBER)
IS

   l_encrypt_enable   cms_prod_cattype.cpc_encrypt_enable%TYPE;
   l_appl_code        cms_caf_info_entry.cci_appl_code%TYPE;
   l_prod_code        cms_appl_pan.cap_prod_code%TYPE;
   l_card_type        cms_appl_pan.cap_card_type%TYPE;
   l_err_msg          VARCHAR2(500);
   e_exception        EXCEPTION;
   
BEGIN
   FOR counter IN 1 .. p_loopcounter_in
   LOOP
		 FOR l_idx IN (SELECT ccm_cust_code
                   FROM cms_cust_mast
                   WHERE ccm_first_name_encr IS NULL
                   AND rownum <= p_rownum_in
                  )
         LOOP

		BEGIN
       
            BEGIN
                SELECT cap_appl_code,
                  cap_prod_code,
                  cap_card_type
                INTO l_appl_code,
                  l_prod_code,
                  l_card_type
                FROM
                  (SELECT cap_appl_code,
                    cap_prod_code,
                    cap_card_type
                  FROM cms_appl_pan
                  WHERE cap_inst_code = 1
                  AND cap_cust_code   = l_idx.ccm_cust_code
                  ORDER BY cap_pangen_date ASC
                  )
                WHERE rownum = 1;
            EXCEPTION
            WHEN OTHERS THEN
               l_err_msg := 'Error while selecting data from cms_appl_pan';
               RAISE e_exception;
            END;
            
            
            BEGIN 
                SELECT cpc_encrypt_enable
                INTO l_encrypt_enable
                FROM cms_prod_cattype
                WHERE cpc_inst_code = 1
                AND cpc_prod_code   = l_prod_code
                AND cpc_card_type   = l_card_type;
            EXCEPTION
            WHEN OTHERS THEN
               l_err_msg := 'Error while selecting encrypt enable flag from cms_prod_cattype';
               RAISE e_exception;
            END;
            
            BEGIN	 
                UPDATE cms_addr_mast
                SET cam_add_one_encr = DECODE(l_encrypt_enable,'Y',cam_add_one,fn_emaps_main(cam_add_one)),
                  cam_add_two_encr   = DECODE(l_encrypt_enable,'Y',cam_add_two,fn_emaps_main(cam_add_two)),
                  cam_city_name_encr = DECODE(l_encrypt_enable,'Y',cam_city_name,fn_emaps_main(cam_city_name)),
                  cam_pin_code_encr  = DECODE(l_encrypt_enable,'Y',cam_pin_code,fn_emaps_main(cam_pin_code)),
                  cam_email_encr     = DECODE(l_encrypt_enable,'Y',cam_email,fn_emaps_main(cam_email))
                WHERE cam_inst_code  = 1
                AND cam_cust_code    = l_idx.ccm_cust_code;
            EXCEPTION
            WHEN OTHERS THEN
               l_err_msg := 'Error while updating cms_addr_mast';
               RAISE e_exception;
            END;
            
            BEGIN
                UPDATE cms_cust_mast
                SET ccm_first_name_encr = DECODE(l_encrypt_enable,'Y',ccm_first_name,fn_emaps_main(ccm_first_name)),
                  ccm_last_name_encr    = DECODE(l_encrypt_enable,'Y',ccm_last_name,fn_emaps_main(ccm_last_name)),
                  ccm_user_name_encr    = DECODE(l_encrypt_enable,'Y',ccm_user_name,fn_emaps_main(ccm_user_name))
                WHERE ccm_inst_code     = 1
                AND ccm_cust_code       = l_idx.ccm_cust_code;
            EXCEPTION
            WHEN OTHERS THEN
               l_err_msg := 'Error while updating cms_cust_mast';
               RAISE e_exception;
            END;
            
            BEGIN 
              UPDATE cms_caf_info_entry
              SET cci_seg12_name_line1_encr    = DECODE(l_encrypt_enable,'Y',cci_seg12_name_line1,
                                               fn_emaps_main(cci_seg12_name_line1)),
                cci_seg12_name_line2_encr      = DECODE(l_encrypt_enable,'Y',cci_seg12_name_line2,
                                               fn_emaps_main(cci_seg12_name_line2)),
                cci_seg12_addr_line1_encr      = DECODE(l_encrypt_enable,'Y',cci_seg12_addr_line1,
                                               fn_emaps_main(cci_seg12_addr_line1)),
                cci_seg12_addr_line2_encr      = DECODE(l_encrypt_enable,'Y',cci_seg12_addr_line2,
                                               fn_emaps_main(cci_seg12_addr_line2)),
                cci_seg12_city_encr            = DECODE(l_encrypt_enable,'Y',cci_seg12_city,
                                               fn_emaps_main(cci_seg12_city)),
                cci_seg12_postal_code_encr     = DECODE(l_encrypt_enable,'Y',cci_seg12_postal_code,
                                               fn_emaps_main(cci_seg12_postal_code)),
                cci_seg12_emailid_encr         = DECODE(l_encrypt_enable,'Y',cci_seg12_emailid,
                                               fn_emaps_main(cci_seg12_emailid))
               WHERE cci_inst_code = 1
               AND cci_appl_code = to_char(l_appl_code);
			   
             EXCEPTION
             WHEN OTHERS THEN
               l_err_msg := 'Error while updating cms_caf_info_entry';
               RAISE e_exception;
             END;
	   EXCEPTION		 
       WHEN e_exception 
	   THEN
			INSERT
			INTO vms_error_log
			  (
				vel_pan_code,
				vel_error_msg,
				vel_ins_date
			  )
			  VALUES
			  (
				'VMS_RSJ020 '
				|| l_idx.ccm_cust_code,
				l_err_msg,
				SYSDATE
			  );	
       WHEN OTHERS 
	   THEN
          l_err_msg := 'Error in loop'|| SUBSTR (SQLERRM, 1, 200);
		  
			INSERT
			INTO vms_error_log
			  (
				vel_pan_code,
				vel_error_msg,
				vel_ins_date
			  )
			  VALUES
			  (
				'VMS_RSJ020 '
				|| l_idx.ccm_cust_code,
				l_err_msg,
				SYSDATE
			  );	
	   END;

      END LOOP;
      COMMIT;
	  
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      l_err_msg := 'Error from main' || l_err_msg || SUBSTR (SQLERRM, 1, 200);
		INSERT
		INTO vms_error_log
		  (
			vel_pan_code,
			vel_error_msg,
			vel_ins_date
		  )
		  VALUES
		  (
			'VMS_RSJ020',
			l_err_msg,
			SYSDATE
		  );
END;
/
show error