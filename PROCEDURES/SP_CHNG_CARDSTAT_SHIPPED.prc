create or replace
PROCEDURE        vmscms.sp_chng_cardstat_shipped (
   p_inst_code   IN       NUMBER,
   p_from_stat   IN       NUMBER,
   p_to_stat     IN       NUMBER,
   p_optional_stat   IN       NUMBER,
   p_resp_msg    OUT      VARCHAR2
)
IS
/*************************************************
    * Created By      : Deepa
     * Created Date    :  06-Apr-2012
     * Purpose  :  sent status to Shipped for the cards other than starter card from scheduler
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  12_Apr-2012
     * Build Number     :  RI0005_B0003

   * Modified by         : Sachin P.
   * Modified for        : FSS-1034
   * Modified Date       : 13-Mar-2013
   * Modified reason     : Shipped within 24 hours of the card being generated
   * Reviewer            : Dhiraj
   * Reviewed Date       : 19-MAR-2013
   * Build Number        : CMS3.5.1_RI0024_B0004

   * Modified By      : Pankaj S.
   * Modified Date    : 21-Mar-2013
   * Modified Reason  : Logging of system initiated card status change(FSS-390)
   * Reviewer         : Dhiraj
   * Reviewed Date    :
   * Build Number     : CMS3.5.1_RI0024_B0008

   * Modified By      : Ramesh
   * Modified Date    : 28-FEB-2014
   * Modified Reason  : MVCSD-4121 and FWR-43 : Logging of shipped date when application status changed to 15
   * Reviewer         : Dhiraj
   * Reviewed Date    : 10-Mar-2014
   * Build Number     : RI0027.2_B0002

   * Modified By      : Siva kumar M
   * Modified Date    : 07/11/14
   * Modified Reason  : FSS-1964 Scheduler not changed SourceOne CCF Cards Application Status to SHIPPED after 48 hours
   * Build Number     : RI0027.4.2.1_B0001

   * Modified By      : Ramesh A
   * Modified Date    : 24/04/15
   * Modified Reason  : FSS-2432
   * Build Number     : 3.0.1

   * Modified By      : Siva kumar M
   * Modified Date    : 07/14/15
   * Modified Reason  : MVHOST_1164
   * Reviewer         : Pankaj S
   * Build Number     : VMSGPRHOSTCSD_3.0.2.2_B0001

    * Modified by      : Pankaj S.
    * Modified Date    : 14-Sep-16
    * Modified For     : FSS-4779
    * Modified reason  : Card Generation Performance changes
    * Reviewer         : Saravanakumar
    * Build Number     : 4.2.5

    * Modified by      : Sai Prasad.
    * Modified Date    : 24-May-17
    * Modified For     : FSS-5138
    * Modified reason  : Update expiry date changes
    * Reviewer         : Saravanakumar
    * Build Number     : 17.05

    * Modified by      : Sai Prasad.
    * Modified Date    : 24-Jul-17
    * Modified For     : FSS-5157
    * Modified reason  : B2B Changes
    * Reviewer         : Saravanakumar
    * Build Number     : 17.07
    
    * Modified by      : MageshKumar.S
    * Modified Date    : 07-Feb-18
    * Modified For     : VMS-187 
    * Reviewer         : Saravanakumar
    * Build Number     : 17.12.04
    
    * Modified by      : Ravi.N
    * Modified Date    : 15/09/2020
    * Modified For     : VMS-3039 
    * Reviewer         : Saravanakumar
    * Build Number     : VMSGPRHOST_R36_B0001
	
	* Modified by      : Mageshkumar.S
    * Modified Date    : 25/09/2020
    * Modified For     : VMS-3140
    * Reviewer         : Saravanakumar
    * Build Number     : VMSGPRHOST_R36_B0001
 *************************************************/
   v_shipped_date   DATE;
   v_sys_date       DATE;
   v_upd_rec_cnt    NUMBER;
   v_respcode       VARCHAR2 (5);
   v_errmsg         VARCHAR2(2000);


   CURSOR c3
   IS              --- below query modified for FSS-1964
      /*SELECT
   /*TO_DATE (TO_CHAR (ccs_lupd_date + 2, 'MM/DD/YYYY HH24:MI:SS'),
       'MM/DD/YYYY HH24:MI:SS'
      ) AS shippeddate,*/ --commented and modified on 13.03.2013 for FSS-1034
           /*  TO_DATE (TO_CHAR (DECODE (cap_repl_flag,
                                       2, ccs_lupd_date + 1,
                                       ccs_lupd_date + 2
                                      ),
                               'MM/DD/YYYY HH24:MI:SS'
                              ),
                      'MM/DD/YYYY HH24:MI:SS'
                     ) AS shippeddate,
             TO_DATE (TO_CHAR (SYSDATE, 'MM/DD/YYYY HH24:MI:SS'),
                      'MM/DD/YYYY HH24:MI:SS'
                     ) AS systemdate,
             ccs_pan_code_encr, ccs_pan_code
        FROM cms_cardissuance_status a, cms_appl_pan b, cms_prod_cattype c
       WHERE ccs_card_status = p_from_stat
         AND ccs_inst_code = p_inst_code
         AND a.ccs_pan_code = b.cap_pan_code
         AND c.cpc_prod_code = b.cap_prod_code
         AND c.cpc_card_type = b.cap_card_type
         AND c.cpc_package_id IS NOT NULL;*/

         /* SELECT
                  TO_DATE (TO_CHAR (DECODE (cap_repl_flag,
                                      -- 2, ccs_lupd_date + 1,  ---Modified for MVHOST_1164.
                                       7, sysdate,
                                       ccs_lupd_date - 2
                                      ),
                               'MM/DD/YYYY HH24:MI:SS'
                              ),
                      'MM/DD/YYYY HH24:MI:SS'
                     ) AS shippeddate,
             TO_DATE (TO_CHAR (SYSDATE, 'MM/DD/YYYY HH24:MI:SS'),
                      'MM/DD/YYYY HH24:MI:SS'
                     ) AS systemdate,
             ccs_pan_code_encr, ccs_pan_code, cap_acct_id, cap_cust_code, cap_startercard_flag
        FROM cms_cardissuance_status a, cms_appl_pan b
       WHERE ccs_inst_code = p_inst_code
         AND (ccs_card_status = p_from_stat or ccs_card_status = p_optional_stat)
         AND a.ccs_pan_code = b.cap_pan_code
         and ccs_inst_code=cap_inst_code
         and exists(select 1 from cms_prod_cattype c,cms_prod_cardpack e
         where e.CPC_CARD_ID =nvl((select cmp_card_id from cms_merinv_prodcat,cms_merinv_merpan
                                  where cmp_merprodcat_id = cmm_merprodcat_id
                                 and cmm_pan_code =  b.cap_pan_code and cmm_inst_code =p_inst_code
                                  and cmp_inst_code =p_inst_code), c.CPC_CARD_ID )
         AND c.cpc_prod_code = b.cap_prod_code
         AND c.cpc_card_type = b.cap_card_type
         and c.cpc_INST_code = b.cap_inst_Code
         and e.CPC_INST_code=c.cpc_INST_code
         AND e.cpc_prod_code = b.cap_prod_code
         and e.CPC_PRINT_VENDOR like 'SourceOne%'); --Modified for FSS-2432*/

         SELECT TO_DATE (TO_CHAR (DECODE (cap_repl_flag,
                                      -- 2, ccs_lupd_date + 1,  ---Modified for MVHOST_1164.
                                       7, sysdate,
                                       ccs_lupd_date + nvl(Vfv_Shipped_Time_Delay/24,2)
                                      ),
                               'MM/DD/YYYY HH24:MI:SS'
                              ),
                      'MM/DD/YYYY HH24:MI:SS'
                     ) AS shippeddate,
             TO_DATE (TO_CHAR (SYSDATE, 'MM/DD/YYYY HH24:MI:SS'),
                      'MM/DD/YYYY HH24:MI:SS'
                     ) AS systemdate,
             ccs_pan_code_encr, ccs_pan_code, cap_acct_id, cap_cust_code, cap_startercard_flag
        FROM cms_cardissuance_status a, cms_appl_pan b, cms_prod_cattype c,cms_prod_cardpack e, Vms_PackageId_Mast, Vms_Fulfillment_Vendor_Mast
       WHERE ccs_inst_code = p_inst_code
         AND (ccs_card_status = p_from_stat or ccs_card_status = p_optional_stat)
         AND a.ccs_pan_code = b.cap_pan_code
         and ccs_inst_code=cap_inst_code
         and e.CPC_CARD_ID = b.CAP_CARDPACK_ID
         and c.cpc_prod_code = b.cap_prod_code
         and c.cpc_card_type = b.cap_card_type
         and c.cpc_INST_code = b.cap_inst_Code
         and e.CPC_INST_code=c.cpc_INST_code
         and e.cpc_prod_code = b.cap_prod_code
         and E.Cpc_Card_Details = VPM_PACKAGE_ID
         and VFV_FVENDOR_ID = VPM_VENDOR_ID
         --and VFV_IS_AUTOMATIC_SHIPPED ='Y'
         AND VFV_IS_AUTOMATIC_SHIPPED = '1' AND NVL(CAP_REPL_FLAG,0)=0
         union all
         SELECT TO_DATE (TO_CHAR (DECODE (cap_repl_flag,
                                      -- 2, ccs_lupd_date + 1,  ---Modified for MVHOST_1164.
                                       7, sysdate,
                                       ccs_lupd_date + nvl(Vfv_Shipped_Time_Delay/24,2)
                                      ),
                               'MM/DD/YYYY HH24:MI:SS'
                              ),
                      'MM/DD/YYYY HH24:MI:SS'
                     ) AS shippeddate,
             TO_DATE (TO_CHAR (SYSDATE, 'MM/DD/YYYY HH24:MI:SS'),
                      'MM/DD/YYYY HH24:MI:SS'
                     ) AS systemdate,
             ccs_pan_code_encr, ccs_pan_code, cap_acct_id, cap_cust_code, cap_startercard_flag
        FROM cms_cardissuance_status a, cms_appl_pan b, cms_prod_cattype c,cms_prod_cardpack e, Vms_PackageId_Mast, Vms_Fulfillment_Vendor_Mast
       WHERE ccs_inst_code = p_inst_code
         AND (ccs_card_status = p_from_stat or ccs_card_status = p_optional_stat)
         AND a.ccs_pan_code = b.cap_pan_code
         and ccs_inst_code=cap_inst_code
         and e.CPC_CARD_ID =b.CAP_CARDPACK_ID
         and c.cpc_prod_code = b.cap_prod_code
         and c.cpc_card_type = b.cap_card_type
         and c.cpc_INST_code = b.cap_inst_Code
         and e.CPC_INST_code=c.cpc_INST_code
         and e.cpc_prod_code = b.cap_prod_code
         and E.Cpc_Card_Details = VPM_PACKAGE_ID
         and VFV_FVENDOR_ID = VPM_VENDOR_ID
         AND VFV_IS_AUTOMATIC_SHIPPED='2' AND cap_repl_flag <> 0
         union all
         SELECT TO_DATE (TO_CHAR (DECODE (cap_repl_flag,
                                      -- 2, ccs_lupd_date + 1,  ---Modified for MVHOST_1164.
                                       7, sysdate,
                                       ccs_lupd_date + nvl(Vfv_Shipped_Time_Delay/24,2)
                                      ),
                               'MM/DD/YYYY HH24:MI:SS'
                              ),
                      'MM/DD/YYYY HH24:MI:SS'
                     ) AS shippeddate,
             TO_DATE (TO_CHAR (SYSDATE, 'MM/DD/YYYY HH24:MI:SS'),
                      'MM/DD/YYYY HH24:MI:SS'
                     ) AS systemdate,
             ccs_pan_code_encr, ccs_pan_code, cap_acct_id, cap_cust_code, cap_startercard_flag
        FROM cms_cardissuance_status a, cms_appl_pan b, cms_prod_cattype c,cms_prod_cardpack e, Vms_PackageId_Mast, Vms_Fulfillment_Vendor_Mast
       WHERE ccs_inst_code = p_inst_code
         AND (ccs_card_status = p_from_stat or ccs_card_status = p_optional_stat)
         AND a.ccs_pan_code = b.cap_pan_code
         and ccs_inst_code=cap_inst_code
         and e.CPC_CARD_ID =b.CAP_CARDPACK_ID
         and c.cpc_prod_code = b.cap_prod_code
         and c.cpc_card_type = b.cap_card_type
         and c.cpc_INST_code = b.cap_inst_Code
         and e.CPC_INST_code=c.cpc_INST_code
         and e.cpc_prod_code = b.cap_prod_code
         and E.Cpc_Card_Details = VPM_PACKAGE_ID
         and VFV_FVENDOR_ID = VPM_VENDOR_ID
         and VFV_IS_AUTOMATIC_SHIPPED = '3';
