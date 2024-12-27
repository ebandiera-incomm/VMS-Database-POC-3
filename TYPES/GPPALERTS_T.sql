  CREATE OR REPLACE TYPE "VMSCMS"."GPPALERTS_LIST_T" AS TABLE OF gppalerts_t;


  CREATE OR REPLACE TYPE "VMSCMS"."GPPALERTS_T" AS OBJECT
(
    alert_id    VARCHAR2(20),
    alert_name  VARCHAR2(100),
    alert_desc  VARCHAR2(500),
    alert_value VARCHAR2(100), --Renamed column from Alter_value
    load_credit_alert_type  VARCHAR2(100)
);