CREATE OR REPLACE FUNCTION VMSCMS.FN_SPCLCHAR_CHEKDMG (
    p_string   IN   VARCHAR2
)
   RETURN VARCHAR2
IS
   v_cnt            NUMBER (38)     := 1;
   v_string         VARCHAR2 (1);
   v_string_final   VARCHAR2 (4000);
   v_length         NUMBER (38);
   v_num            NUMBER (38);
BEGIN                                                           
   SELECT LENGTH (p_string)
     INTO v_length
     FROM DUAL;

   IF v_length <> 0 OR v_length <> NULL
   THEN
      FOR i IN 1 .. v_length
      LOOP
         SELECT SUBSTR (p_string, v_cnt, 1)
           INTO v_string
           FROM DUAL;

         -- Statement Messages
         --A to Z a to z 0 to 9 !@#$%^&*()_-+=[]{}|\/~:;., and space

         --65-90 --A-Z
          --48-57 -- 0  9
           -- 33--!
          --  64--@
          --  35--#
          --  36--$
          --  37--%
          --  94--^
         --   38--&
          --  42--*
          --  40--(
         --   41--)
         --   95--_
         --   45---
         --   43-- +
         --   61--=
          --  91--[
          --  93--]
          --  123--{
          --  125--}
          --  124-- |
           -- 92--\
           -- 47--/
           -- 126--~
          --  58--:
          --  59--;
          --  46--.
           -- 44--,
             --32-- space
      /*   IF    ASCII (UPPER (v_string))  BETWEEN 65 AND 90
            OR ASCII (v_string) BETWEEN 40 AND 47 
            OR ASCII (v_string) BETWEEN 35 AND 38
            OR ASCII (v_string) BETWEEN 123 AND 126
            OR ASCII (v_string) BETWEEN 91 AND 95
            OR ASCII (v_string) IN (32, 33, 64, 61,58,59)
         THEN  */
         IF    ASCII (UPPER (v_string)) NOT  BETWEEN 48 AND 57
         THEN 
            v_string_final := ',,';
             RETURN v_string_final;
         
         END IF;

         v_cnt := v_cnt + 1;
      END LOOP;
   ELSE
   v_string_final := ',,';
      RETURN v_string_final;
   END IF;
 
return trim(p_string) ;

EXCEPTION
   WHEN OTHERS
   THEN
      RETURN SQLERRM;
END;
/
show error