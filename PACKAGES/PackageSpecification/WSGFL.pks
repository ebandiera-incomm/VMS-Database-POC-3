CREATE OR REPLACE PACKAGE VMSCMS.wsgfl is

   function Black (Param in varchar2) return varchar2;
   function Blue (Param in varchar2) return varchar2;
   function Cyan (Param in varchar2) return varchar2;
   function Green (Param in varchar2) return varchar2;
   function Grey (Param in varchar2) return varchar2;
   function Magenta (Param in varchar2) return varchar2;
   function Red (Param in varchar2) return varchar2;
   function White (Param in varchar2) return varchar2;
   function Yellow (Param in varchar2) return varchar2;

   pragma restrict_references(Black, WNDS, WNPS);
   pragma restrict_references(Blue, WNDS, WNPS);
   pragma restrict_references(Cyan, WNDS, WNPS);
   pragma restrict_references(Green, WNDS, WNPS);
   pragma restrict_references(Grey, WNDS, WNPS);
   pragma restrict_references(Magenta, WNDS, WNPS);
   pragma restrict_references(Red, WNDS, WNPS);
   pragma restrict_references(White, WNDS, WNPS);
   pragma restrict_references(Yellow, WNDS, WNPS);

end;
/


CREATE OR REPLACE PACKAGE BODY VMSCMS.wsgfl is

---------------------
   function Black (Param in varchar2) return varchar2 is
   begin
        return '<font color="#000000">'||Param||'</font>';
   end;
---------------------
   function Blue (Param in varchar2) return varchar2 is
   begin
        return '<font color="#0000FF">'||Param||'</font>';
   end;
---------------------
   function Cyan (Param in varchar2) return varchar2 is
   begin
        return '<font color="#00FFFF">'||Param||'</font>';
   end;
---------------------
   function Green (Param in varchar2) return varchar2 is
   begin
        return '<font color="#00FF00">'||Param||'</font>';
   end;
---------------------
   function Grey (Param in varchar2) return varchar2 is
   begin
        return '<font color="#999999">'||Param||'</font>';
   end;
---------------------
   function Magenta (Param in varchar2) return varchar2 is
   begin
        return '<font color="#FF00FF">'||Param||'</font>';
   end;
---------------------
   function Red (Param in varchar2) return varchar2 is
   begin
        return '<font color="#FF0000">'||Param||'</font>';
   end;
---------------------
   function White (Param in varchar2) return varchar2 is
   begin
        return '<font color="#999999">'||Param||'</font>';
   end;
---------------------
   function Yellow (Param in varchar2) return varchar2 is
   begin
        return '<font color="#FFFF00">'||Param||'</font>';
   end;
---------------------
end;
/


