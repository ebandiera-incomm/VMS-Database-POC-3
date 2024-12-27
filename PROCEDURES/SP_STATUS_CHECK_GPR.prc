create or replace PROCEDURE                          VMSCMS.SP_STATUS_CHECK_GPR(PRM_INST_CODE        IN NUMBER,
   prm_card_number        IN       VARCHAR2,
   prm_delivery_channel   IN       VARCHAR2,
   prm_expry_date         IN       DATE,
   prm_card_stat          IN       VARCHAR2,
   prm_tran_code          IN       VARCHAR2,
   prm_tran_mode          IN       VARCHAR2,
   prm_prod_code          IN       VARCHAR2,
   prm_prod_catg          IN       VARCHAR2,
   prm_msg_type           IN       VARCHAR2,
   prm_tran_date          IN       VARCHAR2,
   prm_tran_time          IN       VARCHAR2,
   prm_gvc_int_ind        IN       VARCHAR2,
   prm_gvc_pinsign        IN       VARCHAR2,
   prm_gvc_mcc_code       IN       VARCHAR2,
   prm_resp_code          OUT      VARCHAR2,
   prm_resp_msg           OUT      VARCHAR2,
   prm_precheck           IN       VARCHAR2 DEFAULT '0'
   ,prm_merc_id           IN       VARCHAR2 DEFAULT NULL
)
IS
   v_hash_pan           cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan           cms_appl_pan.cap_pan_code_encr%TYPE;
   v_gpr_check          NUMBER(2);
   v_gpr_cardstat_cnt   NUMBER;
   v_appl_stat          gpr_valid_cardstat.gvc_card_stat%TYPE;
   v_stat_count         NUMBER;
   v_appstat_count      NUMBER;
   v_cardstat_count     NUMBER;
   v_expstat_count      NUMBER;
   v_exp_stat            cms_appl_pan.cap_card_stat%TYPE;
   V_STATUS_CHECK_EXCEPTION EXCEPTION;
   v_validate_msg        VARCHAR2(500);
   v_appstat_app    VARCHAR2(1);
   v_cardstat_app   VARCHAR2(1);
   v_expstat_app    VARCHAR2(1);
   V_NEW_MSG        VARCHAR2(20); --ADDED ON 19-12-2013 FOR MVCSD-4517
   V_INDL_RESID      VARCHAR2(1); --ADDED ON 19-12-2013 FOR MVCSD-4517
   V_CHECK_STATCNT   NUMBER;
   v_updted_cardstatus cms_prod_cattype.CPC_CONSUMED_CARD_STAT%TYPE; --Added for FSS-5225
   v_decline_Cardstatus   VARCHAR2(20); --Added for FSS-5225
   l_consumed_status cms_card_stat.ccs_consumed_status%type;
   v_cap_active_date CMS_APPL_PAN.cap_active_date%TYPE ; --Added for FSS-5225
   V_UPDATED_COUNT NUMBER;
  v_resp_cde             VARCHAR2(5);
  v_err_msg              VARCHAR2(900) := 'OK';
  v_tran_date            DATE;
  v_hold_days   CMS_TXNCODE_RULE.CTR_HOLD_DAYS%TYPE;
  v_hold_amount NUMBER;
  v_consumed_flagupd VARCHAR2(5)     :='Y';
  v_vms_5306_toggle cms_inst_param.cip_param_value%TYPE;

CURSOR cur_status_check (p_appl_stat IN VARCHAR2,
                        p_card_stat IN VARCHAR2,
                        p_exp_stat IN VARCHAR2
                        )
IS
SELECT gvc_stat_flag,gvc_int_ind,gvc_pinsign,gvc_mcc_id,gvc_approve_txn,
    (SELECT CCP_PRIORITY FROM
    CMS_CARDSTAT_PRIORITY
    WHERE DECODE (nvl(gvc_int_ind,'A'),'A','A','NS','A','-') = CCP_INT_STAT
    and DECODE (nvl(gvc_pinsign,'A'),'A','A','NS','A','-') = CCP_PIN_STAT
    and DECODE (nvl(gvc_mcc_id,'A'),'A','A','-') = CCP_MCC_STAT
    ) priority
