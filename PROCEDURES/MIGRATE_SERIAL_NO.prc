create or replace
PROCEDURE               vmscms.MIGRATE_SERIAL_NO(p_serl_flag_in in number)
AS
   l_ctrl_numb        cms_pan_ctrl.cpc_ctrl_numb%TYPE;
   l_max_serlno       cms_pan_ctrl.cpc_max_serial_no%TYPE;
   l_serl_no          shuffle_array_typ;
   l_shuffle_serlno   shuffle_array_typ;
   l_migr_excp        EXCEPTION;
   l_tmp_pan          VARCHAR2 (100);
   l_max_len          NUMBER;
   l_inst_code        NUMBER := 1;
   l_err_msg          VARCHAR2 (1000);
   l_migrate_error    VARCHAR2(2) := 'S';
   L_temp_Max_Serlno       Cms_Pan_Ctrl.Cpc_Max_Serial_No%Type;
   L_Temp_Serlno           Cms_Pan_Ctrl.Cpc_Max_Serial_No%Type;
   L_No_Serials_To_Gen     Cms_Pan_Ctrl.Cpc_Ctrl_Numb%Type;
   l_serial_limit          Cms_Pan_Ctrl.Cpc_Max_Serial_No%Type := 999999;

   PROCEDURE lp_get_tmppan (p_prod_prefix_in        VARCHAR2,
                            p_prod_bin_in           VARCHAR2,
                            p_card_type_in          VARCHAR2,
                            p_profile_code_in       VARCHAR2,
                            p_max_len_out       OUT NUMBER,
                            p_tmppan_out        OUT VARCHAR2,
                            p_errmsg_out        OUT VARCHAR2)
   AS
   BEGIN
      p_errmsg_out := 'OK';
      p_tmppan_out := NULL;
      FOR i
         IN (SELECT cpc_profile_code,
                    cpc_field_name,
                    cpc_start_from,
                    cpc_length,
                    cpc_start
               FROM cms_pan_construct
              WHERE cpc_profile_code = p_profile_code_in
                    AND cpc_inst_code = l_inst_code
                    order by cpc_start_from)
                    
      LOOP
         
         IF i.cpc_field_name = 'Card Type'
         THEN
            p_tmppan_out:=p_tmppan_out|| LPAD ( SUBSTR (TRIM (p_card_type_in), i.cpc_start, i.cpc_length), i.cpc_length,'0');
          ELSIF i.cpc_field_name = 'BIN / PREFIX'
         THEN
            p_tmppan_out:=p_tmppan_out||LPAD ( SUBSTR (TRIM (p_prod_bin_in), i.cpc_start, i.cpc_length),  i.cpc_length, '0');
         ELSIF i.cpc_field_name = 'PAN Product Category Prefix'
         THEN
            p_tmppan_out:=p_tmppan_out||LPAD ( SUBSTR (TRIM (p_prod_prefix_in), i.cpc_start, i.cpc_length), i.cpc_length,'0');
         ELSIF i.cpc_field_name = 'Serial Number'
         THEN
            p_max_len_out := i.cpc_length;
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg_out :=
            'Error while getting temp PAN:' || SUBSTR (SQLERRM, 1, 200);
   END;
