create or replace
PROCEDURE vmscms.GET_SHUFFLE_SERIALS (
   p_minval_in              NUMBER,
   p_maxval_in              NUMBER,
   p_shufflearray_out   OUT shuffle_array_typ)
AS
   LANGUAGE JAVA
   NAME 'GenShuffle.generateShuffledList(long,long,oracle.sql.ARRAY[])';
   
   
   
/
show error;   