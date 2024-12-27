CREATE OR REPLACE PROCEDURE VMSCMS.SP_PASSIVEPERIOD_CALC(P_INST_CODE        IN NUMBER,
                                    P_CARD_NUMBER      IN VARCHAR2,
                                    P_PROD_CODE        IN VARCHAR2,
                                    P_PROD_CATG        IN VARCHAR2,
                                    P_TRAN_DATE        IN VARCHAR2,
                                    P_TRAN_TIME        IN VARCHAR2,
                                    P_DEL_CHANNEL      IN VARCHAR2,
                                    P_RESP_CODE        OUT VARCHAR2,
                                    P_RESP_MSG         OUT VARCHAR2
                                    ) IS



/*************************************************
     * Modified By      :  Deepa
     * Modified Date    :  20-June-2012
     * Modified Reason  :  Fee changes
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  21-June-2012
     * Build Number     :  CMS3.5.1_RI0010_B0009
 *************************************************/
  V_HASH_PAN                CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN                CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_LAST_TRANDATE           NUMBER(14);
  V_PASSIVE_TIME_PRODCATG   CMS_PROD_CATTYPE.CPC_PASSIVE_TIME%TYPE;
  V_PASSIVE_DAYS            CMS_PROD_CATTYPE.CPC_PASSIVE_TIME%TYPE;
  v_passive_period          CMS_PROD_CATTYPE.CPC_PASSIVE_TIME%TYPE;
  v_active_date             DATE;
  EXP_REJECT_PASSIVE        EXCEPTION;
  v_prod_code               CMS_APPL_PAN.cap_prod_Code%TYPE;
  v_prod_catg               CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_LAST_TRAN_DATE          TRANSACTIONLOG.BUSINESS_DATE%TYPE;
  V_LAST_TRAN_TIME          TRANSACTIONLOG.BUSINESS_TIME%TYPE;
  V_DEL_CHANNEL             CMS_DELCHANNEL_MAST.CDM_CHANNEL_CODE%TYPE;
  v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991

BEGIN