BEGIN
   l_err_msg := 'OK';

   FOR idx
      IN (SELECT cpc_prod_code,
                 cpc_card_type,
                 cpc_profile_code,
                 cpc_prod_prefix,
                 cpc_serl_flag,
                 cpb_inst_bin
            FROM cms_prod_cattype, cms_prod_bin
           WHERE     NVL (cpc_pan_inventory_flag, 'N') = 'N'
                 AND cpb_inst_code = cpc_inst_code
                 AND cpb_prod_code = cpc_prod_code
                 AND cpc_serl_flag=p_serl_flag_in
                 AND cpb_active_bin = 'Y')
   LOOP
      BEGIN
      
         l_migrate_error := 'S';
         lp_get_tmppan (idx.cpc_prod_prefix,
                        idx.cpb_inst_bin,
                        idx.cpc_card_type,
                        idx.cpc_profile_code,
                        l_max_len,
                        l_tmp_pan,
                        l_err_msg);

         IF l_err_msg <> 'OK'
         THEN
            RAISE l_migr_excp;
         END IF;

         BEGIN
            IF idx.cpc_serl_flag = 0
            THEN
               SELECT cpc_ctrl_numb, cpc_max_serial_no
                 INTO l_ctrl_numb, l_max_serlno
                 FROM cms_pan_ctrl
                WHERE cpc_pan_prefix = l_tmp_pan
                      AND cpc_inst_code = l_inst_code;
            ELSE
               SELECT csc_shfl_cntrl, LPAD ('9', l_max_len, 9)
                 INTO l_ctrl_numb, l_max_serlno
                 FROM cms_shfl_cntrl
                WHERE     csc_inst_code = l_inst_code
                      AND csc_prod_code = idx.cpc_prod_code
                      AND csc_card_type = idx.cpc_card_type;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_ctrl_numb := 1;
               l_max_serlno := LPAD ('9', l_max_len, 9);
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while getting running serials:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE l_migr_excp;
         END;
         
         IF l_ctrl_numb <= l_max_serlno THEN
             BEGIN
                INSERT INTO vms_pan_ctrl_inv (vpc_inst_code,
                                              vpc_prod_code,
                                              vpc_prod_catg,
                                              vpc_prod_prefix,
                                              vpc_ctrl_numb,
                                              vpc_min_serlno,
                                              vpc_max_serlno,
                                              vpc_ins_date,
                                              vpc_ins_user)
                     VALUES (l_inst_code,
                             idx.cpc_prod_code,
                             idx.cpc_card_type,
                             idx.cpc_prod_prefix,
                             l_ctrl_numb,
                             l_ctrl_numb,
                             l_max_serlno,
                             SYSDATE,
                             1);
             EXCEPTION
                WHEN OTHERS
                THEN
                   l_err_msg :=
                      'Error while inserting serials:'
                      || SUBSTR (SQLERRM, 1, 200);
                   RAISE l_migr_excp;
             END;
         ELSE
            l_err_msg :=
                      'The existing control number is greater than the maximum serial number';
            l_migrate_error := 'E';
         END IF;

         IF idx.cpc_serl_flag = 1
         THEN
            INSERT INTO vms_shfl_serl_inv (vss_inst_code,
                                           vss_prod_code,
                                           vss_prod_catg,
                                           vss_prod_prefix,
                                           vss_serl_numb,
                                           vss_shfl_cntrl,
                                           vss_ins_user,
                                           vss_ins_date)
               SELECT css_inst_code,
                      css_prod_code,
                      css_prod_catg,
                      idx.cpc_prod_prefix,
                      css_serl_numb,
                      css_shfl_cntrl,
                      1,
                      SYSDATE
                 FROM cms_shfl_serl
                WHERE     css_inst_code = l_inst_code
                      AND css_prod_code = idx.cpc_prod_code
                      AND css_prod_catg = idx.cpc_card_type
                      AND css_shfl_cntrl >= l_ctrl_numb
                      AND css_shfl_cntrl <= l_max_serlno
                      AND css_serl_flag = 0;
 
            IF SQL%ROWCOUNT > 0
            THEN
               SELECT MAX (css_shfl_cntrl) + 1
                 INTO l_ctrl_numb
                 FROM cms_shfl_serl
                WHERE     css_inst_code = l_inst_code
                      AND css_prod_code = idx.cpc_prod_code
                      AND css_prod_catg = idx.cpc_card_type
                      AND css_serl_flag = 0;
            END IF;

           L_temp_Max_Serlno:= l_max_serlno;
            IF l_ctrl_numb < l_max_serlno
            THEN
               Loop
                  If L_Temp_Max_Serlno  > l_serial_limit Then
                     L_Temp_Serlno := L_Temp_Max_Serlno - l_serial_limit;  -- 89  -79 --19  -9
                     l_no_serials_to_gen := l_serial_limit;
                  Else
                     L_Temp_Serlno := 0;
                     l_no_serials_to_gen := L_temp_Max_Serlno;
                  End If;
                  If L_Ctrl_Numb + L_No_Serials_To_Gen > L_Max_Serlno Then
                     l_no_serials_to_gen := l_max_serlno - L_Ctrl_Numb + 1; 
                  end if;
               BEGIN
                  SELECT serials
                    BULK COLLECT INTO l_serl_no
                    FROM (    SELECT ROWNUM + L_Ctrl_Numb - 1 serials
                                FROM DUAL
                          CONNECT BY LEVEL <= l_no_serials_to_gen)
                   WHERE serials >= l_ctrl_numb;

                  VMSCARD.get_shuffle_serials (l_ctrl_numb,					--modified for VMS_7147
                                       l_ctrl_numb + l_no_serials_to_gen - 1,
                                       l_shuffle_serlno);

                  FORALL i IN 1 .. l_serl_no.COUNT
                     INSERT INTO vms_shfl_serl_inv (vss_inst_code,
                                                    vss_prod_code,
                                                    vss_prod_catg,
                                                    vss_prod_prefix,
                                                    vss_serl_numb,
                                                    vss_shfl_cntrl,
                                                    vss_ins_user,
                                                    vss_ins_date)
                          VALUES (l_inst_code,
                                  idx.cpc_prod_code,
                                  idx.cpc_card_type,
                                  idx.cpc_prod_prefix,
                                  l_shuffle_serlno (i),
                                  l_serl_no (i),
                                  1,
                                  SYSDATE);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_err_msg :=
                        'Error while inserting shuffle serials:'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE l_migr_excp;
               END;
                L_Ctrl_Numb := L_Ctrl_Numb  + L_No_Serials_To_Gen;  -- 11  --21  -31 -41 -51-61-71-81  -91
                L_temp_Max_Serlno := L_temp_Serlno; --89 -79   -19  9
               If L_Temp_Serlno = 0  or  L_Ctrl_Numb >= l_max_serlno Then
                  Exit;
               End If;
               end loop;  
            END IF;
         END IF;
      
         BEGIN
             INSERT INTO vms_migrate_serialno
                                             (vms_prod_code,
                                              vms_card_type,
                                              vms_migrate_flag,
                                              vms_error_msg)
                        VALUES(idx.cpc_prod_code,
                               idx.cpc_card_type,
                               l_migrate_error,
                               l_err_msg);
             EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_err_msg :=
                        'Error while inserting into vms_migrate_serialno :'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE l_migr_excp;
         END;
         
      EXCEPTION
         WHEN l_migr_excp
         THEN
            ROLLBACK;
            l_migrate_error := 'E';
             INSERT INTO vms_migrate_serialno
                                             (vms_prod_code,
                                              vms_card_type,
                                              vms_migrate_flag,
                                              vms_error_msg)
                        VALUES(idx.cpc_prod_code,
                               idx.cpc_card_type,
                               l_migrate_error,
                               l_err_msg);
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_err_msg :=
               'Error while get_temp_acct::' || SUBSTR (SQLERRM, 1, 200);
            EXIT;
      END;

      COMMIT;
   END LOOP;

END;
/
show error