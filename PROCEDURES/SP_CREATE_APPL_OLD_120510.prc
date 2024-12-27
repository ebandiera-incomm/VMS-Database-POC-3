CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_appl_old_120510 (
   instcode                   IN       NUMBER,
   assocode                   IN       NUMBER,
   insttype                   IN       NUMBER,
   applno                     IN       VARCHAR2,
   appldate                   IN       DATE,
   regdate                    IN       DATE,
   custcode                   IN       NUMBER,
   applbran                   IN       VARCHAR2,
   prodcode                   IN       VARCHAR2,
   cardtype                   IN       NUMBER,
   custcatg                   IN       NUMBER,
   activedate                 IN       DATE,
   exprydate                  IN       DATE,
   dispname                   IN       VARCHAR2,
   limtamt                    IN       NUMBER,
   addonissu                  IN       CHAR,
   usagelimt                  IN       NUMBER,
   totacct                    IN       NUMBER,
   addonstat                  IN       CHAR,
   addonlink                  IN       NUMBER,
   billaddr                   IN       NUMBER,
   chnlcode                   IN       NUMBER,
   request_id                 IN       VARCHAR2,
   payment_ref                IN       VARCHAR2,
   appluser                   IN       NUMBER,
   lupduser                   IN       NUMBER,
   prm_initial_topup_amount   IN       NUMBER,
   applcode                   OUT      NUMBER,
   errmsg                     OUT      VARCHAR2
)
AS
   trueaddonlink     NUMBER (20);
   v_cpc_catg_appl   VARCHAR2 (2);
   v_cam_bill_addr   cms_appl_pan.cap_bill_addr%TYPE;
   v_appl_stat       cms_appl_mast.cam_appl_stat%TYPE;
   v_pay_ref         cms_appl_mast.cam_payment_ref%TYPE;
   v_host_proc       cms_inst_param.cip_param_value%TYPE;
BEGIN                                           --Main Begin Block Starts Here
   BEGIN
      SELECT cpc_catg_appl
        INTO v_cpc_catg_appl
        FROM cms_prod_catg
       WHERE cpc_inst_code = instcode
         AND cpc_catg_code =
                (SELECT cpm_catg_code
                   FROM cms_prod_mast
                  WHERE cpm_inst_code = instcode AND cpm_prod_code = prodcode);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         errmsg := ' no data found for prod code: ' || prodcode;
         -- stop processing, since master setup is not complete
         RETURN;
      -- EN Shekar 18.Feb.06, error handler modified for pcms
      WHEN OTHERS
      THEN
         -- SN Shekar 18.Feb.06, error handler modified for pcms
         errmsg := 'when others: ' || SQLERRM;
         -- stop processing, since master setup is not complete
         RETURN;
   -- EN Shekar 18.Feb.06, error handler modified for pcms
   END;

   v_cpc_catg_appl := LPAD (v_cpc_catg_appl, 2, 0);

   IF addonstat = 'P' AND addonlink = 0
   THEN                                                                 --IF 2
      SELECT    TO_CHAR (SYSDATE, 'yyyy')
             || v_cpc_catg_appl
             || LPAD (seq_appl_code.NEXTVAL, 8, 0)
        INTO applcode
        FROM DUAL;

      trueaddonlink := applcode;
   ELSIF addonstat IN ('A', 'B') AND addonlink IS NOT NULL
   THEN                                                                 --IF 2
      SELECT    TO_CHAR (SYSDATE, 'yyyy')
             || v_cpc_catg_appl
             || LPAD (seq_appl_code.NEXTVAL, 8, 0)
        INTO applcode
        FROM DUAL;

      trueaddonlink := addonlink;
   END IF;                                                       --End of IF 2

   IF addonstat = 'A'
   THEN
      SELECT cam_bill_addr
        INTO v_cam_bill_addr
        FROM cms_appl_mast
       WHERE cam_appl_code = addonlink;
   ELSE
      v_cam_bill_addr := billaddr;
   END IF;

   IF request_id IS NOT NULL
   THEN
      v_appl_stat := 'I';
   ELSE
      BEGIN
         SELECT cip_param_value
           INTO v_host_proc
           FROM cms_inst_param
          WHERE cip_inst_code = instcode AND cip_param_key = 'REQ_HOST_PROC';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_host_proc := 'N';
      END;

      IF v_host_proc = 'Y'
      THEN
         v_appl_stat := 'R';
      ELSE
         v_appl_stat := 'P';
      END IF;
   END IF;

   INSERT INTO cms_appl_mast
               (cam_inst_code, cam_asso_code, cam_inst_type, cam_appl_code,
                cam_appl_no, cam_appl_date, cam_reg_date, cam_cust_code,
                cam_appl_bran, cam_prod_code, cam_card_type, cam_cust_catg,
                cam_active_date, cam_expry_date, cam_disp_name,
                cam_limit_amt, cam_use_limit, cam_addon_issu, cam_tot_acct,
                cam_addon_stat, cam_addon_link, cam_bill_addr, cam_chnl_code,
                cam_request_id, cam_payment_ref, cam_appl_stat,
                cam_appl_user, cam_lupd_user, cam_process_msg, cam_ins_date,
                cam_ins_user
               )
        VALUES (instcode, assocode, insttype, applcode,
                applno, appldate, regdate, custcode,
                applbran, prodcode, cardtype, custcatg,
                activedate, LAST_DAY (exprydate), dispname,
                limtamt, usagelimt, addonissu, totacct,
                addonstat, trueaddonlink, v_cam_bill_addr, chnlcode,
                request_id, payment_ref, v_appl_stat,
                appluser, lupduser, 'Successful', SYSDATE,
                lupduser
               );

   DBMS_OUTPUT.put_line ('After appl insert');
   errmsg := 'OK';
EXCEPTION                                               --Main block Exception
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.put_line (   '    '
                            || prodcode
                            || ' '
                            || cardtype
                            || ' '
                            || custcatg
                           );
      errmsg := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
END;                                              --Main Begin Block Ends Here
/


