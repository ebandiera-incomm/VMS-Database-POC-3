create or replace PROCEDURE       VMSCMS.SP_SMSEMAIL_DAILY_ALTMSG(PRM_INSTCODE IN NUMBER,
										   PRM_ERR_MSG  OUT VARCHAR2,
                       PRM_JOB_ID   IN  NUMBER) IS

  /*************************************************
      * Created By       :  NA
      * Created Date     :  NA
      * Modified By      :  T.Narayanaswamy
      * Modified Date    :  12-June-2012
      * Modified Reason  :  For Separting the configuration of SMS and Email
      * Reviewer         :  B.Besky Anand.
      * Reviewed Date    :  18-June-2012
      * Build Number     :  CMS3.5.1_RI0010_B0002

      * Modified By      :  Pankaj s
	    * Modified For     :  FSS-289
      * Modified Date    :  28_Mar_2013
      * Modified Reason  :  To avoid the customer getting alerts for closed card(MVHOST-289)
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  28_Mar_2013
      * Build Number     :  RI0024_B0012

      * Modified By      :  Arun
	  * Modified For     :  12362
      * Modified Date    :  16/09/2013
      * Modified Reason  :  Daily balance alert not recevied after complition of scheduler execution
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  16/09/2013
      * Build Number     :  RI0024.4_B0014

      * Modified by      : MageshKumar S
      * Modified for     : HOSTCC-51
      * Modified Date    : 03-FEB-2016
      * Reviewer         : Saravanankumar/SPankaj
      * Build Number     : VMSGPRHOST_4.0_B0001

      * Modified by      : MageshKumar S
      * Modified for     : Mantis Id:0016311
      * Modified Date    : 22-MAR-2016
      * Reviewer         : Saravanankumar/SPankaj
      * Build Number     : VMSGPRHOST_4.0_B0006

      * Modified by      : MageshKumar S
      * Modified for     : Mantis Id:0016311
      * Modified Date    : 31-MAR-2016
      * Reviewer         : Saravanankumar/SPankaj
      * Build Number     : VMSGPRHOST_4.0_B0009

      * Modified by      : T.Narayanaswamy
      * Modified for     : FSS-4933
      * Modified Date    : 28-NOV-2016
      * Reviewer         : Saravanankumar/SPankaj
      * Build Number     : VMSGPRHOST_4.11_B0003

      * Modified by      : Saravanakumar A
      * Modified for     :  Daily Balance Alert Issue
                            FSS-5123
      * Modified Date    : 20-APR-2016
      * Reviewer         : SPankaj
      * Build Number     : VMSGPRHOST_17.04
      
      * Modified by      : Magesh Kumar S
      * Modified for     : VMS-180
      * Modified Date    : 23-JAN-2018
      * Reviewer         : Saravanakumar A
      * Build Number     : VMSGPRHOST_18.01
      
      * Modified by      : UBAIDUR RAHMAN H
      * Modified for     : VMS-2010
      * Modified Date    : 26-JAN-2020
      * Reviewer         : Saravanakumar A
      * Build Number     : VMSGPRHOST_R27_B2
  *************************************************/
  V_SERIAL_NO NUMBER;
  V_ERRMSG    VARCHAR2(500);
  EXP_REJECT_RECORD EXCEPTION;
  --Added single quotes for card status <> '9' for mantis id:12362
  CURSOR C1(INST_CODE IN NUMBER,JOB_ID IN NUMBER) IS
	/*SELECT CAP_INST_CODE, CSA_PAN_CODE, CSA_PAN_CODE_ENCR,
       CAM_MOBL_ONE, CAM_EMAIL, CSA_DAILYBAL_FLAG
       --CSA_BEGIN_TIME,CSA_END_TIME--, CSA_LOWBAL_FLAG, CSA_LOWBAL_AMT
	  FROM CMS_SMSANDEMAIL_ALERT, CMS_ADDR_MAST, CMS_APPL_PAN
 WHERE     CSA_DAILYBAL_FLAG <> '0'--OR CSA_LOWBAL_FLAG <> '0')
		   AND CAP_PAN_CODE = CSA_PAN_CODE
		   AND CAM_INST_CODE = CAP_INST_CODE
		   AND CAM_CUST_CODE = CAP_CUST_CODE
		   AND CAM_ADDR_CODE = CAP_BILL_ADDR
		   AND CAP_INST_CODE = INST_CODE
		   AND CAP_CARD_STAT <> '9'
		   AND CAP_PROD_CODE IN
				  (SELECT DISTINCT CPM_PROD_CODE
					 FROM CMS_BIN_PARAM, CMS_PROD_MAST
					WHERE     CPM_PROFILE_CODE = CBP_PROFILE_CODE
						  AND CBP_PARAM_NAME = 'Currency'
						  AND CBP_PARAM_VALUE IN (SELECT VAM_CCY_CODE
													FROM VMS_ALTCCY_MAPP
												   WHERE VAM_JOB_ID = PRM_JOB_ID));*/
                           
     SELECT CAP_INST_CODE, CSA_PAN_CODE, CSA_PAN_CODE_ENCR,
       ADDR.CAM_MOBL_ONE cam_mobl_one,
       ADDR.CAM_EMAIL cam_email,
       CSA_DAILYBAL_FLAG
       --CSA_BEGIN_TIME,CSA_END_TIME--, CSA_LOWBAL_FLAG, CSA_LOWBAL_AMT
	  FROM CMS_SMSANDEMAIL_ALERT, CMS_ADDR_MAST ADDR, CMS_APPL_PAN,
    CMS_PROD_CATTYPE,CMS_ACCT_MAST ACCT
 WHERE CSA_DAILYBAL_FLAG <> '0'--OR CSA_LOWBAL_FLAG <> '0')
		   AND CAP_PAN_CODE = CSA_PAN_CODE
		   AND CAP_INST_CODE = ADDR.CAM_INST_CODE 
		   AND CAP_CUST_CODE = ADDR.CAM_CUST_CODE
		 ---  AND CAM_ADDR_CODE = CAP_BILL_ADDR
		   AND cam_addr_flag = 'P'                --- Modified for impact on VMS-2010.
		   AND CAP_INST_CODE = INST_CODE
		   AND CAP_CARD_STAT <> '9'
       AND CAP_ACCT_NO = ACCT.CAM_ACCT_NO
       AND CAP_INST_CODE = ACCT.CAM_INST_CODE
       AND CAP_INST_CODE = CPC_INST_CODE
       AND CAP_PROD_CODE = CPC_PROD_CODE
       AND CAP_CARD_TYPE = CPC_CARD_TYPE
       AND (cap_card_stat IN (select regexp_substr(CPC_ALERT_CARD_STAT,'[^,]+', 1, level) from dual
                                     connect by regexp_substr(CPC_ALERT_CARD_STAT, '[^,]+', 1, level) is not null) OR CPC_ALERT_CARD_STAT IS NULL)
       AND (ACCT.CAM_ACCT_BAL > CPC_ALERT_CARD_AMOUNT OR CPC_ALERT_CARD_AMOUNT IS NULL)
       AND ( (SYSDATE-CAP_LAST_TXNDATE) < CPC_ALERT_CARD_DURATION OR CPC_ALERT_CARD_DURATION IS NULL)
		   AND exists
				  (SELECT 1
					 FROM CMS_BIN_PARAM
					WHERE     CBP_PROFILE_CODE = CPC_PROFILE_CODE
						  AND CBP_PARAM_NAME = 'Currency'
						  AND CBP_PARAM_VALUE IN (SELECT VAM_CCY_CODE
													FROM VMS_ALTCCY_MAPP
												   WHERE VAM_JOB_ID = PRM_JOB_ID));
                           
  /*  SELECT CAP_INST_CODE,
		 CSA_PAN_CODE,
		 CSA_PAN_CODE_ENCR,
		 CAM_MOBL_ONE,
		 CAM_EMAIL,
		 CSA_DAILYBAL_FLAG,
		 CSA_BEGIN_TIME,
		 CSA_END_TIME,
		 CSA_LOWBAL_FLAG,
		 CSA_LOWBAL_AMT
	 FROM CMS_SMSANDEMAIL_ALERT,
		 CMS_ADDR_MAST,
		 CMS_CUST_MAST,
		 CMS_APPL_PAN
    /* T.Narayanan changed For Separting the configuration of SMS and Email on 12th june 2012  -- beg */
