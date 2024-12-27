DECLARE
  l_msg varchar2(1000);
  l_exp exception;
 BEGIN
    FOR I IN (SELECT CPC_PROD_CODE,CPC_CARD_TYPE  FROM vmscms.CMS_PROD_CATTYPE)
    LOOP
      BEGIN
          UPDATE vmscms.CMS_PROD_CATTYPE 
          SET CPC_PRODUCT_ID=LPAD(vmscms.SEQ_PRODUCT_ID.NEXTVAL,5,'0')
          WHERE CPC_PROD_CODE=i.cpc_prod_code
          AND CPC_CARD_TYPE=i.cpc_card_type;
          
          if sql%rowcount=0 then
              L_MSG:='Error while updating cms_prod_cattype';
              raise l_exp;
          end if;
      EXCEPTION
          WHEN OTHERS THEN
              L_MSG:='Error while updating cms_prod_cattype'||substr(sqlerrm,1,200);
              raise l_exp;
      END;
    END LOOP;
    
    commit;
exception
    when l_exp then
         dbms_output.put_line(L_MSG);
        rollback;
    when others then
        dbms_output.put_line('Error in Main'||substr(sqlerrm,1,200));
        rollback;
end;
/