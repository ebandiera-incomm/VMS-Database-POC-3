CREATE OR REPLACE PROCEDURE VMSCMS.SP_MANUAL_LOYL_UPDATION(ERRMSG OUT VARCHAR2)
AS
	CURSOR C1 IS
	SELECT CPC_CUST_CATG ,CPC_PROD_CODE,CPC_CARD_TYPE
	FROM  CMS_PROD_CCC
	WHERE
	--CPC_PROD_CODE = 'VD03'
	CPC_PROD_CODE = 'NA77'
	AND  CPC_CARD_TYPE = 1
	MINUS
	SELECT CPL_CUST_CATG,CPL_PROD_CODE,CPL_CARD_TYPE
	FROM CMS_PRODCCC_LOYL ;
	BEGIN  --Main Begin
			/*   sp_create_prodloyl	(instcode		IN	number  ,
						prodcode		IN	varchar2,
						loylcode		IN	number,
						validfrom		IN	date,
						validto			IN	date,
						lupduser		IN	number,
						errmsg			OUT	varchar2)*/
			PACK_CMS_LOYLATTACH.sp_create_prodloyl (1,'NA77', 1 ,TO_DATE('01-JAN-2003','DD-MON-YYYY'),TO_DATE('31-MAR-2099','DD-MON-YYYY'),
   					1, errmsg ) ;
				FOR Y IN C1
				LOOP
					/*
					PROCEDURE sp_create_prodcccloyl( instcode  IN number ,
					custcatg  IN number ,
					prodcode  IN varchar2 ,
					cardtype  IN number ,
					loylcode  IN number ,
					validfrom  IN date  ,
					validto  IN date  ,
					flowsource IN varchar2 ,
					lupduser  IN number ,
					errmsg  OUT  varchar2 );
					*/
					PACK_CMS_LOYLATTACH.SP_CREATE_PRODCCCLOYL (1,Y.CPC_CUST_CATG,Y.CPC_PROD_CODE,Y.CPC_CARD_TYPE,1,TO_DATE('01-JAN-2003','DD-MON-YYYY'),TO_DATE('31-MAR-2099','DD-MON-YYYY'),
					'EXP',1,errmsg ) ;
				END LOOP ;
				UPDATE CMS_PAN_TRANS
				SET CPT_LOYL_CALC='N'
				WHERE
				   --CPT_PROD_CODE = 'VD03' and
				      CPT_PROD_CODE = 'NA77' AND
				      CPT_CARD_TYPE = 1 AND
				      TRUNC(CPT_TRANS_DATE) > TRUNC(TO_DATE('30-JUN-2004','DD-MON-YYYY')) AND
				      CPT_LOYL_CALC = 'E'  ;
	EXCEPTION
	WHEN OTHERS THEN
	ERRMSG := 'ERROR : '||SQLERRM ;
	END ;
/
SHOW ERRORS