BEGIN
   v_upd_rec_cnt := 0;

   FOR i3 IN c3
   LOOP
      BEGIN
         IF i3.shippeddate <= i3.systemdate
         THEN
            UPDATE cms_cardissuance_status
               SET ccs_card_status = p_to_stat,
                   ccs_lupd_date = SYSDATE , CCS_SHIPPED_DATE = sysdate  --Added CCS_SHIPPED_DATE for FWR-43 on 28/02/14
             WHERE (ccs_card_status = p_from_stat or ccs_card_status = p_optional_stat)
               AND ccs_inst_code = p_inst_code
               AND ccs_pan_code = i3.ccs_pan_code;

            IF SQL%ROWCOUNT = 0
            THEN
               INSERT INTO cms_statupd_shipped_failure
                           (csf_inst_code, csf_pan_code_encr,
                            ccs_pan_code, csf_ins_date
                           )
                    VALUES (p_inst_code, i3.ccs_pan_code_encr,
                            i3.ccs_pan_code, SYSDATE
                           );
            ELSE
               v_upd_rec_cnt := v_upd_rec_cnt + 1;
               sp_log_cardstat_chnge (p_inst_code,
                              i3.ccs_pan_code,
                              i3.ccs_pan_code_encr,
                              NULL,  --need to discuss
                              '06',
                              NULL,
                              NULL,
                              NULL,
                              v_respcode,
                              v_errmsg
                             );

               --SN added for Card issu performance changes
                IF i3.cap_startercard_flag='Y'  THEN

                   IF  v_errmsg='OK' THEN
                    BEGIN
                       INSERT INTO cms_smsandemail_alert (csa_inst_code, csa_pan_code, csa_pan_code_encr, csa_loadorcredit_flag,
                                                          csa_lowbal_flag, csa_negbal_flag, csa_highauthamt_flag, csa_dailybal_flag,
                                                          csa_insuff_flag, csa_incorrpin_flag, csa_fast50_flag, csa_fedtax_refund_flag,
                                                          csa_deppending_flag, csa_depaccepted_flag, csa_deprejected_flag, csa_ins_user, csa_ins_date)
                            VALUES (p_inst_code,  i3.ccs_pan_code,  i3.ccs_pan_code_encr, 0,
                                             0, 0, 0, 0,
                                             0, 0, 0, 0,
                                             0, 0, 0, 1, SYSDATE);
                    EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN NULL;
                       WHEN OTHERS THEN
                       v_errmsg:='Error while inserting records into SMS_EMAIL ALERT ' || SUBSTR (SQLERRM, 1, 200);
                    END;
                  END IF;

                 IF  v_errmsg='OK' THEN
                    BEGIN
                         INSERT INTO CMS_PAN_ACCT
                                     (cpa_inst_code, cpa_cust_code, cpa_acct_id,
                                      cpa_acct_posn, cpa_pan_code, cpa_mbr_numb,
                                      cpa_ins_user, cpa_lupd_user, cpa_pan_code_encr
                                     )
                              VALUES (p_inst_code, i3.cap_cust_code, i3.cap_acct_id,
                                      1,  i3.ccs_pan_code, '000',
                                      1, 1,  i3.ccs_pan_code_encr
                                     );
                    EXCEPTION
                    WHEN DUP_VAL_ON_INDEX THEN
                      NULL;
                    WHEN OTHERS THEN
                     v_errmsg:= 'Error while inserting records into pan acct  master '|| SUBSTR (SQLERRM, 1, 200);
                    END;
                 END IF;

                END IF;
                --EN added for Card issu performance changes

             IF v_respcode<>'00' and  v_errmsg <>'OK' THEN

                INSERT INTO cms_statupd_log_failure
                               (csf_inst_code, csf_pan_code_encr,
                                ccs_pan_code, csf_ins_date,csf_failure_reason
                               )
                        VALUES (p_inst_code, i3.ccs_pan_code_encr,
                                i3.ccs_pan_code, SYSDATE,v_errmsg
                               );
             END IF ;


            END IF;
         END IF;
      END;
   END LOOP;

   p_resp_msg := v_upd_rec_cnt || ' Records Updated';
EXCEPTION
   WHEN OTHERS
   THEN
      p_resp_msg :=
            'Exception in Selecting the Printer Sent Card details'
         || SUBSTR (SQLERRM, 1, 200);
END;
/
show error