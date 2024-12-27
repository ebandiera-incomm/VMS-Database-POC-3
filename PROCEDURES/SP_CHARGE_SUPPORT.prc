CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHARGE_SUPPORT (
   instcode   IN       NUMBER,
   pancode     IN       VARCHAR2,
   spprtkey   IN 	   VARCHAR2,
   lupduser   IN       NUMBER,
   errmsg     OUT      VARCHAR2
)
AS

v_fee_amt CMS_SPPRT_FEE_MAST.CSF_FEE_AMT%TYPE;
v_mbr_numb CMS_APPL_PAN.cap_mbr_numb%TYPE;
v_cust_code CMS_APPL_PAN.cap_cust_code%TYPE;
v_acct_id CMS_APPL_PAN.cap_acct_id%TYPE;
v_acct_no CMS_APPL_PAN.cap_acct_no%TYPE;

BEGIN
	errmsg :='OK';
	BEGIN
		SELECT CSF_FEE_AMT INTO v_fee_amt
		FROM CMS_SPPRT_FEE_MAST
		WHERE CSF_SPPRT_KEY=spprtkey;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		errmsg := 'No Fee Attached';
		WHEN OTHERS THEN
		errmsg := 'Excp 1 -- '||SQLERRM;
	END;
	BEGIN
		SELECT cap_mbr_numb,cap_cust_code,cap_acct_id,cap_acct_no
		INTO v_mbr_numb,v_cust_code,v_acct_id,v_acct_no
		FROM CMS_APPL_PAN
		WHERE cap_pan_code=pancode;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		errmsg := 'Error Getting PAN Details ';
		WHEN OTHERS THEN
		errmsg := 'Excp 1 -- '||SQLERRM;
	END;

	BEGIN
		dbms_output.put_line('Before Insert ');

		INSERT INTO CMS_CHARGE_DTL(	CCD_INST_CODE		,
						CCD_PAN_CODE		,
						CCD_MBR_NUMB		,
						CCD_CUST_CODE	,
						CCD_ACCT_ID		,
						CCD_ACCT_NO		,
						CCD_FEE_FREQ		,
						CCD_FEETYPE_CODE ,
						CCD_FEE_CODE	,
						CCD_CALC_AMT		,
						CCD_EXPCALC_DATE	,
						CCD_CALC_DATE		,
						CCD_FILE_NAME		,
						CCD_FILE_DATE		,
						CCD_INS_USER		,
						CCD_LUPD_USER	)
						VALUES (
						instcode,
						pancode,
						v_mbr_numb,
						v_cust_code,
						v_acct_id,
						v_acct_no,
						'R',
						99,
						999,
						v_fee_amt,
						SYSDATE,
						SYSDATE,
						'SUPPFN',
						SYSDATE,
						lupduser,
						lupduser
						);

			IF SQL%rowcount = 0 THEN
				dbms_output.put_line('Row Not Inserted : ');
			   errmsg := 'Error in Inserting Charge Details';
			END IF;
			END;
			EXCEPTION
						WHEN OTHERS THEN
								errmsg := 'Error in Inserting Charge Details'||SQLERRM;


			dbms_output.put_line('Test Charge : '||errmsg);
END;
/


show error