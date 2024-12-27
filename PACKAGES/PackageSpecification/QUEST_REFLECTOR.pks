CREATE OR REPLACE PACKAGE VMSCMS.quest_reflector IS

--
-- Purpose: PL/SQL package containing Java call specs to invoke
--          Reflection API routines
--

  FUNCTION EXAMINE        (class IN VARCHAR2)  RETURN NUMBER   AS LANGUAGE JAVA NAME 'com.quest.Reflector.examine(java.lang.String) return int';
  FUNCTION GET_METHOD_COUNT                    RETURN NUMBER   AS LANGUAGE JAVA NAME 'com.quest.Reflector.getMethodCount() return int';
  FUNCTION GET_METHOD_NAME(idx IN NUMBER)      RETURN VARCHAR2 AS LANGUAGE JAVA NAME 'com.quest.Reflector.getMethodName(int) return java.lang.String';
  FUNCTION GET_METHOD_CLASSNAME(idx IN NUMBER) RETURN VARCHAR2 AS LANGUAGE JAVA NAME 'com.quest.Reflector.getMethodClassName(int) return java.lang.String';
  FUNCTION GET_MODIFIERS  (idx IN NUMBER)      RETURN NUMBER   AS LANGUAGE JAVA NAME 'com.quest.Reflector.getModifiers(int) return int';
  FUNCTION GET_RETURN_TYPE(idx IN NUMBER)      RETURN VARCHAR2 AS LANGUAGE JAVA NAME 'com.quest.Reflector.getReturnType(int) return java.lang.String';
  FUNCTION GET_PARAMETERS (idx IN NUMBER)      RETURN NUMBER   AS LANGUAGE JAVA NAME 'com.quest.Reflector.getParameters(int) return int';
  FUNCTION GET_PARAM_COUNT                     RETURN NUMBER   AS LANGUAGE JAVA NAME 'com.quest.Reflector.getParamCount() return int';
  FUNCTION GET_PARAM_TYPE (idx IN NUMBER)      RETURN VARCHAR2 AS LANGUAGE JAVA NAME 'com.quest.Reflector.getParamType(int) return java.lang.String';
  FUNCTION EXAMINE_CLEANUP                     RETURN NUMBER   AS LANGUAGE JAVA NAME 'com.quest.Reflector.cleanup() return int';
  major_version NUMBER := 1.0;
END;
/


show error