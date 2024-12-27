CREATE OR REPLACE AND RESOLVE JAVA SOURCE NAMED VMSCMS."GenShuffle" as import java.io.*;
import java.sql.*;
import oracle.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Collections;
import oracle.jdbc.driver.*;
public class GenShuffle {
public static void generateShuffledList(long startVal,long maxVal,oracle.sql.ARRAY[] vshuffleArray) throws
java.sql.SQLException, IOException {
long arraySize = maxVal - startVal;
Integer oShuffledList[] = new Integer[(int) arraySize+1];
 List<Integer> list = new ArrayList<Integer>();
 for(int i=(int)startVal;i<=maxVal;i++){
         list.add(i);
  }
  Collections.shuffle(list);
 list.toArray(oShuffledList);
 Connection conn = new OracleDriver().defaultConnection();
ArrayDescriptor desc = ArrayDescriptor.createDescriptor("SHUFFLE_ARRAY_TYP",conn);
vshuffleArray[0] = new ARRAY(desc,conn,oShuffledList);
}
}
/
show error