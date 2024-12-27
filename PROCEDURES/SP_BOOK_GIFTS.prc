CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Book_Gifts  (
   instcode       IN       NUMBER,
   acctid         IN       NUMBER,
   SOURCE         IN       VARCHAR2,
   planid         IN       VARCHAR2,
   strofitemqty   IN       VARCHAR2,  
   orderworth     IN       NUMBER,
--the worth of order in loyalty points...the account will be debited for thesemuch loyalty points
   --bookdate  IN    date     ,
   custname       IN       VARCHAR2,
   addrflag       IN       VARCHAR2,
--'N' means use the new address, 'E' means use the existing one using the addrcode parameter
   addrcode       IN       NUMBER,
   addrline1      IN       VARCHAR2,
   addrline2      IN       VARCHAR2,
   addrline3      IN       VARCHAR2,
   addrline4      IN       VARCHAR2,
   cityname       IN       VARCHAR2,
   pincode        IN       VARCHAR2,
   stdcode        IN       VARCHAR2,
   phonenumb      IN       VARCHAR2,
   lupduser       IN       NUMBER,
   giftorder      OUT      VARCHAR2,
   errmsg         OUT      VARCHAR2
)
AS
   v_cam_acct_no      VARCHAR2 (20);
   v_cca_cust_code    NUMBER (10);
   v_cap_pan_code     VARCHAR2 (20);
   v_cap_card_stat    VARCHAR2 (1);
   gift_charges       NUMBER (2);
   v_ccm_first_name   VARCHAR2 (30);
   v_cam_add_one      VARCHAR2 (30);
   v_cam_add_two      VARCHAR2 (30);
   v_cam_add_three    VARCHAR2 (30);
   v_cam_add_four     VARCHAR2 (30);
   v_cam_city_name    VARCHAR2 (20);
   v_cam_pin_code     VARCHAR2 (6);
   v_cam_phone_one    VARCHAR2 (15);
   v_cam_std_code     VARCHAR2 (5);
   itemid             VARCHAR2 (6);
   itemqty            VARCHAR2 (2);
   tabvar1            Gen_Cms_Pack.plsql_tab_single_column;
   ---variable of plsqltable type defined in gen_cms_pack;
   tabvar2            Gen_Cms_Pack.plsql_tab_single_column;
   v_unclaimed_loyl   NUMBER (10);
   v_threshold_loyl   VARCHAR2 (10);
   v_check_point	  NUMBER(6);

   ---variable of plsqltable type defined in gen_cms_pack;
   PROCEDURE lp_insert_into_cms_gift_trans (
      acctno      IN       VARCHAR2,
      pancode     IN       VARCHAR2,
      giftorder   IN       VARCHAR2,
      itemid      IN       VARCHAR2,
      itemqty     IN       VARCHAR2,
      custname    IN       VARCHAR2,
      addr1       IN       VARCHAR2,
      addr2       IN       VARCHAR2,
      addr3       IN       VARCHAR2,
      addr4       IN       VARCHAR2,
      city        IN       VARCHAR2,
      pincode     IN       VARCHAR2,
      stdcode     IN       VARCHAR2,
      phone       IN       VARCHAR2,
      lperr1      OUT      VARCHAR2
   )
   IS
   BEGIN                                                          --begin lp1
      lperr1 := 'OK';

      INSERT INTO CMS_GIFT_TRANS
                  (cgt_inst_code, cgt_acct_no, cgt_sr_no, cgt_source_code,
                   cgt_record_type, cgt_pan_code, cgt_gift_order,
                   cgt_redemp_code, cgt_stat_code, cgt_airway_billno,
                   cgt_item_id, cgt_item_qty, cgt_req_date, cgt_post_date,
                   cgt_apprv_date, cgt_cust_name, cgt_addr_line1,
                   cgt_addr_line2, cgt_addr_line3,
                   cgt_addr_line4, cgt_city_name,
                   cgt_pin_code, cgt_std_code,
                   cgt_phone_numb, cgt_reject_rsn, cgt_file_name,
                   cgt_ins_user, cgt_lupd_user, cgt_plan_id
                  )
           VALUES (instcode, acctno, NULL, SOURCE,
                   RPAD (' ', 2, ' '), pancode, giftorder,
                   RPAD (' ', 3, ' '), 'APP', RPAD (' ', 12, ' '),
                   itemid, LPAD (itemqty, 2, '0'), SYSDATE, NULL,
                   NULL, RPAD (custname, 30, ' '), RPAD (addr1, 30, ' '),
                   RPAD (addr2, 30, ' '), RPAD (addr3, 30, ' '),
                   RPAD (addr4, 30, ' '), RPAD (city, 20, ' '),
                   RPAD (pincode, 6, ' '), RPAD (stdcode, 5, ' '),
                   RPAD (phone, 7, ' '), NULL, 'N',
                   lupduser, lupduser, planid
                  );
   EXCEPTION                                               --excp of begin lp1
      WHEN OTHERS
      THEN
         lperr1 := 'LP1 Main Exception -- ' || SQLERRM;
   END;                                                          --end begin 1
