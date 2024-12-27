CREATE OR REPLACE TYPE VMSCMS."SAMPLE_ARRAY_CALL"                                                                                                                                                                                                                             AS OBJECT EXTERNAL NAME 'SAMPLEARRAYCALL' LANGUAGE JAVA

USING SQLData (

receipt_no  varchar2(300) EXTERNAL NAME 'receipt_no',

customer_ref varchar2(50) EXTERNAL NAME 'customer_ref',

new_service_type varchar2(40) EXTERNAL NAME 'new_service_type',

old_service_type varchar2(40) EXTERNAL NAME 'old_service_type',

physical_payment_seq varchar2(56) EXTERNAL NAME 'physical_payment_seq'

)
/


