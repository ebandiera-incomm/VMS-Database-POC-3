create or replace and compile java source named "VMSCMS.McmsFileList"
 as
 import java.io.*;
 import java.sql.*;
 
 public class McmsFileList
 {
 public static void getList(String directory)throws SQLException
 {
     File path = new File( directory );
     String[] list = path.list();
     String element;
 
     for(int i = 0; i < list.length; i++)
     {
         element = list[i];
         #sql { INSERT INTO cms_mcmsret_filename (cmf_file_name)
                VALUES (:element) };
     }
 }
 
 }
 /