/*********************************************************************************/
BEGIN                                                             --main begin
   errmsg := 'OK';

   BEGIN                                                            --begin 1
      SELECT cam_acct_no, cam_unclaimed_loyl
        INTO v_cam_acct_no, v_unclaimed_loyl
        FROM CMS_ACCT_MAST
       WHERE cam_inst_code = instcode AND cam_acct_id = acctid;
   EXCEPTION                                                          --excp 1
      WHEN OTHERS
      THEN
         errmsg := 'Excp 1 -- ' || SQLERRM;
   END;  
   
  -- IF v_unclaimed_loyl <= 0 THEN
   --	  errmsg := 'Customer is not eligable for gifts : loyalty points less than or equal to zero';
  -- END IF;

                                                           --end begin 1

   IF errmsg = 'OK'
   THEN
      BEGIN
         SELECT TO_NUMBER (cip_param_value)
           INTO v_threshold_loyl
           FROM CMS_INST_PARAM
          WHERE cip_inst_code = instcode AND cip_param_key = 'THRESHOLD LOYL';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            errmsg := 'ThreshHold loyalty is not defined ' || SQLERRM;
         WHEN OTHERS
         THEN
            errmsg := 'ThreshHold loyalty is not defined ' || SQLERRM;
      END;

      IF errmsg = 'OK'
      THEN
         IF v_unclaimed_loyl < v_threshold_loyl
         THEN
            errmsg :=
                  'Customer is not eligable for the gift, loyalty point is less then '
               || v_threshold_loyl;
         END IF;
      END IF;

      IF errmsg = 'OK'
      THEN
         BEGIN                                                      --begin 2
            SELECT cca_cust_code
              INTO v_cca_cust_code
              FROM CMS_CUST_ACCT
             WHERE (cca_cust_code, cca_acct_id) IN (
                       SELECT cpa_cust_code, cpa_acct_id
                         FROM CMS_PAN_ACCT
                        WHERE cpa_inst_code = instcode
                                -- this clause on inst_code has been added to optimize
                              -- the query so that index will be used
                              AND cpa_acct_id = acctid)
               AND cca_hold_posn = 1;
         EXCEPTION                                                    --excp 2
            WHEN OTHERS
            THEN
               errmsg := 'Excp 2 -- ' || SQLERRM;
         END;
      END IF;                                                    --end begin 2
   END IF;

