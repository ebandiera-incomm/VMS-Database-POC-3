CREATE OR REPLACE PROCEDURE VMSCMS.sp_proxy_shuffler_F16
    (     PRM_PROD_CODE VARCHAR2 ,
          PRM_CARD_TYPE NUMBER ,
          PRM_MIN_PROXY  NUMBER ,
          PRM_MAX_PROXY NUMBER ,
          PRM_RANGE  NUMBER
      )

--Created by: - Dhiraj G/Sachin N
--Created on: - July 16, 2012.
--Purpose: - Shuffling of proxy code and PAN code alignment w.r.t. Sr. No. sequence.
--This is applicable for shuffling proxy numbers of only Starter card or similar products
--having proxy numbers as running sequence number of max length 9 digits.This is not applicable
--to shuffling for proxy numbers of DFC having 12 digit proxy numbers with unique construct.

IS
    CURSOR c_orig_rec
        (     v_frm_range NUMBER,
            v_to_range NUMBER
        )
       IS
        SELECT     ROWID row_id,
            cap_proxy_number
     FROM         cms_appl_pan
     WHERE     CAP_PROD_CODE =     PRM_PROD_CODE and
            CAP_CARD_TYPE =     PRM_CARD_TYPE and
            cap_pbfgen_flag = 'P' and
            cap_proxy_number >=     v_frm_range and
            cap_proxy_number <=    v_to_range ;

       TYPE c_orig_rec_tab IS TABLE OF c_orig_rec%ROWTYPE;

       cur_prox_no    c_orig_rec_tab;

       TYPE rec_hash IS RECORD
    (
          cap_proxy_number   CMS_APPL_PAN.cap_proxy_number%type ,
          flag               NUMBER (1)
       );

       TYPE type_hash IS TABLE OF rec_hash
          INDEX BY BINARY_INTEGER;

       v_record                 type_hash;
       v_min_proxy              NUMBER (20);
       v_max_proxy              NUMBER (20);
       ser_no                   NUMBER (20);
       v_cap_proxy_number       VARCHAR2(20);
       v_flag                   NUMBER (1);
       v_frm_range          NUMBER (20);
        v_to_range          NUMBER (20);
       v_exit_loop         NUMBER (1):= 0 ;

       loop_excp            EXCEPTION;

BEGIN

 /*      SELECT     TO_NUMBER (MIN (cap_proxy_number)),
                  TO_NUMBER (MAX (cap_proxy_number))
     INTO         v_min_proxy,
                  v_max_proxy
     FROM         cms_appl_pan
     WHERE     CAP_PROD_CODE    = PRM_PROD_CODE and
            CAP_CARD_TYPE     = PRM_CARD_TYPE AND
            cap_pbfgen_flag = 'P';
*/
     v_min_proxy := PRM_MIN_PROXY ;
     v_max_proxy := PRM_MAX_PROXY ;

     v_frm_range := v_min_proxy  ;
     v_to_range  := v_min_proxy + PRM_RANGE ;

LOOP

        IF v_to_range     >=  v_max_proxy then
            v_exit_loop    :=1 ;
             v_to_range     := v_max_proxy ;
        END IF ;

       OPEN c_orig_rec ( v_frm_range ,v_to_range ) ;

   LOOP
      FETCH c_orig_rec
      BULK COLLECT INTO cur_prox_no;

      EXIT WHEN cur_prox_no.COUNT () = 0;

      BEGIN
         v_record.DELETE;

         FOR z IN 1 .. cur_prox_no.COUNT ()
         LOOP
            BEGIN
               v_record (TO_NUMBER (cur_prox_no (z).cap_proxy_number)).cap_proxy_number :=
                                             cur_prox_no (z).cap_proxy_number;
               v_record (TO_NUMBER (cur_prox_no (z).cap_proxy_number)).flag := 0;
            EXCEPTION
               WHEN OTHERS        THEN
                       DBMS_OUTPUT.put_line (SUBSTR (SQLERRM, 1, 200));
                      RETURN;
            END;
         END LOOP;

         FOR z IN 1 .. cur_prox_no.COUNT ()
         LOOP
            BEGIN
               LOOP
                  SELECT     ROUND (DBMS_RANDOM.VALUE (v_frm_range, v_to_range))
                  INTO     ser_no
                  FROM     DUAL;

                  BEGIN
                      v_flag := v_record (ser_no).flag;
                         EXIT ;
                  EXCEPTION
                     WHEN     NO_DATA_FOUND THEN
                             NULL ;
                     WHEN     OTHERS THEN
                           DBMS_OUTPUT.put_line (SUBSTR (SQLERRM, 1, 200));
                  END;
               END LOOP;

               IF     v_flag = 0 THEN
                      v_cap_proxy_number := v_record (ser_no).cap_proxy_number;

                      UPDATE     cms_appl_pan
                         SET         cap_proxy_number = v_cap_proxy_number,
                                 cap_pbfgen_flag = 'S'
                       WHERE     ROWID = cur_prox_no (z).row_id;

                      v_record (ser_no).flag := 1;
               ELSE
                    FOR i IN REVERSE v_min_proxy .. ser_no
                      LOOP
                             BEGIN
                                 ser_no := i;
                                 v_flag := v_record (i).flag;
                             EXCEPTION
                                 WHEN     NO_DATA_FOUND THEN
                                   NULL ;
                             END ;
                             IF     v_flag = 0 THEN
                                v_cap_proxy_number := v_record (i).cap_proxy_number;
                                EXIT;
                             END IF;
                      END LOOP;

                      IF     v_flag = 1 THEN
                             FOR i IN REVERSE ser_no .. v_max_proxy
                             LOOP
                                BEGIN
                                    ser_no := i;
                                    v_flag := v_record (i).flag;
                                EXCEPTION
                                    WHEN NO_DATA_FOUND THEN
                                         NULL ;
                                END ;
                                IF     v_flag = 0 THEN
                                   v_cap_proxy_number := v_record (i).cap_proxy_number;
                                   EXIT;
                                END IF;
                             END LOOP;
                      END IF;

                      UPDATE     cms_appl_pan
                         SET         cap_proxy_number = v_cap_proxy_number,
                                 cap_pbfgen_flag = 'S'
                       WHERE     ROWID = cur_prox_no (z).row_id;

                      v_record (ser_no).flag := 1;
               END IF;
            EXCEPTION
               WHEN     NO_DATA_FOUND THEN
                        NULL ;
               WHEN     loop_excp THEN
                        NULL;
               WHEN     OTHERS THEN
                      DBMS_OUTPUT.put_line (SUBSTR (SQLERRM, 1, 100));
                      ROLLBACK ;
                      RETURN;
            END;
         END LOOP;
      END;
   END LOOP;
   CLOSE c_orig_rec;
--   COMMIT ;

   EXIT WHEN V_EXIT_LOOP = 1  ;

   v_frm_range:= v_to_range+1;
   v_to_range:= v_to_range+ PRM_RANGE ;

END LOOP ;

EXCEPTION
   WHEN     OTHERS THEN
          DBMS_OUTPUT.put_line (SUBSTR (SQLERRM, 1, 100));
             ROLLBACK ;
END;
/

SHOW ERRORS;


