CREATE OR REPLACE PROCEDURE VMSCMS.SP_CREATE_EDITIONING_VIEW (P_VIEW_NAME_IN  IN	 VARCHAR2,
															  P_TABLE_NAME_IN IN   VARCHAR2,
															  P_ERR_MSG_OUT    OUT  VARCHAR2
													   )
AS													   

	    l_sql          VARCHAR2(25000);
        l_column_list  VARCHAR2(25000);

    BEGIN
			
        l_sql := 'CREATE OR REPLACE EDITIONING VIEW '
                 || P_VIEW_NAME_IN
                 || ' AS SELECT ';

        SELECT rtrim(xmlagg(XMLELEMENT(e,column_name,',').EXTRACT('//text()')
                       ).GetClobVal(),',')  "Column_list"
        INTO l_column_list
        FROM ( SELECT 
		           column_name 
               FROM 
			       user_tab_columns
               WHERE 
			       table_name = P_TABLE_NAME_IN
               ORDER BY column_id);		

        l_sql := l_sql
                 || l_column_list
                 || ' FROM '
                 || p_table_name_in;

        EXECUTE IMMEDIATE l_sql;
                    
                 
        P_ERR_MSG_OUT := 'OK';
		
		DBMS_OUTPUT.PUT_LINE('VIEW '|| P_VIEW_NAME_IN || ' CREATED SUCESFULLY');
                   
    EXCEPTION
        WHEN OTHERS THEN
            P_ERR_MSG_OUT := 'ERROR WHILE CREATING EDITIONING VIEW '|| SUBSTR(SQLERRM,1,200);
    END;
 /
show error	