SAVEPOINT V_PASSIVECARD_SAVEPOINT;
--SN CREATE HASH PAN
    BEGIN
     V_HASH_PAN := GETHASH(P_CARD_NUMBER);
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE:='89';
       P_RESP_MSG := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_PASSIVE;--Added for Exception handling in GPR card Status--deepa
    END;

    --EN CREATE HASH PAN

    --SN create encr pan
    BEGIN
     V_ENCR_PAN := FN_EMAPS_MAIN(P_CARD_NUMBER);
    EXCEPTION
     WHEN OTHERS THEN
        P_RESP_CODE:='89';
       P_RESP_MSG := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_PASSIVE;--Added for Exception handling in GPR card Status--deepa
    END;



   --Sn Passive Period calculation
   BEGIN

   SELECT   cap_active_date,cap_prod_Code,CAP_CARD_TYPE
           INTO v_active_date,v_prod_code,v_prod_catg
           FROM cms_appl_pan, cms_prod_cattype
          WHERE cap_card_stat IN ('1')
            AND cap_inst_code = P_INST_CODE
            AND cap_prod_code = cpc_prod_code
            AND cap_card_type = cpc_card_type
            AND CAP_PAN_CODE=V_HASH_PAN
            AND (cpc_passive_time IS NOT NULL AND cpc_passive_time!='0')
            AND CPC_INST_CODE=P_INST_CODE
            AND CAP_EXPRY_DATE > sysdate; --Added by Deepa on June-06-2012 to calculate the passive period only for the active and non-expired cards

                 BEGIN

                 /*Added to calculate the passive period if the
                 Passive period flag of deliverychannel(in which transaction is done) is 'Y' in GPR Cardstatus --deepa*/
                 select CDM_CHANNEL_CODE
                 into V_DEL_CHANNEL
                     from cms_delchannel_mast
                     where CDM_PASSIVEPERIOD_FLAG='Y'
                     and CDM_CHANNEL_CODE=P_DEL_CHANNEL
                     AND CDM_INST_CODE=P_INST_CODE;

                 BEGIN
                 /*Modified the query to calculate the passive period based on the
                 Passive period flag of deliverychannel in GPR Cardstatus --deepa*/
                      SELECT MAX (business_date || business_time)
                      INTO v_last_trandate
                      FROM VMSCMS.TRANSACTIONLOG  --Added for VMS-5733/FSP-991
                     WHERE customer_card_no = V_HASH_PAN
                     AND instcode = P_INST_CODE
                     AND DELIVERY_CHANNEL IN (select CDM_CHANNEL_CODE
                     from cms_delchannel_mast
                     where CDM_PASSIVEPERIOD_FLAG='Y'
                     and CDM_INST_CODE=P_INST_CODE);
					 IF SQL%ROWCOUNT = 0 THEN 
					 SELECT MAX (business_date || business_time)
                      INTO v_last_trandate
                      FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST   --Added for VMS-5733/FSP-991
                     WHERE customer_card_no = V_HASH_PAN
                     AND instcode = P_INST_CODE
                     AND DELIVERY_CHANNEL IN (select CDM_CHANNEL_CODE
                     from cms_delchannel_mast
                     where CDM_PASSIVEPERIOD_FLAG='Y'
                     and CDM_INST_CODE=P_INST_CODE);
					 END IF;


                    EXCEPTION

                     WHEN NO_DATA_FOUND THEN
                     v_last_trandate:=NULL;
                     WHEN OTHERS THEN
                     v_last_trandate:=NULL;
                  END ;


                     IF v_last_trandate IS NULL THEN

                     v_last_trandate:=to_char(v_active_date,'YYYYMMDDHH24MISS');


                     END IF;

                     BEGIN

                        SELECT TRUNC ( TO_DATE (P_tran_date || P_tran_time,
                                 'yyyymmdd hh24:mi:ss')
                        - TO_DATE (v_last_trandate, 'yyyymmdd hh24:mi:ss')
                            )
                        INTO v_passive_days
                        FROM DUAL;

                        EXCEPTION --Added for Exception handling in calculating the passive period--deepa
                        WHEN OTHERS THEN

                            P_RESP_CODE := '89';
                            P_RESP_MSG    := 'Problem in calculating passive days' ||
                                            SUBSTR(SQLERRM, 1, 200);
                            RAISE EXP_REJECT_PASSIVE;

                      END;

                      --Added to substring the date and time instead of substring it in the insert query--deepa
                      v_last_tran_date:=substr(v_last_trandate,1,8);
                      v_last_tran_time:=substr(v_last_trandate,9)  ;


                        BEGIN
                         SELECT cpc_passive_time
                         INTO V_PASSIVE_TIME_PRODCATG
                         FROM cms_prod_cattype
                         WHERE cpc_prod_code =v_prod_code-- P_PROD_CODE--Modified to avoid the execution of query in java to get these datails -- deepa
                         AND cpc_card_type = v_prod_catg--P_PROD_CATG--Modified to avoid the execution of query in java to get these datails -- deepa
                         AND cpc_inst_code = P_INST_CODE;

                            EXCEPTION --Added for Exception handling while selecting he passive period of product category--deepa
                     WHEN NO_DATA_FOUND THEN

                        P_RESP_CODE := '89';
                        P_RESP_MSG    := 'Problem while selecting Passive period of Product Catg' ||
                                            SUBSTR(SQLERRM, 1, 200);
                        RAISE EXP_REJECT_PASSIVE;

                   WHEN OTHERS THEN

                        P_RESP_CODE := '89';
                        P_RESP_MSG    := 'Error while selecting cms_prod_cattype' || SUBSTR(SQLERRM, 1, 200);
                        RAISE EXP_REJECT_PASSIVE;
                  END ;

                     IF v_passive_days>V_PASSIVE_TIME_PRODCATG THEN

                           BEGIN
                                insert into cms_passivecard_details (CPD_INST_CODE,
                             CPD_PAN_CODE,CPD_PAN_CODE_ENCR,
                              CPD_LAST_TRANDATE  ,
                              CPD_LAST_TRANTIME  ,
                              CPD_CURRTRAN_DATE   ,
                              CPD_CURRTRAN_TIME  ,
                              CPD_PASSIVE_PERIOD,
                              CPD_PROCESS_FLAG,
                              CPD_INS_USER,
                              CPD_LUPD_USER )values(P_INST_CODE,V_HASH_PAN,
                              V_ENCR_PAN,v_last_tran_date,v_last_tran_time,
                              P_tran_date,P_TRAN_TIME,v_passive_days,'N',
                              '1','1');

                               --commented as the Passive details are inserted and the card is used no need of updating the status--deepa


                               /*Added for Exception handling if no rows are inserted
                              in passive period calculation of GPPR card status--deepa*/

                               IF SQL%ROWCOUNT = 0 THEN

                                 P_RESP_CODE := '89';
                                 P_RESP_MSG  := 'Problem in inserting the passive details';
                                 RAISE EXP_REJECT_PASSIVE;

                               END IF;


                           EXCEPTION
                            WHEN EXP_REJECT_PASSIVE THEN--Added by Deepa on Apr-19-2012 to log the error
                            RAISE;
                            WHEN OTHERS THEN

                               P_RESP_CODE := '89';
                               P_RESP_MSG    := 'Problem while inserting passive card details' ||
                                            SUBSTR(SQLERRM, 1, 200);
                               RAISE EXP_REJECT_PASSIVE;
                            END;


                     END IF;
                 EXCEPTION
                 WHEN EXP_REJECT_PASSIVE THEN--Added by Deepa on Apr-19-2012 to log the error
                 RAISE;
                 WHEN OTHERS THEN
                 NULL;

                    END;
      EXCEPTION
        WHEN EXP_REJECT_PASSIVE THEN
        RAISE;
         WHEN OTHERS THEN
          NULL;


    END;
   --En Passive Period calculation


  P_RESP_CODE := 1;
  P_RESP_MSG  := 'OK';
