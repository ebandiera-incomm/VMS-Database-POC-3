/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.cms_splunk_interface (txn_date,
                                                          txn_time,
                                                          delivery_channel,
                                                          txn_code,
                                                          rrn,
                                                          reversal_code,
                                                          card_no,
                                                          proxy_number,
                                                          response_code,
                                                          auth_id
                                                         )
AS
   SELECT business_date, business_time, delivery_channel, txn_code, rrn,
          reversal_code, customer_card_no, proxy_number, response_code,
          auth_id
     FROM transactionlog;