FROM gpr_valid_cardstat
WHERE gvc_tran_code = prm_tran_code
AND gvc_delivery_channel = prm_delivery_channel
AND gvc_prod_code = prm_prod_code
AND gvc_card_type = prm_prod_catg
AND gvc_inst_code = prm_inst_code
AND gvc_msg_type = prm_msg_type
AND gvc_stat_flag IN ('C','A','E')
AND gvc_card_stat =DECODE(gvc_stat_flag,'C',p_card_stat,'A',p_appl_stat,'E',p_exp_stat)
AND gvc_int_ind IN ('NS','A',prm_gvc_int_ind)
AND gvc_pinsign IN ('NS','A',prm_gvc_pinsign)
AND (gvc_mcc_id IS NULL OR 0 <>(SELECT COUNT (*)
                                FROM cms_mcc_tran
                                WHERE cmt_mcc_id = gvc_mcc_id
                                AND cmt_mcc_code = prm_gvc_mcc_code))
--GROUP BY gvc_stat_flag,gvc_int_ind,gvc_pinsign,gvc_mcc_id,gvc_approve_txn
ORDER BY gvc_stat_flag,priority;

/*************************************************
  * modified by           :Ramesh.A
  * modified Date        : 02-NOV-12
  * modified reason      : Added condition for checks application status and card status
  * Reviewer         : B.Besky Anand
  * Reviewed Date    :  02-NOV-12
  * Release Number     :  CMS3.5.1_RI0020.1

  * Modified By                  : Pankaj S.
  * Modified Date                : 12-Nov-2013
  * Modified Reason              : SPIL:Spend down status card accepts Val insertion transaction when configured to 'DECLINE'
  * Mantis ID                    : 12970
  * Reviewer                     : Dhiraj
  * Reviewed Date                :
  * Build Number                 : RI0024.6.2_B0001

  * Modified By                  : MageshKUmar S.
  * Modified Date                : 19-Dec-2013
  * Modified Reason              : error Msg changed for international declined txns
  * Mantis ID                    : MVCSD-4517
  * Reviewer                     : Dhiraj
  * Reviewed Date                : 19-Dec-2013
  * Build Number                 : RI0027_B0003

  * Modified By                  : Ramesh
  * Modified Date                : 20-Feb-2014
  * Modified Reason              : SPIL:The Spil Activation Gets processed successfully even if it is declined in the Configuration
  * Mantis ID                    : 13724
  * Reviewer                     : Dhiraj
  * Reviewed Date                : 20-Feb-2014
  * Build Number                 : RI0027.1_B0004

  * Modified By                  : RAVI N
  * Modified Date                : 27-MAY-2014
  * Modified Reason              : JIRA-1619 SPIL response code and response message are conflicting. 10031 is for inactive card and 10047 is for stolen card
  * Build Number                 : RI0027.2.1_B0003

  * Modified By                  : Pankaj S.
  * Modified Date                : 20-May-2015
  * Modified Reason              :Full table scan changes
  * Build Number                 : VMSGPRHOAT_3.0.3_B0001

  * Modified By                  : Abdul Hameed M.A
  * Modified Date                : 26-Sep-2016
  * Modified Reason              : Pcms_valid_cardstat check should he validate for OLS txn
  * Build Number                 : VMSGPRHOAT_4.8_B0004

  * Modified By                  : Dhinakaran
  * Modified Date                : 10-Oct-2017
  * Modified Reason              : FSS-5225 : To change the card status to Consumed
  * Build Number                 : VMSGPRHOST_17.10 B0002

  * Modified By                  : Baskar
  * Modified Date                : 03-MAY-2019
  * Modified Reason              : VMS-911 : POS Transactions Failed on Shipped From Warehouse Application Status
  * Build Number                 : VMSGPRHOSTR15 B0005

  * Modified By                  : Dhinakaran B
  * Modified Date                : 25-Dec-2021
  * Modified Reason              : VMS-5306 : update Consumed logic
  * Build Number                 : VMSGPRHOST_57

  * Modified By                  : Pankaj S.
  * Modified Date                : 07-Sept-2022
  * Modified Reason              : VMS-6335 : Enhance Consumed Logic
  * Build Number                 : VMS_R68
*************************************************/

