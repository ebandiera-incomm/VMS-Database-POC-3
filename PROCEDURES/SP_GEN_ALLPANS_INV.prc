CREATE OR REPLACE PROCEDURE VMSCMS.sp_gen_allpans_inv (
   prm_instcode   IN       NUMBER,
   prm_filename   IN       VARCHAR2,
  -- prm_req_id	  IN 	   VARCHAR2,
   prm_lupduser   IN       NUMBER,
   prm_totcnt     OUT      NUMBER,
   prm_succnt     OUT      NUMBER,
   prm_errcnt     OUT      NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
AS
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 24/MAR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Generate Pan for Inventory

     * Modified By:    :
     * Modified Date  :
 ***********************************************/
   CURSOR c1
   IS
      SELECT   cam_appl_code
          FROM cms_appl_mast
         WHERE cam_appl_stat = 'I'
		 AND   cam_file_name = prm_filename
      ORDER BY cam_appl_code;

   v_panout     VARCHAR2 (20);
   v_cnt        NUMBER (10)    := 0;
   v_appl_msg   VARCHAR2 (500);
   v_totcnt     NUMBER (10)    DEFAULT 0;
   v_succnt     NUMBER (10)    DEFAULT 0;
   v_errcnt     NUMBER (10)    DEFAULT 0;
BEGIN
   prm_errmsg := 'OK';

--Sn get the total count
   BEGIN
      SELECT COUNT (1)
        INTO v_totcnt
        FROM cms_appl_mast
       WHERE cam_appl_stat = 'I'
	   AND	 cam_file_name = prm_filename;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg :=
               'NODATA FOUND FOR cam_appl_stat I from cms_appl_mast'
            || SUBSTR (SQLERRM, 1, 200);
         RETURN;
      WHEN OTHERS
      THEN
         prm_errmsg :=
                 'Error while selecting records ' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

--En get the total count
   FOR x IN c1
   LOOP
      IF prm_errmsg != 'OK'
      THEN
         DBMS_OUTPUT.put_line (   'Error message = '
                               || prm_errmsg
                               || 'for appl = '
                               || x.cam_appl_code
                               || ' and count = '
                               || v_cnt
                              );
         EXIT;
      END IF;

      sp_gen_pan_pcms_inv (prm_instcode,
                           x.cam_appl_code,
                           prm_lupduser,
                           v_panout,
                           v_appl_msg,
                           prm_errmsg
                          );

      IF prm_errmsg = 'OK' AND v_appl_msg = 'OK'
      THEN
        /* IF v_panout IS NOT NULL
         THEN
		 BEGIN
            UPDATE pcms_issuanceentry_update
               SET ciu_pan_code = v_panout
             WHERE ciu_appl_code = x.cam_appl_code;
			 IF SQL%ROWCOUNT = 0
               THEN
                  prm_errmsg := 'Error while updating issuanceentry_update ';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while updating record in issuanceentry_update'
                     || SUBSTR (SQLERRM, 1, 200);
            END;
         END IF;*/

         IF prm_filename IS NOT NULL
         THEN
            --Sn update cms_request_inventory for  pan
            BEGIN
               UPDATE cms_request_inventory
                  SET cri_batch_status = 'D'
                WHERE cri_ref_no = prm_filename
                  AND cri_inst_code = prm_instcode;

               IF SQL%ROWCOUNT = 0
               THEN
                  prm_errmsg := 'Error while updating request inventory ';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while updating record in request inventory '
                     || SUBSTR (SQLERRM, 1, 200);
            END;
         --En update acct_mast for pan
         END IF;

         v_succnt := v_succnt + 1;
         DBMS_OUTPUT.put_line ('success count ' || ' ' || v_succnt);
	  ELSE 
	  	   IF prm_filename IS NOT NULL
         THEN
            --Sn update cms_request_inventory for  pan
            BEGIN
               UPDATE cms_request_inventory
                  SET cri_batch_status = 'E'
                WHERE cri_ref_no = prm_filename
                  AND cri_inst_code = prm_instcode;

               IF SQL%ROWCOUNT = 0
               THEN
                  prm_errmsg := 'Error while updating request inventory ';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while updating record in request inventory '
                     || SUBSTR (SQLERRM, 1, 200);
            END;
         --En update acct_mast for pan
         END IF;
      END IF;

      v_cnt := v_cnt + 1;
      sp_pancount (v_cnt);
   END LOOP;

   IF prm_errmsg = 'OK'
   THEN
      v_errcnt := v_totcnt - v_succnt;
   ELSE
      v_succnt := 0;
      v_errcnt := 0;
   END IF;

   prm_totcnt := v_totcnt;
   prm_succnt := v_succnt;
   prm_errcnt := v_errcnt;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;
/
SHOW ERRORS

