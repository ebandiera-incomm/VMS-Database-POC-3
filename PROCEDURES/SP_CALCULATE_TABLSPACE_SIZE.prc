CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Calculate_Tablspace_Size
(prm_instcode NUMBER,
 prm_percent_growth  NUMBER,
 prm_errmsg OUT VARCHAR2)
 AS
 CURSOR c IS   SELECT
      DISTINCT  PTT_TABLESPACE_NAME
        FROM     PREPAID_TABLE_TABLESPACE;
 CURSOR c1(v_tablespace_name VARCHAR2)
        IS
        SELECT  PTD_TABLE_NAME,PTD_REC_TOTSPACE_BYTE, PTD_NOOF_REC_1STYR
        FROM    PREPAID_TABLE_DTL,PREPAID_TABLE_TABLESPACE
        WHERE   PTD_TABLE_NAME = PTT_TABLE_NAME
        AND     PTT_TABLESPACE_NAME = v_tablespace_name;
V_SIZE_1STYR   NUMBER DEFAULT 0;
V_SIZE_2NDYR   NUMBER DEFAULT 0;
V_SIZE_3RDYR   NUMBER DEFAULT 0;
BEGIN
        --Sn loop for each tablespace
prm_errmsg  := 'OK';
DELETE FROM PREPAID_TABLESPACE_DTL;
        FOR I IN C LOOP
            BEGIN
                V_SIZE_1STYR := 0;
				V_SIZE_2NDYR := 0;
				V_SIZE_3RDYR := 0;
            --Sn loop for each table from table_dtl for each tablespace from C
                FOR I1 IN C1(I.PTT_TABLESPACE_NAME) LOOP
                BEGIN
                        --Sn calculate total space for 1st year
                       V_SIZE_1STYR := NVL(V_SIZE_1STYR ,0)+ NVL((I1.PTD_REC_TOTSPACE_BYTE * I1.PTD_NOOF_REC_1STYR),0);
                        --En calculate total space for 1st year
                END;
               END LOOP;
                V_SIZE_2NDYR := NVL(V_SIZE_1STYR,0) * (1+(prm_percent_growth/100));
                V_SIZE_3RDYR :=  NVL(V_SIZE_2NDYR,0) *(1+(prm_percent_growth/100));
                INSERT INTO PREPAID_TABLESPACE_DTL
                VALUES
                (I.PTT_TABLESPACE_NAME,
                        V_SIZE_1STYR/1073741824,
                        V_SIZE_2NDYR/1073741824,
                        V_SIZE_3RDYR/1073741824 );
           --en loop for each table from table_dtl for each tablespace from C
            END ;
            END LOOP;
        --En loop for each tablespace
EXCEPTION
        WHEN OTHERS THEN
        PRM_ERRMSG := SUBSTR(SQLERRM,1, 300);
END;
/


