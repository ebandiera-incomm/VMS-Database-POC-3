CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Change_Pin_Online
(
prm_inst_code NUMBER,
prm_pancode  VARCHAR2,
prm_mbrnumb  VARCHAR2,
prm_pinoffst VARCHAR2,
prm_resp_cde    OUT     VARCHAR2,
prm_resp_msg    OUT     VARCHAR2
)
IS
                v_rrn				VARCHAR2(200)	        ;
		v_delivery_channel		VARCHAR2(2)	        ;
		v_term_id			VARCHAR2(200)	        ;
		v_date_time			DATE                    ;
		v_txn_code			VARCHAR2(2)	        ;
		v_txn_type			VARCHAR2(2)	        ;
		v_txn_mode			VARCHAR2(2)	        ;
		v_tran_date			VARCHAR2(200)	        ;
		v_tran_time			VARCHAR2(200)	        ;
		v_txn_amt			NUMBER		        ;
		v_card_no			CMS_APPL_PAN.cap_pan_code%TYPE;
		v_resp_code			VARCHAR2(200)	        ;
		v_resp_msg			VARCHAR2(200)	        ;
                v_mbrnumb                       VARCHAR2(3)             ;
                v_errmsg                       VARCHAR2(300)           ;
                v_capture_date                  DATE;
				exp_reject_record				EXCEPTION;
BEGIN
                v_rrn			:= '654321';
		v_delivery_channel	:= '05';
		v_term_id		:= NULL;
		v_date_time		:= NULL;
		v_txn_code		:= 'OP';
		v_txn_type		:= '1';
		v_txn_mode		:= '0';
		v_tran_date		:= TO_CHAR ( SYSDATE , 'yyyymmdd')   ;    -- '20080723';
		v_tran_time		:= TO_CHAR( SYSDATE , 'HH24:MI:SS')  ;    --'16:21:10';
		v_card_no		:= prm_pancode ;
		v_txn_amt		:= 0;
             IF	TRIM  (prm_mbrnumb) IS NULL  THEN
			v_mbrnumb := '000';
		ELSE
			v_mbrnumb := prm_mbrnumb;
		END IF;
        --Sn call to authorize procedure
                        Sp_Authorize_Txn                                                                  ( V_RRN, V_DELIVERY_CHANNEL, V_TERM_ID, V_DATE_TIME,
				  		   		  					  V_TXN_CODE, V_TXN_TYPE, V_TXN_MODE, V_TRAN_DATE, V_TRAN_TIME,
				  									  V_CARD_NO, NULL, NULL, NULL,
				  									  NULL, V_TXN_AMT, NULL, NULL, NULL,
				  									  NULL, NULL, NULL, NULL, NULL, NULL,
				  									  NULL, NULL, NULL, NULL,
				  									  NULL, NULL, NULL, NULL,
				  									  NULL,NULL, V_RESP_CODE, V_RESP_MSG , V_CAPTURE_DATE );
			IF  V_RESP_CODE <> '00' THEN
				v_errmsg := V_RESP_MSG;
				RAISE exp_reject_record;
			END IF;
        --En call to authorize procedure
        --Sn update  pin off set in appl_pan
                                UPDATE CMS_APPL_PAN
                                SET    CAP_PIN_OFF = prm_pinoffst
                                WHERE  CAP_PAN_CODE = prm_pancode
                                AND    CAP_MBR_NUMB = prm_mbrnumb;
                                IF SQL%ROWCOUNT <> 1 THEN
                                v_resp_code := '21';
                                v_errmsg := 'Error while updating appl_pan';
				RAISE exp_reject_record;
			        END IF;
        --En update  pin off set in appl_pan
        --Sn insert a record for successful txn
                INSERT INTO CMS_SPPRTFUNC_LOG_DTL
                VALUES
                        (
                                v_delivery_channel,
                                v_txn_code,
                                v_txn_type,
                                v_txn_mode,
                                v_tran_date,
                                v_tran_time,
                                prm_pancode,
                                'on line pin change' ,
                                'Y',
                                'OK'
                        );
       --En insert a record for successful txn
	   prm_resp_cde := V_RESP_CODE;
	   prm_resp_msg :=  V_RESP_MSG;

EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        ROLLBACK;
        prm_resp_cde := v_resp_code;
        prm_resp_msg := v_errmsg;
        --Sn insert a record for successful txn
                INSERT INTO CMS_SPPRTFUNC_LOG_DTL
                VALUES
                        (
                                v_delivery_channel,
                                v_txn_code,
                                v_txn_type,
                                v_txn_mode,
                                v_tran_date,
                                v_tran_time,
                                prm_pancode,
                                'on line pin change',
                                'E',
                                 prm_resp_msg
                        );
       --En insert a record for successful txn
       WHEN OTHERS THEN
        ROLLBACK;
        prm_resp_cde := '21';
        prm_resp_msg := 'Error while updating pin offset ' || SUBSTR(SQLERRM, 1, 300);
        INSERT INTO CMS_SPPRTFUNC_LOG_DTL
                VALUES
                        (
                                v_delivery_channel,
                                v_txn_code,
                                v_txn_type,
                                v_txn_mode,
                                v_tran_date,
                                v_tran_time,
                                prm_pancode,
                                'on line pin change',
                                'E',
                                 prm_resp_msg
                        );
END;
/


