CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Initialload_Pan (
   prm_instcode       IN       NUMBER,
   prm_rrn            IN       VARCHAR2,
   prm_terminalid     IN       VARCHAR2,
   prm_stan           IN       VARCHAR2,
   prm_trandate       IN       VARCHAR2,
   prm_trantime       IN       VARCHAR2,
   prm_acctno         IN       VARCHAR2,
   prm_filename       IN       VARCHAR2,
   prm_remrk          IN       VARCHAR2,
   prm_resoncode      IN       NUMBER,
   prm_amount         IN       NUMBER,
   prm_refno          IN       VARCHAR2,
   prm_paymentmode    IN       VARCHAR2,
   prm_instrumentno   IN       VARCHAR2,
   prm_drawndate      IN       DATE,
   prm_currcode       IN       VARCHAR2,
   prm_lupduser       IN       NUMBER,
   prm_auth_message   OUT      VARCHAR2,
   prm_errmsg         OUT      VARCHAR2
)
AS
   v_cap_prod_catg          CMS_APPL_PAN.cap_prod_catg%TYPE;
   v_cap_card_stat          CMS_APPL_PAN.cap_card_stat%TYPE;
   v_cap_cafgen_flag        CMS_APPL_PAN.cap_cafgen_flag%TYPE;
   v_cap_appl_code          CMS_APPL_PAN.cap_appl_code%TYPE;
   v_firsttime_topup        CMS_APPL_PAN.cap_firsttime_topup%TYPE;
   v_errmsg                 VARCHAR2 (300);
   v_varprodflag            CMS_PROD_MAST.cpm_var_flag%TYPE;
   v_currcode               VARCHAR2 (3);
   v_appl_code              CMS_APPL_MAST.cam_appl_code%TYPE;
   v_resoncode              CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
   v_respcode               VARCHAR2 (5);
   v_respmsg                VARCHAR2 (500);
   v_authmsg                VARCHAR2 (500);
   v_capture_date           DATE;
   v_mbrnumb                CMS_APPL_PAN.cap_mbr_numb%TYPE;
   v_txn_code               CMS_FUNC_MAST.cfm_txn_code%TYPE;
   v_txn_mode               CMS_FUNC_MAST.cfm_txn_mode%TYPE;
   v_del_channel            CMS_FUNC_MAST.cfm_delivery_channel%TYPE;
   v_txn_type               CMS_FUNC_MAST.cfm_txn_type%TYPE;
   v_inil_authid            TRANSACTIONLOG.auth_id%TYPE;
   exp_main_reject_record   EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
 v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;


BEGIN                                                        --<<MAIN BEGIN >>
   prm_errmsg := 'OK';
   prm_auth_message := 'OK';

--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(prm_acctno);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_main_reject_record;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(prm_acctno);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_main_reject_record;
END;
--EN create encr pan


   IF prm_remrk IS NULL
   THEN
      v_errmsg := 'Please enter appropriate remrk';
      RAISE exp_main_reject_record;
   END IF;

   --Sn select Pan detail
   BEGIN
      SELECT cap_card_stat, cap_prod_catg, cap_cafgen_flag,
             cap_appl_code, cap_firsttime_topup, cap_mbr_numb
        INTO v_cap_card_stat, v_cap_prod_catg, v_cap_cafgen_flag,
             v_appl_code, v_firsttime_topup, v_mbrnumb
        FROM CMS_APPL_PAN
        WHERE cap_pan_code =v_hash_pan; -- prm_acctno;
