create or replace
PROCEDURE          VMSCMS.SP_HIGHRISKLOADWITH_24HRS_REP(FRMDT      IN VARCHAR2, --yyyymmdd
   todt         IN       VARCHAR2,                                  --yyyymmdd
   prm_errmsg   OUT      VARCHAR2
)
IS
--high risk indicators card load and cash withdrawal in 24 hrs
   ronm    NUMBER;
   rowno   NUMBER;

   CURSOR LOAD
   IS
      SELECT DISTINCT a.ROWID rwid, a.customer_card_no pancode,
                      a.business_date || a.business_time trndt
                 FROM transactionlog a
                WHERE a.instcode = 1
                  AND (   (    a.delivery_channel = '04'
                           AND a.txn_code IN
                                   (  '68', '69', '80', '82', '85', '88')
                          )
                       OR (    a.delivery_channel = '07'
                           AND a.txn_code IN ('07', '08')
                          )
                       OR (    a.delivery_channel = '08'
                           AND a.txn_code IN ('21', '22')
                          )
                       OR (    a.delivery_channel = '10'
                           AND a.txn_code IN ('07', '08')
                          )
                       OR (a.delivery_channel = '01' AND a.txn_code IN ('10')
                          )
                       OR (a.delivery_channel = '02' AND a.txn_code IN ('10')
                          )
                      )
                  -- AND TO_DATE (a.business_date || a.business_time,
                  AND TO_DATE (decode(fn_txndtchk(a.business_date, a.business_time),0,null,a.business_date || a.business_time),
                               'yyyymmddhh24miss'
                              ) BETWEEN TO_DATE (frmdt || '000000',
                                                 'yyyymmddhh24miss'
                                                )
                                    AND TO_DATE (todt || '235959',
                                                 'yyyymmddhh24miss'
                                                );

   CURSOR wthdrw (pancode VARCHAR2, trndt VARCHAR2)
   IS
      SELECT DISTINCT a.ROWID rwid, a.customer_card_no
                 FROM transactionlog a                                     
                WHERE a.instcode = 1
                  AND (a.delivery_channel = '04' AND a.txn_code IN ('10'))
                  --AND TO_DATE (a.business_date || a.business_time,
                  AND TO_DATE (decode(fn_txndtchk(a.business_date, a.business_time),0,null,a.business_date || a.business_time),
                               'yyyymmddhh24miss'
                              ) BETWEEN TO_DATE (frmdt || '000000',
                                                 'yyyymmddhh24miss'
                                                )
                                    AND TO_DATE (todt || '235959',
                                                 'yyyymmddhh24miss'
                                                )
                  AND a.customer_card_no = pancode
                  --AND TO_DATE (a.business_date || a.business_time,
                  AND TO_DATE (decode(fn_txndtchk(a.business_date, a.business_time),0,null,a.business_date || a.business_time),
                               'yyyymmddhh24miss'
                              ) BETWEEN TO_DATE (trndt, 'yyyymmddhh24miss')
                                    AND TO_DATE (trndt, 'yyyymmddhh24miss')
                                        + 1;

   CURSOR rep
   IS
SELECT DISTINCT  ROWNO,ROWDESC,x.cardno primary_card_number,
                      x.custname card_holder_name,
                      x.cam_phone_one phone_number, x.address address,
                      txndt txn_date, delivery_channel, txn_code,
                      TO_CHAR (amount,
                               '99,99,99,99,99,99,99,990.99'
                              ) load_amount,
                      x.cap_expry_date expiry_date,
                      TO_CHAR (ledger_balance, '$99,99,99,99,990.99') balance,
                      response_code response_code, terminal_id term_id,
                       MERCHANT_NAME term_owner, decode(merchant_state,null,merchant_city, 
                      decode(merchant_city,null,merchant_state,merchant_city||','||merchant_state)) term_city_state_country
                 FROM (SELECT fn_dmaps_main (cap_pan_code_encr) cardno,
                              cap_pan_code,
                              TO_CHAR (cap_expry_date, 'MMYY') cap_expry_date,
                --  ccm_first_name || ccm_first_name custname, --commented on 201212   for fss 859 
                CCM_FIRST_NAME || ' ' || CCM_LAST_NAME CUSTNAME, --added on 201212  for fss 859 
                                 cam_add_one
                              ||' '|| cam_add_two
                              ||' '||  cam_add_three
                              ||' '||  cam_pin_code
                              ||' '||  cam_city_name address,
                                 SUBSTR (cam_phone_one, 1, 3)
                              || '-'
                              || SUBSTR (cam_phone_one, 4, 3)
                              || '-'
                              || SUBSTR (cam_phone_one, 7, 4) cam_phone_one,
                              ROWNO,ROWDESC, delivery_channel, txn_code,
                              d.customer_card_no, terminal_id,MERCHANT_NAME,MERCHANT_CITY,MERCHANT_STATE, --Added by sriram 
                              DECODE (response_code,
                                      '00', 'Approved',
                                      'Declined'
                                     ) response_code,
                              ledger_balance, amount,
                              TO_CHAR (TO_DATE (   d.business_date
                                                || d.business_time,
                                                'yyyymmddhh24miss'
                                               ),
                                       'yyyymmddhh24miss'
                                      ) txndt
                         FROM cms_appl_pan a, cms_addr_mast b,
                              cms_cust_mast c,transactionlog d,cms_highriskloadwith_txn24hrs
                        WHERE a.cap_bill_addr = b.cam_addr_code
                          AND a.cap_cust_code = c.ccm_cust_code
                          and a.cap_pan_code=d.customer_card_no
                          and d.rowid=ROWIDENTIFIER) x
                                ORDER BY rowno, rowdesc;

 /*************************************************
     * Created Date     :  10-Dec-2011
     * Created By       :  Naveena
     * PURPOSE          :  VMS PHASEII REPORTS 
     * Modified By      : Naveena
     * Modified Date    :  20-12-2012 
     * Modified Reason  : JIRA FSS - 859 - Report: High Risk Indicators Card Load and Cash Withdrawal in 24 Hours 
      * Reviewer        :  Saravanakumar
     * Reviewed Date    : 20-12-2012 
     * Build Number     :CMS3.5.1_RI0023_B0003

 *************************************************/

BEGIN
   prm_errmsg := 'OK';

   truncate_tab_ebr ('CMS_HIGHRISK_TXN24HRS');
   truncate_tab_ebr ('CMS_HIGHRISKLOAD_TXN24HRS');
   truncate_tab_ebr ('CMS_HIGHRISKWITH_TXN24HRS');
   truncate_tab_ebr ('CMS_HIGHRISKLOADWITH_TXN24HRS');   
begin

   ronm := 1;

   FOR j IN LOAD
   LOOP
         INSERT INTO cms_highriskload_txn24hrs
              VALUES (ronm, j.rwid, 'Load');

      FOR k IN wthdrw (j.pancode, j.trndt)
      LOOP
         INSERT INTO cms_highriskwith_txn24hrs
              VALUES (ronm, k.rwid, 'Withdrawal');

         ronm := ronm + 1;
      END LOOP;
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'EXCP 1- ' || SQLERRM;
END;

begin
   INSERT INTO cms_highriskloadwith_txn24hrs
      SELECT   *
          FROM cms_highriskload_txn24hrs
      UNION
      SELECT   *
          FROM cms_highriskwith_txn24hrs
      ORDER BY 1, 3;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'EXCP - 2 ' || SQLERRM;
END;

begin
   rowno := 1;

   FOR l IN rep
   LOOP
      INSERT INTO cms_highrisk_txn24hrs
                  (chr_row_num, chr_row_desc, chr_primary_card_number,
                   chr_card_holder_name, chr_address, chr_phone_number,
                   chr_txn_date, chr_load_amount, chr_expiry_date,
                   chr_balance, chr_response_code, chr_term_id,
                   chr_term_owner, chr_term_city_state_country, chr_ins_date
                  )
           VALUES (rowno, l.rowdesc, l.primary_card_number,
                   l.card_holder_name, l.address, l.phone_number,
                   l.txn_date, l.load_amount, l.expiry_date,
                   l.balance, l.response_code, l.term_id,
                   l.term_owner, l.term_city_state_country, SYSDATE
                  );

      rowno := rowno + 1;
   END LOOP;
   EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'EXCP - 3' || SQLERRM;
END;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'MAIN EXCP - ' || SQLERRM;
END;
/
show error;