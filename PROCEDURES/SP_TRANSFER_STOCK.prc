CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Transfer_Stock
(prm_inst_code NUMBER,
 prm_req_id    VARCHAR2,
 prm_ins_user  NUMBER,
 prm_err_msg  OUT VARCHAR2
)
IS
v_crd_cnt                       			 		CMS_BRANCH_TRANSFER.cbt_card_quantity%TYPE;
v_from_branch                   			 CMS_BRANCH_TRANSFER.cbt_from_branch%TYPE;
v_to_branch                     			 										  CMS_BRANCH_TRANSFER.cbt_to_branch%TYPE;
v_card_quantity                 CMS_BRANCH_TRANSFER.cbt_card_quantity%TYPE;
v_product_code                  CMS_BRANCH_TRANSFER.cbt_product_code%TYPE;
v_card_type                     CMS_BRANCH_TRANSFER.cbt_card_type%TYPE;
v_card_denomination             CMS_BRANCH_TRANSFER.cbt_card_denomination%TYPE;
v_frombranch_stock              CMS_BRANCH_STOCK.CBS_CARD_STOCK%TYPE;
v_tobranch_stock              CMS_BRANCH_STOCK.CBS_CARD_STOCK%TYPE;
BEGIN           --<<MAIN BEGIN>>
				 prm_err_msg := 'OK';
                --Sn select request detail from request id
                BEGIN
                        SELECT
                                cbt_card_quantity ,
                                cbt_from_branch ,
                                cbt_to_branch ,
                                cbt_product_code ,
                                cbt_card_type,
                                cbt_card_denomination
                        INTO
                                v_crd_cnt            ,
                                v_from_branch        ,
                                v_to_branch          ,
                                 v_product_code       ,
                                v_card_type			  ,
								v_card_denomination
                        FROM    CMS_BRANCH_TRANSFER
                        WHERE   CBT_REQUEST_ID = prm_req_id;
                EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                        prm_err_msg := 'Invalid request id ';
                        RETURN;
						WHEN OTHERS THEN
                        prm_err_msg := 'Error while selecting req id detail from branch transfer  for  ' ||  prm_req_id || SUBSTR(SQLERRM,1,200);
                        RETURN;
						
                END;
                --En select request detail from request id
                --Sn update from   branch
                        BEGIN
                                SELECT  CBS_CARD_STOCK
                                INTO    v_frombranch_stock
                                FROM    CMS_BRANCH_STOCK
                                WHERE   CBS_INST_CODE           =       prm_inst_code
                                AND     CBS_BRANCH_CODE         =       v_from_branch
                                AND     CBS_PRODUCT_CODE        =       v_product_code
                                AND     CBS_CARD_TYPE           =       v_card_type 
                                AND     CBS_CARD_DENOMINATION   =       v_card_denomination;
                                IF v_frombranch_stock >= v_crd_cnt THEN
                                        UPDATE  CMS_BRANCH_STOCK
                                        SET     CBS_CARD_STOCK = CBS_CARD_STOCK - v_crd_cnt
                                        WHERE   CBS_INST_CODE           =       prm_inst_code
                                        AND     CBS_BRANCH_CODE         =       v_from_branch
                                        AND     CBS_PRODUCT_CODE        =       v_product_code
                                        AND     CBS_CARD_TYPE           =       v_card_type 
                                        AND     CBS_CARD_DENOMINATION   =       v_card_denomination;
                                        IF SQL%ROWCOUNT = 0 THEN
                                        prm_err_msg := 'Error while updating stock in branch_stock for from branch ';
                                        RETURN;
                                        END IF;
								ELSE
										prm_err_msg := 'Requested no of stock not avilable in from branch  ' || v_from_branch;
										RETURN;
                                END IF;
                        EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                 prm_err_msg := 'From branch is not exist in master ';
                                RETURN;
								
								WHEN OTHERS THEN
                        		prm_err_msg := 'Error while selecting req id detail from branch stock  ' ||  SUBSTR(SQLERRM,1,200);
                        		RETURN;
                        		END;
                --En update   from branch
                 --Sn update to   branch
                        BEGIN
                                SELECT  CBS_CARD_STOCK
                                INTO    v_tobranch_stock
                                FROM    CMS_BRANCH_STOCK
                                WHERE   CBS_INST_CODE           =       prm_inst_code
                                AND     CBS_BRANCH_CODE         =       v_to_branch
                                AND     CBS_PRODUCT_CODE        =       v_product_code
                                AND     CBS_CARD_TYPE           =       v_card_type 
                                AND     CBS_CARD_DENOMINATION   =       v_card_denomination;
                                        UPDATE  CMS_BRANCH_STOCK
                                        SET     CBS_CARD_STOCK          =       CBS_CARD_STOCK + v_crd_cnt
                                        WHERE   CBS_INST_CODE           =       prm_inst_code
                                        AND     CBS_BRANCH_CODE         =       v_to_branch
                                        AND     CBS_PRODUCT_CODE        =       v_product_code
                                        AND     CBS_CARD_TYPE           =       v_card_type 
                                        AND     CBS_CARD_DENOMINATION   =       v_card_denomination;
                                        IF SQL%ROWCOUNT = 0 THEN
                                        prm_err_msg := 'Error while updating stock in Branch_stock for to branch ';
                                        RETURN;
                                        END IF;
                        EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                BEGIN
                                INSERT INTO CMS_BRANCH_STOCK
                                            (
                                            CBS_INST_CODE,
                                            CBS_BRANCH_CODE,
                                            CBS_PRODUCT_CODE,
                                            CBS_CARD_TYPE,
                                            CBS_CARD_DENOMINATION,
                                            CBS_CARD_STOCK,
                                            CBS_CARD_REORDER,
                                            CBS_CARD_MAX,
                                            CBS_INS_USER,
                                            CBS_INS_DATE,
                                            CBS_LUPD_USER,
                                            CBS_LUPD_DATE
                                            )
                                         VALUES
                                            (
                                                prm_inst_code,
                                                v_to_branch,
                                                v_product_code,
                                                v_card_type,
                                                v_card_denomination,
                                                v_crd_cnt,
                                                0,
                                                0,
                                                prm_ins_user,
                                                SYSDATE,
                                                prm_ins_user,
                                                SYSDATE
                                            );
                                 EXCEPTION
                                 WHEN OTHERS THEN
                                 prm_err_msg := 'Error while inserting records into  BRANCH_STOCK for to acct';
                                 RETURN;
                                 END;
						WHEN OTHERS THEN
						prm_err_msg := 'Error while selecting data from Branch stock ' || substr(sqlerrm,1,200);
                        END;
						
					
					BEGIN
					
					UPDATE CMS_APPL_PAN 
					SET CAP_APPL_BRAN =  v_to_branch 
					WHERE CAP_REQUEST_ID = prm_req_id 
					AND CAP_PROD_CODE = v_product_code 
					AND CAP_CARD_TYPE = v_card_type ;
					IF SQL%ROWCOUNT = 0 THEN
                                        prm_err_msg := 'Error while updating cms Appl pan for New Branch ';
                                        RETURN;
                                       END IF;
					EXCEPTION
								WHEN OTHERS THEN
                        		prm_err_msg := 'Error while updatinf Cms appl pan req id detail from branch stock  ' ||  SUBSTR(SQLERRM,1,200);
                        		RETURN;
                    END;
										
                --En update   to branch
EXCEPTION       --<<MAIN EXCEPTION >>
WHEN OTHERS THEN
prm_err_msg := 'Error from main proc ' || SUBSTR(SQLERRM,1 , 300);
END;            --<<MAIN END>>
/


SHOW ERRORS