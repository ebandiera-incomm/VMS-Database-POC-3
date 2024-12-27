CREATE OR REPLACE PROCEDURE VMSCMS.SP_AUTHORIZE_LOG_ERROR
(prm_inst_code          NUMBER,
 prm_txn_code           VARCHAR2,
 prm_txn_type           VARCHAR2,
 prm_txn_mode           VARCHAR2,
 prm_tran_date          VARCHAR2,
 prm_tran_time          VARCHAR2,
 prm_card_no            VARCHAR2,
 prm_txn_amt            NUMBER,
 prm_delivery_channel   VARCHAR2,
 prm_resp_cde           VARCHAR2,
 prm_resp_msg           VARCHAR2,
 prm_isoresp_code  OUT     VARCHAR2,
 prm_err_msg       OUT     VARCHAR2
 )
 IS
 PRAGMA AUTONOMOUS_TRANSACTION;
 v_isoresp_code         VARCHAR2(300);
 BEGIN
	prm_err_msg := 'OK';
        --Sn select iso response code
        BEGIN
  SELECT CMS_ISO_RESPCDE
  INTO   v_isoresp_code
  FROM   CMS_RESPONSE_MAST
  WHERE  CMS_INST_CODE  = prm_inst_code
  AND    CMS_DELIVERY_CHANNEL = prm_delivery_channel
  AND    CMS_RESPONSE_ID  = v_resp_cde;
                prm_isoresp_code := v_isoresp_code;
 EXCEPTION
  WHEN OTHERS THEN
  prm_isoresp_code  := '89';
 END;
        --En select iso response code
        BEGIN
  INSERT INTO CMS_TRANSACTION_LOG_DTL
  VALUES
  (
  prm_txn_code,
  prm_txn_type,
  prm_txn_mode,
  prm_tran_date,
  prm_tran_time,
  prm_card_no,
  prm_txn_amt,
  'E',
  prm_resp_msg
  );
 EXCEPTION
  WHEN OTHERS THEN
    prm_err_msg := 'Problem while inserting data into transaction log  dtl' || SUBSTR(SQLERRM,1,300);
        END;
   EXCEPTION
        WHEN OTHERS THEN
        prm_err_msg := 'Problem from log error';
   END;
/


