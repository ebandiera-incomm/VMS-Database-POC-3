CREATE OR REPLACE PROCEDURE VMSCMS.sp_delay_change_cardstat (
   prm_errmsg      OUT      VARCHAR2
)
IS
/**********************************************************************************************
  * VERSION           :  1.0
  * DATE OF CREATION  : 22/Aug/2013
  * PURPOSE           : Delay card status change
  * CREATED BY        : Sagar More
  * REVIEWER          : Dhiraj
  * REVIEWED DATE     : 30-Aug-2013 	
  * RELEASE NUMBER    : RI0024.4_B0006
  
  * Modified by      : A.Sivakaminathan
  * Modified Date    : 01-Mar-2016
  * Modified for     : pass adminuser flag
  * Reviewer         : Saravanakumar
  * Build Number     : VMSGPRHOSTCSD_4.0  
**********************************************************************************************/
   v_new_rrn             varchar2 (20);
   v_new_business_date   VARCHAR2 (8);
   v_new_business_time   VARCHAR2 (8);
   v_clear_pan           VARCHAR2 (20);
   v_errmsg              VARCHAR2 (1000);
   v_loop_excp           EXCEPTION;
   v_resp_code           cms_response_mast.cms_iso_respcde%TYPE;
   v_msg_type           VARCHAR2 (4) := '0200';      
   v_revrsl_code        VARCHAR2 (2) := '00'; 
   v_txn_mode           VARCHAR2 (1) := '0';
   v_schd_flag          VARCHAR2(1) := 'Y';
   v_adminuser_flag     VARCHAR2(1) := 'N';   
   
   
BEGIN
   prm_errmsg := 'SUCCESS';

   FOR i IN (SELECT ccr_del_chnl, ccr_txn_code,
                    ccr_pan_code_encr, ccr_mbr_numb, ccr_reason_code,
                    ccr_remark, ccr_req_callid, ccr_ip_addr, ccr_pan_code,
                    ccr_business_date, ccr_business_time, ccr_rrn,
                    ccr_acct_no, ccr_inst_code,ccr_ins_user, cgr_role_code
               FROM cms_chngcardstat_req, cms_usgpdetl_mast, cms_group_role
              WHERE ccr_status = 'N'
                AND ccr_process_date <= TRUNC (SYSDATE)
				AND cgr_grup_code =cum_grup_code and cum_user_code=ccr_ins_user)
   LOOP
      BEGIN
         v_errmsg := 'OK';
         v_adminuser_flag := 'N';

         
         BEGIN
            v_new_rrn := LPAD (seq_auth_rrn.NEXTVAL, 12, '0');
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                          'While generating RRN ' || SUBSTR (SQLERRM, 1, 100);
               RAISE v_loop_excp;
         END;

         BEGIN
            v_new_business_date := TO_CHAR (SYSDATE, 'yyyymmdd');
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'While generating business date '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE v_loop_excp;
         END;

         BEGIN
            v_new_business_time := TO_CHAR (SYSDATE, 'hh24miss');
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'While generating business time '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE v_loop_excp;
         END;

         BEGIN
            v_clear_pan := fn_dmaps_main (i.ccr_pan_code_encr);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    'While generating clear pan ' || SUBSTR (SQLERRM, 1, 100);
               RAISE v_loop_excp;
         END;

         BEGIN
            IF i.cgr_role_code IN (1,3) THEN
				v_adminuser_flag := 'Y';
			END IF;	
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    'While set adminuser flag ' || SUBSTR (SQLERRM, 1, 100);
               RAISE v_loop_excp;
         END;

         BEGIN
            sp_chnge_crdstat_csr (i.ccr_inst_code,
                                  v_new_rrn,
                                  v_clear_pan,
                                  i.ccr_ins_user,
                                  i.ccr_txn_code,
                                  i.ccr_del_chnl,
                                  v_msg_type,   
                                  v_revrsl_code,
                                  v_txn_mode,   
                                  i.ccr_mbr_numb,
                                  v_new_business_date,
                                  v_new_business_time,
                                  i.ccr_reason_code,
                                  i.ccr_remark,
                                  i.ccr_req_callid,                 --call id
                                  i.ccr_ip_addr,
                                  v_schd_flag,
                                  i.ccr_rrn,
                                  v_adminuser_flag,
                                  v_resp_code,
                                  v_errmsg
                                 );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'While calling card status change process '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE v_loop_excp;
         END;
         
         BEGIN
         
            UPDATE transactionlog
               SET orgnl_card_no = i.ccr_pan_code,
                   orgnl_rrn = i.ccr_rrn,
                   orgnl_business_date = i.ccr_business_date,
                   orgnl_business_time = i.ccr_business_time
             WHERE instcode = i.ccr_inst_code
               AND customer_card_no = i.ccr_pan_code
               AND business_date = v_new_business_date
               AND business_time = v_new_business_time
               AND delivery_channel = i.ccr_del_chnl
               AND txn_code = i.ccr_txn_code
               AND rrn = v_new_rrn;
               
         EXCEPTION WHEN OTHERS
            THEN
               null;
         END;         
         
         BEGIN
            UPDATE cms_chngcardstat_req
               SET ccr_status = DECODE (v_resp_code, '00', 'P', 'E'),
                   ccr_process_msg = v_errmsg,
                   ccr_lupd_user = i.ccr_ins_user,
                   CCR_LUPD_DATE = sysdate
             WHERE ccr_inst_code = i.ccr_inst_code
               AND ccr_pan_code = i.ccr_pan_code
               AND ccr_business_date = i.ccr_business_date
               AND ccr_business_time = i.ccr_business_time
               AND ccr_rrn = i.ccr_rrn;
           
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'While updating request table 2 '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE v_loop_excp;
         END;     
         
         
      EXCEPTION WHEN v_loop_excp
         THEN
            ROLLBACK;                           
         BEGIN
            UPDATE cms_chngcardstat_req
               SET ccr_status = 'E',
                   ccr_process_msg = v_errmsg,
                   ccr_lupd_user = i.ccr_ins_user,
                   CCR_LUPD_DATE = sysdate
             WHERE ccr_inst_code = i.ccr_inst_code
               AND ccr_pan_code = i.ccr_pan_code
               AND ccr_business_date = i.ccr_business_date
               AND ccr_business_time = i.ccr_business_time
               AND ccr_rrn = i.ccr_rrn;
           
         EXCEPTION
            WHEN OTHERS
            THEN
               null;
         END;   

            
      WHEN OTHERS
      THEN
            ROLLBACK;                           
            v_errmsg := 'Loop exception ' || SUBSTR (SQLERRM, 1, 100);

         BEGIN
            UPDATE cms_chngcardstat_req
               SET ccr_status = 'E',
                   ccr_process_msg = v_errmsg,
                   ccr_lupd_user = i.ccr_ins_user,
                   CCR_LUPD_DATE = sysdate
             WHERE ccr_inst_code = i.ccr_inst_code
               AND ccr_pan_code = i.ccr_pan_code
               AND ccr_business_date = i.ccr_business_date
               AND ccr_business_time = i.ccr_business_time
               AND ccr_rrn = i.ccr_rrn;
           
         EXCEPTION
            WHEN OTHERS
            THEN
               null;
         END;   

         
      END;
      
      COMMIT;
      
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'Main Execption ' || SUBSTR (SQLERRM, 1, 100);
END;
/

SHOW ERROR;