--dbms_output.put_line('CKPT2');
   IF errmsg = 'OK'
   THEN
      BEGIN                                                         --begin 3
         -- ################  This query has to be optimized  #################
         /*
         SELECT   cap_pan_code,cap_card_stat
         INTO  v_cap_pan_code,v_cap_card_stat
         FROM  cms_appl_pan
         WHERE cap_cust_code  = v_cca_cust_code
         AND   cap_acct_id = acctid;
         */

         -- commented the above query to force the index on appl_pan
         SELECT /* +INDEX(CMS_APPL_PAN INDX_APPLPAN_INSTCAFGEN)*/ cap_pan_code, cap_card_stat
           INTO  v_cap_pan_code, v_cap_card_stat
           FROM CMS_APPL_PAN
          WHERE cap_inst_code = 1
            AND cap_cafgen_flag = 'Y'
            AND cap_cust_code = v_cca_cust_code
            AND cap_acct_id = acctid;

         IF v_cap_card_stat IN ('9', 'F')
         THEN
            errmsg :=
               'Validation Failed. Card No. ' || v_cap_pan_code
               || ' Expired.';
         END IF;
      EXCEPTION                                                       --excp 3
         WHEN OTHERS
         THEN
            errmsg := 'Excp 3 -- ' || SQLERRM;
      END;                                                       --end begin 3
   END IF;

   IF errmsg = 'OK'
   THEN
      IF addrflag = 'E'
      THEN
         BEGIN                                                      --begin 4
            SELECT ccm_first_name, cam_add_one, cam_add_two,
                   cam_add_three, cam_city_name, cam_pin_code,
                   cam_phone_one
              INTO v_ccm_first_name, v_cam_add_one, v_cam_add_two,
                   v_cam_add_three, v_cam_city_name, v_cam_pin_code,
                   v_cam_phone_one
              FROM CMS_CUST_MAST, CMS_ADDR_MAST
             WHERE ccm_inst_code = cam_inst_code
               AND ccm_cust_code = cam_cust_code
               AND cam_cust_code = v_cca_cust_code
               AND cam_addr_code = addrcode;
         EXCEPTION                                                    --excp 4
            WHEN OTHERS
            THEN
               errmsg := 'Excp 4 -- ' || SQLERRM;
         END;                                                    --end begin 4
      ELSIF addrflag = 'N'
      THEN
         v_ccm_first_name := custname;
         v_cam_add_one := NVL (addrline1, ' ');
         v_cam_add_two := NVL (addrline2, ' ');
         v_cam_add_three := NVL (addrline3, ' ');
         v_cam_add_four := NVL (addrline4, ' ');
         v_cam_city_name := NVL (cityname, ' ');
         v_cam_phone_one := NVL (phonenumb, ' ');
         v_cam_pin_code := NVL (pincode, ' ');
         v_cam_std_code := NVL (stdcode, ' ');
      END IF;
   END IF;

   IF errmsg = 'OK'
   THEN
      SELECT    'gb'
             || TO_CHAR (SYSDATE, 'DDMMYYYY')
             || LPAD (seq_item_trans.NEXTVAL, 4, 0)
        INTO giftorder
        FROM DUAL;

      Tokenise (strofitemqty, '~', tabvar1, errmsg);

      FOR x IN 1 .. tabvar1.COUNT
      LOOP
         IF errmsg = 'OK'
         THEN
            Tokenise (tabvar1 (x), '^', tabvar2, errmsg);

            FOR y IN 1 .. tabvar2.COUNT
            LOOP
               IF y = 1
               THEN
                  itemid := tabvar2 (y);
               ELSIF y = 2
               THEN
                  itemqty := tabvar2 (y);
               END IF;
            END LOOP;

            lp_insert_into_cms_gift_trans (v_cam_acct_no,
                                           v_cap_pan_code,
                                           giftorder,
                                           itemid,
                                           itemqty,
                                           v_ccm_first_name,
                                           v_cam_add_one,
                                           v_cam_add_two,
                                           v_cam_add_three,
                                           v_cam_add_four,
                                           v_cam_city_name,
                                           v_cam_pin_code,
                                           v_cam_std_code,
                                           v_cam_phone_one,
                                           errmsg
                                          );
         ELSE
            EXIT;
         END IF;
      END LOOP;
	  
	  --IF errmsg = 'OK' THEN
	  	  
	  
	  
	 -- END IF;

      IF errmsg = 'OK'
      THEN
         SELECT TO_NUMBER (cip_param_value)
           INTO gift_charges
           FROM CMS_INST_PARAM
          WHERE cip_inst_code = instcode AND cip_param_key = 'LOYL PER ORDER';
		  
		 v_check_point := v_unclaimed_loyl - (orderworth + gift_charges);
		  
		  IF v_check_point < 0 THEN
		  errmsg := 'Earned loyalty points is less than gift redemption points';
		  
		  END IF;
	  
		  	
			
			
	   END IF;
	   IF 	errmsg = 'OK' THEN

         UPDATE CMS_ACCT_MAST
            SET cam_unclaimed_loyl =
                              cam_unclaimed_loyl
                              - (orderworth + gift_charges),
                cam_lupd_user = lupduser
          WHERE cam_inst_code = instcode AND cam_acct_id = acctid;

         IF SQL%ROWCOUNT != 1
         THEN
            errmsg :=
               'Problem in updation of unclaimed loyalty points for the account.';
         END IF;
      END IF;
   END IF;
EXCEPTION                                                     --main exception
   WHEN OTHERS
   THEN
      errmsg := 'Main Exception -- ' || SQLERRM;
END;                                                         --main begin ends
/


show error