--SN local procedure for status validate based on configuration
/*
  Example
  For Transaction with Domestic, PIN based for MCC 6010,

  * Cursor "cur_status_check" o/p,

  status_flag        Dom/Int/All        Pin/Sign/All    Mcc/All        App/Dec        Priority order
  A                A             A                A              Y            8
  C                      0                      P                      A                N                4
  C                      A                      P                      A                N                6
  C                A                A                A              Y            8
  E                0             P                6010        N            1

  * local procedure "lp_validate" o/p will be
  v_appstat_app  = 'Y'
  v_cardstat_app = 'N'    v_expstat_app  = 'N'

  Based on count > 0 and app/decline status flag transaction will be declined or allowed respectively.
  Here for application staus flag assigned as approve ,so it move for next card status check,
  and transaction will be declined .In this case expiry status check will not happen.
*/
PROCEDURE lp_validate(
                    p_appl_stat IN VARCHAR2,
                    p_card_stat IN VARCHAR2,
                    p_exp_stat IN VARCHAR2,
                    p_validate_msg OUT VARCHAR2)
AS
    v_cur_stat_flag        gpr_valid_cardstat.gvc_stat_flag%TYPE;
    v_pre_stat_flag        gpr_valid_cardstat.gvc_stat_flag%TYPE;
BEGIN
    p_validate_msg:='OK';
    --if no matches found then default  decline
     v_appstat_app := 'N';
     v_cardstat_app :='N';
     v_expstat_app :='N';
     v_pre_stat_flag :=' ';

    FOR j IN cur_status_check (p_appl_stat,p_card_stat,p_exp_stat)
    LOOP
        v_cur_stat_flag:=j.gvc_stat_flag;

        IF  v_pre_stat_flag <> v_cur_stat_flag THEN -- if previous staus match with current status then skip
            IF j.gvc_stat_flag = 'A' THEN
                v_appstat_app := j.gvc_approve_txn;
            ELSIF  j.gvc_stat_flag = 'C' THEN
                v_cardstat_app := j.gvc_approve_txn;
            ELSIF  j.gvc_stat_flag = 'E' THEN
                v_expstat_app := j.gvc_approve_txn;
                if p_card_stat='7' then
                    v_cardstat_app := j.gvc_approve_txn;
                end if;
            END IF;
        END IF;
        v_pre_stat_flag:=j.gvc_stat_flag;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_validate_msg:='Error in lp_validate Check' || SUBSTR (SQLERRM, 1, 300);
END lp_validate;
--EN local procedure for validate based on configuration



