CREATE OR REPLACE PROCEDURE VMSCMS.sp_populate_cafgen_data_140510
AS
PRAGMA autonomous_transaction;
BEGIN

 INSERT INTO CMS_CAFGEN_DATA_TEMP (
  SELECT *
  FROM CMS_CAF_INFO
  WHERE cci_file_gen = 'N');

COMMIT;

END;
/