/*	WHERE (CSA_DAILYBAL_FLAG <> 0 OR CSA_LOWBAL_FLAG <> 0) AND
		 CCM_CUST_CODE = CAP_CUST_CODE AND CAP_INST_CODE = CSA_INST_CODE AND
		 CAM_CUST_CODE = CAP_CUST_CODE AND CAP_PAN_CODE = CSA_PAN_CODE AND
		 CAM_ADDR_CODE = CAP_BILL_ADDR AND CAP_INST_CODE = INST_CODE
     AND CAP_CARD_STAT <> '9'   --condition added for MVHOST-289(To avoid the customer getting alerts for closed card)
		 AND CAP_PROD_CODE IN(SELECT DISTINCT CPM_PROD_CODE FROM CMS_BIN_PARAM,CMS_PROD_MAST
     WHERE CPM_PROFILE_CODE=CBP_PROFILE_CODE
     AND  CBP_PARAM_NAME='Currency' AND CBP_PARAM_VALUE IN(SELECT VAM_CCY_CODE FROM VMS_ALTCCY_MAPP WHERE VAM_JOB_ID=PRM_JOB_ID));*/
  /* T.Narayanan changed For Separting the configuration of SMS and Email on 12th june 2012  -- end */

  --SN   LOCAL PROCEDURE
  PROCEDURE LP_SMS_SRNO(L_INSTCODE IN NUMBER,
				    L_SRNO     OUT VARCHAR2,
				    L_ERRMSG   OUT VARCHAR2,
            PRM_JOB_ID IN NUMBER) IS
    V_SER_NUMB NUMBER;
  BEGIN
    L_ERRMSG := 'OK';

    SELECT CSS_SERIAL_NUMBER
	 INTO V_SER_NUMB
	 FROM CMS_SMS_SERIAL
	--WHERE CSS_INST_CODE = L_INSTCODE AND CSS_SMS_DATE LIKE SYSDATE;
  WHERE CSS_INST_CODE = PRM_JOB_ID AND CSS_SMS_DATE LIKE SYSDATE;

    IF LENGTH(V_SER_NUMB) > 10 THEN
	 L_ERRMSG := 'Maximum serial number reached';
	 RETURN;
    END IF;

    L_SRNO := V_SER_NUMB;

    UPDATE CMS_SMS_SERIAL
	  SET CSS_SERIAL_NUMBER = V_SER_NUMB + 1
	--WHERE CSS_INST_CODE = L_INSTCODE AND CSS_SMS_DATE LIKE SYSDATE;
    WHERE CSS_INST_CODE = PRM_JOB_ID AND CSS_SMS_DATE LIKE SYSDATE;

    IF SQL%ROWCOUNT = 0 THEN
	 L_ERRMSG := 'Error while updating serial no';
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	 UPDATE CMS_SMS_SERIAL
	    SET CSS_SERIAL_NUMBER = 2
	 -- WHERE CSS_INST_CODE = L_INSTCODE;
    WHERE CSS_INST_CODE = PRM_JOB_ID;
	 V_SER_NUMB := 1;
	 L_SRNO     := V_SER_NUMB;
    WHEN OTHERS THEN
	 L_ERRMSG := 'Excp1 LP2 -- ' || SQLERRM;
  END;
  --EN  LOCAL PROCEDURE