BEGIN
    v_gpr_check := 0;
    prm_resp_msg := 'OK';

    --SN CREATE HASH PAN
    BEGIN
        v_hash_pan := gethash (prm_card_number);
    EXCEPTION
        WHEN OTHERS   THEN
            prm_resp_code := '21';
            prm_resp_msg :=  'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
    END;
    --EN CREATE HASH PAN

    --SN create encr pan
    BEGIN
        v_encr_pan := fn_emaps_main (prm_card_number);
    EXCEPTION
        WHEN OTHERS   THEN
            prm_resp_code := '21';
            prm_resp_msg :=  'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
    END;
    --EN create encr pan

    --Sn Getting the card status configuration for the txn code

    /*If no no mapping has done for the transation then GPR status check will not be performed.
    PCMS_VALID_CARDSTAT validation will be done*/

    BEGIN
        SELECT COUNT (1)
        INTO v_gpr_cardstat_cnt
        FROM gpr_valid_cardstat
        WHERE gvc_tran_code = prm_tran_code
        AND gvc_delivery_channel = prm_delivery_channel
        AND gvc_prod_code = prm_prod_code
        AND gvc_card_type = prm_prod_catg
        AND gvc_inst_code = prm_inst_code
        AND gvc_msg_type = prm_msg_type;

        IF v_gpr_cardstat_cnt = 0   THEN
            v_gpr_check := '1';
        ELSE
            v_gpr_check := '0';
        END IF;

    EXCEPTION
        WHEN OTHERS   THEN
            prm_resp_code := '21';
            prm_resp_msg :=  'Error card status count check ' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
    END;

   --SN ADDED ON 19-12-2013 FOR MVCSD-4517
  IF   prm_gvc_int_ind='1' AND prm_delivery_channel IN('01','02') THEN
    V_NEW_MSG :=' International';
    V_INDL_RESID :='8';
  END IF;
  --EN ADDED ON 19-12-2013 FOR MVCSD-4517


    --En Getting the card status configuration for the txn code
    IF v_gpr_check = '0'   THEN
    --Sn Getting the count of Approve status for the transaction with msgtype
        BEGIN
           --Sn Modified for Full table scan changes
           /* SELECT   COUNT (DISTINCT gvc_stat_flag)
            INTO v_stat_count
            FROM gpr_valid_cardstat
            WHERE gvc_tran_code = prm_tran_code
            AND gvc_delivery_channel = prm_delivery_channel
            AND gvc_prod_code = prm_prod_code
            AND gvc_card_type = prm_prod_catg
            AND gvc_inst_code = prm_inst_code
            AND gvc_msg_type = prm_msg_type
            AND gvc_approve_txn = 'Y'
            ORDER BY gvc_stat_flag;*/

            SELECT COUNT (gvc_stat_flag)
                 INTO v_stat_count
                FROM gpr_valid_cardstat
               WHERE     gvc_tran_code = prm_tran_code
                     AND gvc_delivery_channel =prm_delivery_channel
                     AND gvc_prod_code = prm_prod_code
                     AND gvc_card_type = prm_prod_catg
                     AND gvc_inst_code = prm_inst_code
                     AND gvc_msg_type =prm_msg_type
                     AND gvc_approve_txn = 'Y';
             --En Modified for Full table scan changes

            IF v_stat_count = 0          THEN
                prm_resp_msg := 'Inactive card / Status Not Allowed For' ||NVL(V_New_Msg,'This' )||' Transaction'; -- MODIFIED ON 19-12-2013 FOR MVCSD-4517
                RAISE V_STATUS_CHECK_EXCEPTION;
            END IF;

        EXCEPTION
             WHEN V_STATUS_CHECK_EXCEPTION   THEN --ADDED BY ANANTH FOR GETTING PROPER ERROR MSG ON 18OCT2012
                RAISE V_STATUS_CHECK_EXCEPTION;
            WHEN OTHERS   THEN
                prm_resp_code := '21';
                prm_resp_msg :=   'Error   status count check ' || SUBSTR (SQLERRM, 1, 200);
                RETURN;
        END;

        --En Getting the count of Approve status for the transaction with msgtype
        BEGIN
            SELECT ccs_card_status
            INTO v_appl_stat
            FROM cms_cardissuance_status
            WHERE ccs_pan_code = v_hash_pan
            AND ccs_inst_code = prm_inst_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                BEGIN
                    SELECT ccs_card_status
                    INTO v_appl_stat
                    FROM cms_cardissuance_status
                    WHERE ccs_appl_code =
                    (SELECT cap_appl_code
                    FROM cms_appl_pan
                    WHERE cap_pan_code = v_hash_pan
                    AND cap_inst_code = prm_inst_code);
                EXCEPTION
                    WHEN NO_DATA_FOUND  THEN
                        prm_resp_code := '21';
                        prm_resp_msg :='Application details not found for the card'|| v_hash_pan;
                        RETURN;
                    WHEN OTHERS   THEN
                        prm_resp_code := '21';
                        prm_resp_msg :=  'Application details error ' || SUBSTR (SQLERRM, 1, 200);
                        RETURN;
                END;

            WHEN OTHERS  THEN
                prm_resp_code := '21';
                prm_resp_msg :=  'Error in appl stat ' || SUBSTR (SQLERRM, 1, 200);
                RETURN;
        END;
        BEGIN
            SELECT SUM(DECODE(gvc_stat_flag,'A',1,0)),SUM(DECODE(gvc_stat_flag,'C',1,0)),
            SUM(DECODE(gvc_stat_flag,'E',1,0))
            INTO v_appstat_count,v_cardstat_count,v_expstat_count
            FROM gpr_valid_cardstat
            WHERE gvc_tran_code = prm_tran_code
            AND gvc_delivery_channel = prm_delivery_channel
            AND gvc_prod_code = prm_prod_code
            AND gvc_card_type = prm_prod_catg
            AND gvc_inst_code = prm_inst_code
            AND gvc_msg_type = prm_msg_type
            AND gvc_stat_flag IN ('A','C','E');
          --  AND gvc_card_stat = v_appl_stat;
        EXCEPTION
            WHEN OTHERS  THEN
                prm_resp_msg := 'Error while selecting gpr_valid_cardstat ' || SUBSTR (SQLERRM, 1, 200);
                RETURN;
        END;

       IF v_expstat_count > 0   THEN
            BEGIN
                SELECT cgs_stat_code INTO v_exp_stat
                FROM cms_gpr_cardstat WHERE cgc_stat_flag='E';
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    prm_resp_code := '21';
                    prm_resp_msg  := 'No data found while selecting expiry card status ';
                    RETURN;
                WHEN TOO_MANY_ROWS THEN
                    prm_resp_code := '21';
                    prm_resp_msg  := 'TOO MANY ROWS found while selecting expiry card status ';
                    RETURN;
                WHEN OTHERS THEN
                    prm_resp_code := '21';
                    prm_resp_msg  := 'Error from while selecting expiry card status ' ||   SUBSTR(SQLERRM, 1, 200);
                    RETURN;
            END;
        END IF;

        IF (v_appstat_count > 0 or v_cardstat_count >0 or v_expstat_count > 0) THEN
            BEGIN
                -- Call local procedure for application,card,expiry status check
                lp_validate(v_appl_stat,prm_card_stat,v_exp_stat,v_validate_msg);

                IF v_validate_msg <>  'OK'   THEN
                    RAISE V_STATUS_CHECK_EXCEPTION;
                END IF;
               EXCEPTION
                WHEN V_STATUS_CHECK_EXCEPTION  THEN
                    prm_resp_code := '21';
                    prm_resp_msg := v_validate_msg;
                    RETURN;
                WHEN OTHERS THEN
                    prm_resp_code := '21';
                    prm_resp_msg := 'Error in txn approve ' || SUBSTR (SQLERRM, 1, 200);
                    RETURN;
            END;

            --Sn Application status check
            IF v_appstat_count > 0  THEN
                BEGIN
                    IF v_appstat_app = 'N' THEN
                        RAISE V_STATUS_CHECK_EXCEPTION;
                    END IF;
                EXCEPTION
                    WHEN V_STATUS_CHECK_EXCEPTION  THEN
                        prm_resp_msg := 'Inactive card / Status Not Allowed For this Transaction';
                        RAISE V_STATUS_CHECK_EXCEPTION;
                    WHEN OTHERS THEN
                        prm_resp_code := '21';
                        prm_resp_msg := 'Error in txn approve ' || SUBSTR (SQLERRM, 1, 200);
                        RETURN;
                END;
            END IF;
            --En Application status check

            --Sn Card status check
            IF v_cardstat_count >0 THEN
                BEGIN
                    IF v_cardstat_app = 'N' THEN
                        RAISE V_STATUS_CHECK_EXCEPTION;
                    END IF;
                 EXCEPTION
                    WHEN V_STATUS_CHECK_EXCEPTION  THEN
                        prm_resp_msg := 'Inactive card / Status Not Allowed For this Transaction';
                        RAISE V_STATUS_CHECK_EXCEPTION;
                    WHEN OTHERS THEN
                        prm_resp_code := '21';
                        prm_resp_msg := 'Error in txn approve ' || SUBSTR (SQLERRM, 1, 200);
                        RETURN;
                END;
           IF v_appstat_count = 0  THEN --Added by Ramesh.A on 02/11/2012(checks for only if application status not configured)
                BEGIN
                    SELECT ccs_card_status
                    INTO v_appl_stat
                    FROM cms_cardissuance_status
                    WHERE ccs_inst_code = prm_inst_code
                    AND ccs_pan_code = v_hash_pan
                    AND ccs_card_status = '15';
                EXCEPTION
                    WHEN NO_DATA_FOUND   THEN
                        prm_resp_msg := 'Card is not in Shipped Status';
                        RAISE V_STATUS_CHECK_EXCEPTION;
                    WHEN OTHERS  THEN
                        prm_resp_code := '21';
                        prm_resp_msg :='Error in cms_cardissuance_status ' || SUBSTR (SQLERRM, 1, 200);
                        RAISE V_STATUS_CHECK_EXCEPTION;
                END;
                END IF;
            END IF;
            --En Card status check
            --Sn Expiry status check
            --IF v_expstat_count > 0   THEN  --Commented by Ramesh.A on 02/11/2012 for default check for expirydate
                BEGIN
                    IF v_expstat_app = 'N' THEN
                        RAISE V_STATUS_CHECK_EXCEPTION;
                    END IF;
                EXCEPTION
                    WHEN V_STATUS_CHECK_EXCEPTION  THEN
                        BEGIN
                            IF TO_DATE (prm_tran_date, 'YYYYMMDD') > LAST_DAY (TO_CHAR (prm_expry_date,'DD-MON-YY' )) THEN
                                prm_resp_code := '13';
                                prm_resp_msg := 'EXPIRED CARD-GPR';
                                RAISE V_STATUS_CHECK_EXCEPTION;
                            END IF;
                        EXCEPTION
                        WHEN V_STATUS_CHECK_EXCEPTION  THEN
                         RAISE;
                            WHEN OTHERS   THEN
                                prm_resp_code := '21';
                                prm_resp_msg :=  'ERROR IN EXPIRY DATE CHECK '|| SUBSTR (SQLERRM, 1, 200);
                                RETURN;
                        END;

                    WHEN OTHERS  THEN
                        prm_resp_code := '21';
                        prm_resp_msg := 'Error in txn approve 1 ' || SUBSTR (SQLERRM, 1, 200);
                        RETURN;
                END;
            IF v_cardstat_count = 0  and v_appstat_count = 0 and v_expstat_count > 0   THEN  --Added by Ramesh.A on 02/11/2012(checks for only if application status and card status not configured)
                BEGIN
                    SELECT ccs_card_status
                    INTO v_appl_stat
                    FROM cms_cardissuance_status
                    WHERE ccs_inst_code = prm_inst_code
                    AND ccs_pan_code = v_hash_pan
                    AND ccs_card_status = '15';
                EXCEPTION
                    WHEN NO_DATA_FOUND   THEN
                        prm_resp_msg := 'Card is not in Shipped Status';
                        RAISE V_STATUS_CHECK_EXCEPTION;
                    WHEN OTHERS  THEN
                        prm_resp_msg :='Error in cms_cardissuance_status ' || SUBSTR (SQLERRM, 1, 200);
                        RAISE V_STATUS_CHECK_EXCEPTION;
                END;
            END IF;
            --En Expiry status check
        ELSE
            prm_resp_msg := 'Inactive card / Status Not Allowed For this Transaction';
            RAISE V_STATUS_CHECK_EXCEPTION;
        END IF;
    END IF;

  IF v_gpr_check = '1' AND  prm_precheck = '1' THEN
  BEGIN
    SELECT COUNT(1)
     INTO V_CHECK_STATCNT
     FROM PCMS_VALID_CARDSTAT
    WHERE PVC_INST_CODE = PRM_INST_CODE AND PVC_CARD_STAT =  trim(PRM_CARD_STAT)  AND
         PVC_TRAN_CODE = PRM_TRAN_CODE AND
         PVC_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL;
    IF V_CHECK_STATCNT = 0 THEN
     prm_resp_code := '10';
     prm_resp_msg  := 'Invalid Card Status';
     raise V_STATUS_CHECK_EXCEPTION;
    END IF;
  EXCEPTION
    when V_STATUS_CHECK_EXCEPTION then
    raise;
    WHEN OTHERS THEN
     prm_resp_code := '21';
     prm_resp_msg  := 'Problem while selecting card stat ' ||
                   SUBSTR(SQLERRM, 1, 200);
     RETURN;
  END;
  END IF;

    prm_resp_code := v_gpr_check;
