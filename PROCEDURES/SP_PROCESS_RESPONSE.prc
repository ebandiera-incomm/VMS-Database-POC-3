CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Process_Response (
   instcode   IN       NUMBER,
   lupduser   IN       NUMBER,
   proid 	  OUT	   NUMBER,
   errmsg     OUT      VARCHAR2
)
AS
   v_req_id         PCMS_REQ_HOST.prh_req_id%TYPE;
   v_rowid          ROWID;
   v_process_flag   PCMS_RESP_HOST.prh_process_flag%TYPE;
   v_source_type    PCMS_REQ_HOST.prh_source_type%TYPE;
   v_appl_code      PCMS_REQ_HOST.prh_appl_code%TYPE;
   v_amt            PCMS_REQ_HOST.prh_tran_amt%TYPE;
   v_pan            CMS_APPL_PAN.cap_pan_code%TYPE;
   v_next_record 	CHAR(1);

   CURSOR c1
   IS
      SELECT prh_resp_id, prh_ref_no, prh_stat_code, prh_process_flag, ROWID
        FROM PCMS_RESP_HOST
       WHERE prh_process_flag IN ('P', 'E');


  CURSOR c2(REF_NO VARCHAR2)
  IS
	 SELECT prh_req_id, prh_source_type, prh_appl_code, prh_tran_amt,
			      ROWID
--           INTO v_req_id, v_source_type, v_appl_code, v_amt,
--		                v_rowid
           FROM PCMS_REQ_HOST
--          WHERE prh_ref_no = x.prh_ref_no;
          WHERE prh_ref_no = REF_NO;

   PROCEDURE lp_update_req_resp (
      req_flag     IN   VARCHAR2,
      req_rowid         ROWID,
      resp_flag    IN   VARCHAR2,
      resp_rowid        ROWID,
      resp_id           NUMBER
   )
   AS
   BEGIN

   		DBMS_OUTPUT.PUT_LINE('CALLING lp_update_req_resp');
		DBMS_OUTPUT.PUT_LINE(req_flag ||' : '|| req_rowid ||' : '|| resp_flag||' : '||resp_rowid||' : '||resp_id );

      IF req_flag IS NOT NULL
      THEN
	  	  DBMS_OUTPUT.PUT_LINE('Req Update');
         UPDATE PCMS_REQ_HOST
            SET prh_process_flag = req_flag,
                prh_resp_id = resp_id
          WHERE ROWID = v_rowid;
	  	  DBMS_OUTPUT.PUT_LINE('Rows Updated : '||SQL%rowcount);
      END IF;

      IF resp_flag IS NOT NULL
      THEN
	  	 DBMS_OUTPUT.PUT_LINE('Resp Update');
         UPDATE PCMS_RESP_HOST
            SET prh_process_flag = resp_flag,
				prh_process_id=proid
          WHERE ROWID = resp_rowid;
		 DBMS_OUTPUT.PUT_LINE('Rows Updated : '||SQL%rowcount);
      END IF;
   END;

   -- End Local Procedure

