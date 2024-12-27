CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_InventoryReq	(
											instcode	IN	NUMBER	,
											branch	IN	VARCHAR2	,
                                 quantity IN NUMBER,
											ShortName	IN	VARCHAR2	,
                                 amount IN NUMBER ,
                                 status IN VARCHAR2,
                                 remarks IN VARCHAR2,
                                 insUser IN NUMBER,
                                 reqId  OUT VARCHAR2,
                                 batchNo OUT VARCHAR2,
  											errmsg		OUT	 VARCHAR2	 )

AS
invReq VARCHAR2(20);
batchId VARCHAR2(20);
BEGIN		--Main Begin Block Starts Here
errmsg:='OK';
   SELECT TO_CHAR(SYSDATE,'YYYYMMDD')||SEQ_INV_BATCHCODE.NEXTVAL INTO invReq FROM dual;
   SELECT TO_CHAR(SYSDATE,'YYYYMMDD')||SEQ_BATCH_NO.NEXTVAL INTO batchId FROM dual;

   reqId:=invReq;
   batchNo:=batchId;


	INSERT INTO	PCMS_INVENTORY_LOG (
            PIL_REQUEST_ID         ,
            PIL_BRANCH_CODE        ,
            PIL_QUANTITY_RECEIVE   ,
            PIL_CARDTYPE_SNAME     ,
            PIL_AMOUNT             ,
            PIL_STATUS             ,
            PIL_MESSAGE            ,
            PIL_BATCH_NO           ,
            PIL_INST_CODE          )
				VALUES(
               invReq		,
					branch		,
					quantity		,
					ShortName		,
					amount,
					status,
					remarks,
					batchId,
               instcode
               );
EXCEPTION	--Excp of Main Begin Block
	WHEN OTHERS THEN
	errmsg := 'Main Exception --- '||SQLERRM;
END;		--Main Begin Block Ends Here
/


show error