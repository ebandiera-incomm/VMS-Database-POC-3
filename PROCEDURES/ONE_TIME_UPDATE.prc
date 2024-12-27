CREATE OR REPLACE PROCEDURE VMSCMS.ONE_TIME_UPDATE (ERRMSG OUT VARCHAR2) AS
CURSOR c1 IS SELECT cap_acct_no,cap_next_bill_date
      FROM CMS_APPL_PAN_TEST10
      WHERE flag= 'N'
      AND ROWNUM < 10000;
BEGIN
FOR x IN c1
    LOOP
 BEGIN
    UPDATE  CMS_APPL_PAN
    SET  cap_next_bill_date = x.cap_next_bill_date
    WHERE  cap_pan_code =(SELECT cap_pan_code
           FROM CMS_APPL_PAN
           WHERE cap_inst_code = 1
               AND cap_acct_no = x.cap_acct_no
                      AND cap_ins_date =(SELECT MIN(cap_ins_date)
         FROM CMS_APPL_PAN
                WHERE cap_inst_code = 1
                AND cap_acct_no = x.cap_acct_no)
           AND cap_prod_catg = 'D' )
    AND  cap_mbr_numb = '000';
   IF SQL%rowcount=0 THEN
   UPDATE  CMS_APPL_PAN_TEST10
   SET  flag = 'E'
   WHERE  cap_acct_no = x.cap_acct_no
   AND  cap_next_bill_date = x.cap_next_bill_date
   AND  flag = 'N';
  ELSE
   UPDATE  CMS_APPL_PAN_TEST10
   SET  flag = 'Y'
   WHERE  cap_acct_no = x.cap_acct_no
   AND  cap_next_bill_date = x.cap_next_bill_date
   AND  flag = 'N';
   END IF;
 EXCEPTION
  WHEN OTHERS THEN
   UPDATE CMS_APPL_PAN_TEST10
   SET  flag = 'E'
   WHERE  cap_acct_no = x.cap_acct_no
   AND  cap_next_bill_date =  x.cap_next_bill_date
   AND  flag = 'N';
 END;
    END LOOP;
END;
/


