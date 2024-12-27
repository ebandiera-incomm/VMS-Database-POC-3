CREATE OR REPLACE PROCEDURE vmscms.sp_create_holder (
   instcode   IN       NUMBER,
   custcode   IN       NUMBER,
   acctid     IN       NUMBER,
   acctname   IN       VARCHAR2,
   lupduser   IN       NUMBER,
   holdposn   OUT      NUMBER,
   errmsg     OUT      VARCHAR2
)
AS
   v_cnt   NUMBER (1);
BEGIN
   errmsg := 'OK';

   BEGIN
      SELECT COUNT (1)
        INTO v_cnt
        FROM cms_cust_acct
       WHERE cca_inst_code = instcode
         AND cca_cust_code = custcode
         AND cca_acct_id = acctid;

      IF v_cnt > 0
      THEN
         errmsg := 'OK';

         BEGIN
            UPDATE cms_cust_acct
               SET cca_rel_stat = 'Y'
             WHERE cca_inst_code = instcode
               AND cca_cust_code = custcode
               AND cca_acct_id = acctid;
         EXCEPTION
            WHEN OTHERS
            THEN
               errmsg :=
                     'Error while getting customer acct relation '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

         RETURN;
      END IF;
   END;

   SELECT NVL (MAX (cca_hold_posn), 0) + 1
     INTO holdposn
     FROM cms_cust_acct
    WHERE cca_inst_code = instcode AND cca_acct_id = acctid;

   BEGIN
      INSERT INTO cms_cust_acct
                  (cca_inst_code, cca_cust_code, cca_acct_id, cca_acct_name,
                   cca_hold_posn, cca_rel_stat, cca_ins_user, cca_lupd_user
                  )
           VALUES (instcode, custcode, acctid, acctname,
                   holdposn, 'Y', lupduser, lupduser
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         errmsg :=
               'error while inserting data in cust acct '
            || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      errmsg := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
      RETURN;
END;
/

SHOW ERROR