BEGIN                                                        -- Main Procedure
   errmsg := 'OK';

   SELECT SEQ_RESP_PRO_ID.NEXTVAL INTO proid FROM dual;

   FOR x IN c1
   LOOP
      v_next_record :='Y';
   	   DBMS_OUTPUT.PUT_LINE('Resp ID is :'||x.prh_resp_id);


	   DBMS_OUTPUT.PUT_LINE('Reference No. is : '||x.prh_ref_no);



  FOR y IN c2(x.prh_ref_no) --shyam
  LOOP



 /*      BEGIN
	   SELECT prh_req_id, prh_source_type, prh_appl_code, prh_tran_amt,
			      ROWID
           INTO v_req_id, v_source_type, v_appl_code, v_amt,
		                v_rowid
           FROM PCMS_REQ_HOST
          WHERE prh_ref_no = x.prh_ref_no;
	   DBMS_OUTPUT.PUT_LINE(v_req_id ||' : '|| v_source_type||' : '|| v_appl_code||' : '|| v_amt||' : '|| v_rowid);

      EXCEPTION
         WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN

		   lp_update_req_resp (NULL, NULL, 'E', x.ROWID, NULL);
		   v_next_record :='N';
		   	DBMS_OUTPUT.PUT_LINE('Req Id not Found or too many rows ');

      END;
*/

	v_req_id:= y.prh_req_id;
	v_source_type:= y.prh_source_type;
	v_appl_code:=y.prh_appl_code;
        v_amt := y.prh_tran_amt;
	v_rowid:=y.ROWID;

	v_next_record:='Y';

	  DBMS_OUTPUT.PUT_LINE('Stat Code : '||x.prh_stat_code);

	  IF v_next_record ='Y' THEN
	  	 	DBMS_OUTPUT.PUT_LINE( 'Match Found  ');
			DBMS_OUTPUT.PUT_LINE('Req ID is :'||v_req_id);
	        IF x.prh_stat_code = '02'THEN
	  	 	  DBMS_OUTPUT.PUT_LINE('Failed ');
			           lp_update_req_resp ('F', v_rowid, 'F', x.ROWID, x.prh_resp_id);
					            -- MOVE  RESP TO RESP ALL TABLE  AND COPY REQ TO REQ ALL
         --Lp_Move_Req_Resp ('C', v_rowid, 'M', x.ROWID);
      ELSIF x.prh_stat_code = '01'
      THEN
	  	  	DBMS_OUTPUT.PUT_LINE('Posted ');
         lp_update_req_resp ('Y', v_rowid, 'Y', x.ROWID, x.prh_resp_id);

         -- MOVE  RESP TO RESP ALL TABLE  AND MOVE  REQ TO REQ ALL

         --Lp_Move_Req_Resp ('M', v_rowid, 'M', x.ROWID);

         -- Update Account Balance

  	 	  DBMS_OUTPUT.PUT_LINE('v_amt :  '||v_amt);

			UPDATE CMS_ACCT_MAST
			SET cam_acct_bal = TO_NUMBER(v_amt)
			WHERE cam_acct_id = ( SELECT cad_Acct_id FROM CMS_APPL_DET
			WHERE cad_appl_code = v_appl_code);


         IF v_source_type = 'IM' OR v_source_type = 'IC'
         THEN
		 	 DBMS_OUTPUT.PUT_LINE('IM OR IC ');
            -- Change appl stat in Appl mast to 'A'
            UPDATE CMS_APPL_MAST
               SET cam_appl_stat = 'A'
             WHERE cam_inst_code = instcode AND cam_appl_code = v_appl_code;
         ELSIF v_source_type = 'IW'
         THEN
		 	 DBMS_OUTPUT.PUT_LINE('IW');
            SELECT cap_pan_code
              INTO v_pan
              FROM CMS_APPL_PAN
             WHERE cap_inst_code = instcode AND cap_appl_code = v_appl_code;

            UPDATE CMS_APPL_PAN
               SET cap_card_stat = '1',
                   cap_pbfgen_flag = 'N'
             WHERE cap_inst_code = instcode AND cap_pan_code = v_pan;

			 DELETE FROM CMS_CAF_INFO WHERE TRIM(CCI_PAN_CODE) =V_PAN; --DELETE FROM CAF INFO AS 1 RECORD WILL BE PRESENT ALREADY

            Sp_Caf_Rfrsh (instcode,
                          v_pan,
                          NULL,
                          SYSDATE,
                          'C',
                          NULL,
                          'ADDR',
                          lupduser,
                          errmsg
                         );

         ELSIF 	 v_source_type = 'TN' OR v_source_type = 'TC'
         THEN
		 	 DBMS_OUTPUT.PUT_LINE('TN OR TC');
            UPDATE CMS_APPL_PAN
               SET cap_pbfgen_flag = 'N'
             WHERE cap_inst_code = instcode AND cap_appl_code = v_appl_code;
         END IF;
      ELSE
         lp_update_req_resp ('U', v_rowid, 'U', x.ROWID, x.prh_resp_id);
         -- MOVE  RESP TO RESP ALL TABLE  AND COPY REQ TO REQ ALL
         --Lp_Move_Req_Resp ('C', v_rowid, 'M', x.ROWID);
      END IF;
	 END IF;

 END LOOP; -- shyam

   END LOOP;

   EXCEPTION
   WHEN OTHERS
   THEN
      errmsg := 'Main Exception -- ' || SQLERRM;
END;
/