BEGIN
  --<< MAIN BEGIN >>
  PRM_ERR_MSG := 'OK';
IF PRM_JOB_ID = 1 THEN
 truncate_tab_ebr ('CMS_SMSEMAIL_DAILY_ALTMSG');
ELSE
   truncate_tab_ebr ('VMS_NONUS_DAILY_ALTMSG');
  END IF;

  FOR X IN C1(PRM_INSTCODE,PRM_JOB_ID) LOOP
    --Sn find the serial no for the sms
    BEGIN
	 LP_SMS_SRNO(PRM_INSTCODE, V_SERIAL_NO, V_ERRMSG,PRM_JOB_ID);
    EXCEPTION
	 WHEN OTHERS THEN
	   V_ERRMSG := 'Error while selecting serial no from cms_sms_serial' ||
				SUBSTR(SQLERRM, 1, 300);
	   -- RAISE EXP_REJECT_RECORD;
    END;
    --En find the serial no for the sms
    IF V_ERRMSG = 'OK' THEN
    IF PRM_JOB_ID = 1 THEN  --Sn create record in CMS_SMSEMAIL_DAILY_ALTMSG
	 BEGIN
	   INSERT INTO CMS_SMSEMAIL_DAILY_ALTMSG
		(CSD_INST_CODE,
		 CSD_SERIAL_NO,
		 CSD_PAN_CODE,
		 CSD_PAN_CODE_ENCR,
		 CSD_MOBILE_NUMBER,
		 CSD_EMAIL,
		-- CSD_BEGIN_INTERVAL,
		-- CSD_END_INTERVAL,
		 CSD_DAILYBAL_MSG,
		-- CSD_LOWBAL_MSG,
		 CSD_PROCESS_STATUS,
		 CSD_INS_DATE)
	   VALUES
		(PRM_INSTCODE,
		 LPAD(V_SERIAL_NO, 10, '0'),
		 X.CSA_PAN_CODE,
		 X.CSA_PAN_CODE_ENCR,
		 X.CAM_MOBL_ONE,
		 X.CAM_EMAIL,
		 --TO_DATE(TO_CHAR(SYSDATE, 'mmddyyyy') || ' ' || X.CSA_BEGIN_TIME,
			--    'MMDDYYYY hh:mi AM'),
		 --TO_DATE(TO_CHAR(SYSDATE, 'mmddyyyy') || ' ' || X.CSA_END_TIME,
			--    'MMDDYYYY hh:mi AM'),
		 X.CSA_DAILYBAL_FLAG,
		-- X.CSA_LOWBAL_FLAG,
		 'N',
		 SYSDATE);

	   EXIT WHEN C1%NOTFOUND;
	 EXCEPTION
	   WHEN DUP_VAL_ON_INDEX THEN
		V_ERRMSG := 'Duplicate record exist  in CMS_SMSEMAIL_DAILY_ALTMSG for pan  ' ||
				  X.CSA_PAN_CODE;
		--RAISE EXP_REJECT_RECORD;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while inserting records into CMS_SMSEMAIL_DAILY_ALTMSG ' ||
				  SUBSTR(SQLERRM, 1, 200);
		--RAISE EXP_REJECT_RECORD;
		 END; --En create record in CMS_SMSEMAIL_DAILY_ALTMSG
         ELSE
         --Sn create record in cms_nonus_daily_altmsg
          BEGIN
            INSERT INTO VMS_NONUS_DAILY_ALTMSG
                        (VND_INST_CODE,
                         VND_SERIAL_NO,
                         VND_PAN_CODE,
                         VND_PAN_CODE_ENCR,
                         VND_MOBILE_NUMBER,
                         VND_EMAIL,
                        -- VND_BEGIN_INTERVAL,
                        -- VND_END_INTERVAL,
                         VND_DAILYBAL_MSG,
                       --  VND_LOWBAL_MSG,
                         VND_PROCESS_STATUS,
                         VND_INS_DATE)
                         VALUES
                        (PRM_INSTCODE,
                         LPAD(V_SERIAL_NO, 10, '0'),
                         X.CSA_PAN_CODE,
                         X.CSA_PAN_CODE_ENCR,
                         X.CAM_MOBL_ONE,
                         X.CAM_EMAIL,
                        -- TO_DATE(TO_CHAR(SYSDATE, 'mmddyyyy') || ' ' || X.CSA_BEGIN_TIME,
                          --    'MMDDYYYY hh:mi AM'),
                         --TO_DATE(TO_CHAR(SYSDATE, 'mmddyyyy') || ' ' || X.CSA_END_TIME,
                         --     'MMDDYYYY hh:mi AM'),
                         X.CSA_DAILYBAL_FLAG,
                        -- X.CSA_LOWBAL_FLAG,
                         'N',
                         SYSDATE);

            EXIT WHEN c1%NOTFOUND;
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
               v_errmsg :=
                     'Duplicate record exist  in vms_nonus_daily_altmsg for pan  '
                  || x.csa_pan_code;
            --RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while inserting records into vms_nonus_daily_altmsg '
                  || SUBSTR (SQLERRM, 1, 200);
         --RAISE EXP_REJECT_RECORD;
         END;
      --En create record in vms_nonus_daily_altmsg
      END IF;
      END IF;
   END LOOP;
EXCEPTION
  --<< MAIN EXCEPTION >>
  WHEN OTHERS THEN
    PRM_ERR_MSG := 'Error while processing daily sms ' ||
			    SUBSTR(SQLERRM, 1, 150);
END; --<< MAIN END>>
/
show error