EXCEPTION
    WHEN V_STATUS_CHECK_EXCEPTION  THEN
        --ST Added for FSS-5225
          BEGIN
            select nvl(ccs_consumed_status,'N')
            into l_consumed_status
            from cms_card_stat
            where ccs_stat_code=prm_card_stat;
          IF l_consumed_status='Y' then
          DBMS_OUTPUT.PUT_LINE('l_consumed_status = ' || l_consumed_status);
			BEGIN
                        BEGIN
                            SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
                                INTO v_vms_5306_toggle
                                FROM vmscms.cms_inst_param
                               WHERE cip_inst_code = prm_inst_code
                                 AND cip_param_key = 'VMS_5306_TOGGLE';
                       EXCEPTION
                            WHEN OTHERS THEN
                                v_vms_5306_toggle :='N';
                        END;

                        IF  v_vms_5306_toggle ='Y' THEN
                            IF  prm_delivery_channel IN ('01','02'  )
                            THEN
                            IF prm_msg_type IN ('1100','1101','1200','1201') THEN -- Added for VMS-6335
                                 BEGIN
                                        v_tran_date := TO_DATE(substr( trim(prm_tran_date),  1,  8 ) || ' ' || substr( trim(prm_tran_time), 1, 10 ), 'yyyymmdd hh24:mi:ss');

                                        sp_elan_preauthorize_txn(
                                            prm_card_number,
                                            NULL,
                                            NULL,
                                            v_tran_date,
                                            prm_tran_code,
                                            prm_inst_code,
                                            prm_tran_date,
                                            NULL,
                                            prm_delivery_channel,
                                            prm_merc_id,
                                            NULL,
                                            v_hold_amount,
                                            v_hold_days,
                                            v_resp_cde,
                                            v_err_msg,
                                            NULL
                                        );

                                        IF ( v_resp_cde <> '1' OR trim(v_err_msg) <> 'OK' ) THEN
                                            v_consumed_flagupd := 'N';
                                            prm_resp_code := v_resp_cde;
                                            prm_resp_msg := v_err_msg;
                                        END IF;
                                EXCEPTION
                                WHEN OTHERS THEN
                                    NULL;
                                END;
                           ELSE    --Added else condition for VMS-6335
                             v_consumed_flagupd := 'N';
                           END IF;
                        END IF;
                        END IF;
                    EXCEPTION
                    WHEN OTHERS THEN
                         NULL;
                    END;

        IF v_consumed_flagupd='Y' THEN
            BEGIN
              SELECT CPC_CONSUMED_CARD_STAT
              INTO v_updted_cardstatus
              FROM CMS_PROD_CATTYPE
              where cpc_inst_code=PRM_INST_CODE
              and cpc_prod_code = prm_prod_code
              AND CPC_CARD_TYPE   =prm_prod_catg;

              IF v_updted_cardstatus IS NOT NULL THEN
                vmscard.log_consumed_status_change( PRM_INST_CODE, prm_card_number ,prm_tran_date , prm_tran_time , v_updted_cardstatus,prm_delivery_channel,V_UPDATED_COUNT );
                 IF V_UPDATED_COUNT > 0 THEN
                 prm_resp_msg := prm_resp_msg ||' - Consumed';
                 ELSIF V_UPDATED_COUNT = 0 and
                 ((prm_delivery_channel ='10' and prm_tran_code = '25')
                 or (prm_delivery_channel ='07' and prm_tran_code = '01') or (prm_delivery_channel ='13' and prm_tran_code = '01')) THEN
                  prm_resp_code := '1';
                  prm_resp_msg := 'OK';
                END IF;
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              NULL;
            END;
            END IF;
             END IF;
        EXCEPTION
        WHEN OTHERS THEN
          NULL;
        END;
        --ED Added for FSS-5225
        IF prm_delivery_channel = '08'  THEN
        	 /*  IF prm_card_stat = '9'  THEN
                prm_resp_code := '7';
                --prm_resp_msg := 'Card/PIN is Suspended';
              prm_resp_msg := 'Card is Suspended';
            ELSIF prm_card_stat = '2' THEN
                prm_resp_code := '10';
             --   prm_resp_msg := 'Card/PIN is Lost';
                prm_resp_msg := 'Card is Lost/Stolen';
            ELSIF prm_card_stat = '3' THEN
                prm_resp_code := '11';
                --prm_resp_msg := 'Card/PIN is Stolen';
                prm_resp_msg := 'Card is Damage';
            ELSIF prm_card_stat = '0' THEN
                prm_resp_code := '8';
                --prm_resp_msg := 'Card/PIN is Stolen';--JIRA-1619 SPIL response code and response message are conflicting. 10031 is for inactive card and 10047 is for stolen card
                 prm_resp_msg := 'Card is Inactive';
            ELSIF prm_card_stat = '1' THEN
                prm_resp_code := '9';
                 prm_resp_msg := 'Card is Active';
                --prm_resp_msg := 'Card/PIN is Stolen';
            ELSIF prm_card_stat = '13' THEN
                prm_resp_code := '9';
                prm_resp_msg := 'Invalid Card Status ';
            --Sn Added by Pankaj S. for Mantis ID 12970
            ELSIF prm_card_stat = '14' THEN
                prm_resp_code := '136';
                prm_resp_msg := 'Transaction not allowed for card status';
            --En Added by Pankaj S. for Mantis ID 12970
             ELSIF prm_card_stat = '7' THEN --Added on 20/02/14 for defect id: 13724
                prm_resp_code := '13';
                prm_resp_msg := 'EXPIRED CARD';

            END IF;*/
			begin
        SELECT nvl(CCS_SPIL_RESP_ID,NVL(V_INDL_RESID, '10')),nvl(CCS_SPIL_RESP_MSG,'Transaction not allowed for card status')
        INTO prm_resp_code,prm_resp_msg
        FROM CMS_CARD_STAT WHERE CCS_STAT_CODE = prm_card_stat;
      exception
        when others then
          prm_resp_code:=NVL(V_INDL_RESID, '10');
          prm_resp_msg:='Transaction not allowed for card status';
      end;
         ELSE
            --prm_resp_code := '10'; --COMMENTED ON 19-12-2013 FOR MVCSD-4517
            prm_resp_code :=NVL(V_INDL_RESID, nvl(prm_resp_code,'10')); --ADDED ON 19-12-2013 FOR MVCSD-4517
        END IF;

	  if   v_appl_stat = '32' and  prm_delivery_channel != '08' then
                 prm_resp_code := '1';
                prm_resp_msg := 'OK';
		 END IF;

WHEN OTHERS THEN
    prm_resp_code := '21';
    prm_resp_msg :='Error in GPR Card Status Check' || SUBSTR (SQLERRM, 1, 300);
END;
/
show error