EXCEPTION
  WHEN EXP_REJECT_PASSIVE THEN

  ROLLBACK TO V_PASSIVECARD_SAVEPOINT;
  /*Added for the Passive Period Calculation in GPR card status to log the
  failure details of Passive period calculation --deepa*/

  BEGIN

INSERT INTO cms_passiveperiod_fail_dtl
            (cpd_inst_code, cpd_pan_code, cpd_pan_code_encr,
             cpd_currtran_date, cpd_currtran_time, cpd_lasttran_date,
             cpd_lasttrantime, cpd_ins_user, cpd_ins_date, cpd_lupd_user,
             cpd_lupd_date, cpd_resp_code, cpd_process_msg,cpd_delivery_channel
            )
     VALUES (P_inst_code, v_hash_pan, v_encr_pan,
             P_tran_date, P_tran_time, v_last_tran_date,
             v_last_tran_time, '1', SYSDATE, '1',
             SYSDATE, P_resp_code, P_resp_msg,P_DEL_CHANNEL
            );

      IF SQL%ROWCOUNT = 0 THEN

        P_RESP_CODE := '89';
        P_RESP_MSG  := 'Problem in inserting the FAILURE DETAILS OF PASSIVE PERIOD CALCULATION';

      END IF;
  END;

  WHEN OTHERS THEN
    P_RESP_CODE := '89';--21;--Modifed as this not mapped in cms_response_mast.In case of serever decline response code sholud be 89--deepa
    P_RESP_MSG  := 'Error in Passive period details' ||
                 SUBSTR(SQLERRM, 1, 200);
    ROLLBACK TO V_PASSIVECARD_SAVEPOINT;
    /*Added for the Passive Period Calculation in GPR card status to log the
  failure details of Passive period calculation --deepa*/

     BEGIN

INSERT INTO cms_passiveperiod_fail_dtl
            (cpd_inst_code, cpd_pan_code, cpd_pan_code_encr,
             cpd_currtran_date, cpd_currtran_time, cpd_lasttran_date,
             cpd_lasttrantime, cpd_ins_user, cpd_ins_date, cpd_lupd_user,
             cpd_lupd_date, cpd_resp_code, cpd_process_msg,cpd_delivery_channel
            )
     VALUES (P_inst_code, v_hash_pan, v_encr_pan,
             P_tran_date, P_tran_time, v_last_tran_date,
             v_last_tran_time, '1', SYSDATE, '1',
             SYSDATE, P_resp_code, P_resp_msg,P_DEL_CHANNEL
            );

      IF SQL%ROWCOUNT = 0 THEN

        P_RESP_CODE := '89';
        P_RESP_MSG  := 'Problem in inserting the FAILURE DETAILS OF PASSIVE PERIOD CALCULATION';

      END IF;
  END;
END;
/
show error;