/*
      IF v_cap_cafgen_flag = 'N'
      THEN
         v_errmsg := 'CAF has to be generated atleast once for this pan ';
         RAISE exp_main_reject_record;
      END IF;
*/
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Invalid Card number ' || prm_acctno;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while selecting card number ' || prm_acctno;
         RAISE exp_main_reject_record;

   END;

   --En select Pan detail
   --Sn Check initial load
   IF v_firsttime_topup = 'Y'
   THEN
      v_errmsg :=
         'Initial load already done for the account number ,Please try TOPUP';
      RAISE exp_main_reject_record;
   ELSE
      IF TRIM (v_firsttime_topup) IS NULL
      THEN
         v_errmsg := 'Invalid Initial load Parameter';
         RAISE exp_main_reject_record;
      END IF;
   END IF;

   --En Check initial load
   --Sn select transaction code,mode and del channel
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'INILOAD' and cfm_inst_code=prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Support function Initial Load not defined in master';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting support function detail '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En select transaction code,mode and del channel
   --Sm For Debit Card No Need of doing authorization
   
   IF v_cap_prod_catg = 'P' THEN
   
   --Sn call to authorize txn
   BEGIN
      v_currcode := prm_currcode;
      Sp_Authorize_Txn (prm_instcode,
                        '210',
                        prm_rrn,
                        v_del_channel,
                        prm_terminalid,
                        v_txn_code,
                        --'1',
                        v_txn_mode,
                        prm_trandate,
                        prm_trantime,
                        prm_acctno,
                        NULL,
                        prm_amount,
                        NULL,
                        NULL,
                        NULL,
                        v_currcode,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        --NULL,
                        NULL,
                        NULL,
                        prm_stan,
                        prm_lupduser,                               --Ins User
                        SYSDATE,                                    --INS Date
                        v_inil_authid,
                        v_respcode,
                        v_respmsg,
                        v_capture_date
                       );

      IF v_respcode <> '00' AND v_respmsg <> 'OK'
      THEN
         v_authmsg := v_respmsg;
         --v_errmsg := 'Error from auth process' || v_respmsg;
         RAISE exp_auth_reject_record;
      END IF;

      --Sn update the flag in appl_pan
      BEGIN
         UPDATE CMS_APPL_PAN
            SET cap_firsttime_topup = 'Y'
          WHERE cap_pan_code =v_hash_pan and cap_inst_code=prm_instcode; -- prm_acctno;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                 'Error while updating appl_pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   --En update the flag in appl_pan
   EXCEPTION
      WHEN exp_auth_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
      --En call to authorize txn
END IF;
----Sm For Debit Card No Need of doing authorization

   /*--Sn create a record in pan spprt
   BEGIN
      SELECT   CSR_SPPRT_RSNCODE
      INTO  v_resonCode
      FROM  CMS_SPPRT_REASONS
      WHERE csr_spprt_key='INILOAD';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      v_errmsg := 'Initial load reason code is present in master';
      RAISE  exp_main_reject_record ;
      WHEN OTHERS THEN
      v_errmsg := 'Error while selecting reason code from master'|| SUBSTR(SQLERRM,1,200);
      RAISE  exp_main_reject_record ;
   END;*/
   BEGIN
      INSERT INTO CMS_PAN_SPPRT
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,cps_pan_code_encr
                  )
           VALUES (prm_instcode, --prm_acctno
           v_hash_pan, v_mbrnumb, v_cap_prod_catg,
                   'INLOAD', prm_resoncode, prm_remrk,
                   prm_lupduser, prm_lupduser, 0,v_encr_pan
                  );
   --RAISE DUP_VAL_ON_INDEX;  --ONLY TO TEST REMOVE IT ONVE DONE..
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En create a record in pan spprt
   /*       --Commented By Vikrant, Since Procedure Not To Be Used
   --Sn create a record in charge detail
   Sp_Charge_Support(prm_instcode, prm_acctno, 'INLOAD',prm_lupduser,v_errmsg);
   IF v_errmsg <> 'OK' THEN
      v_errmsg := 'Error while creating a record in charge detail';
      RAISE  exp_main_reject_record ;
   END IF;
   --En create a reocrd in charge detail
*/
EXCEPTION                                               --<< MAIN EXCEPTION >>
   WHEN exp_auth_reject_record
   THEN
      prm_auth_message := v_authmsg;
      prm_errmsg := 'OK';
   WHEN exp_main_reject_record
   THEN
      prm_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;                                                          --<< MAIN END;>>
/


