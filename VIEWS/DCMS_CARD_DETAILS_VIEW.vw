/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dcms_card_details_view (card_no,
                                                            bcif_id,
                                                            parameter1,
                                                            parameter2,
                                                            parameter3,
                                                            parameter4,
                                                            parameter5
                                                           )
AS
   SELECT "CARD_NO", "BCIF_ID", "PARAMETER1", "PARAMETER2", "PARAMETER3",
          "PARAMETER4", "PARAMETER5"
     FROM dcms_card_details_table;


