CREATE OR REPLACE PACKAGE VMSCMS.WSGOC is
--
-- Web PL/SQL Generator Object Cache
--

  -- make sure we don't keep this around after a call
  pragma SERIALLY_REUSABLE;

  MISSING_MANDATORY_ATTRIBUTE exception;
  INVALID_OBJECT_HANDLE       exception;

  -- Dump output stream
  type OUTPUT_BUF is record (terminate boolean, buff varchar2(255));
  type OUTPUT_STREAM is table of OUTPUT_BUF index by binary_integer;

  -- New context heading stuff
  -- REF types
  type BRANCH_REF is record (id binary_integer);
  type MODULE_REF is record (id binary_integer);
  type COMPONENT_REF is record (id binary_integer);
  type ITEM_REF is record (id binary_integer);

  -- List Types
  type BRANCH_REF_LIST is table of BRANCH_REF index by binary_integer;
  type MODULE_REF_LIST is table of MODULE_REF index by binary_integer;
  type COMPONENT_REF_LIST is table of COMPONENT_REF index by binary_integer;
  type ITEM_REF_LIST is table of ITEM_REF index by binary_integer;

  -- dump output stream
  o OUTPUT_STREAM;

  -- null refs
  null_branch    BRANCH_REF;
  null_module    MODULE_REF;
  null_component COMPONENT_REF;
  null_item      ITEM_REF;

  -- types operators
  function IS_NULL(pObj in BRANCH_REF) return boolean;
  function IS_SAME(pLft in BRANCH_REF, pRht in BRANCH_REF) return boolean;
  function IS_NULL(pObj in MODULE_REF) return boolean;
  function IS_SAME(pLft in MODULE_REF, pRht in MODULE_REF) return boolean;
  function IS_NULL(pObj in COMPONENT_REF) return boolean;
  function IS_SAME(pLft in COMPONENT_REF, pRht in COMPONENT_REF) return boolean;
  function IS_NULL(pObj in ITEM_REF) return boolean;
  function IS_SAME(pLft in ITEM_REF, pRht in ITEM_REF) return boolean;

  -- Constructors
  function BRANCH
  ( pName          in  varchar2 default 'MAIN'
  ) return BRANCH_REF;

  function MODULE
  ( pShortName             in varchar2
  , pBranch                in BRANCH_REF     default null
  , pFirstTitle            in varchar2       default null
  , pFormattedFirstTitle   in varchar2       default null
  , pCustom                in varchar2       default null
  ) return MODULE_REF;

  function COMPONENT
  ( pBranch                in BRANCH_REF     default null
  , pModule                in MODULE_REF     default null
  , pContext_For           in COMPONENT_REF  default null
  , pName                  in varchar2       default null
  , pTitle                 in varchar2       default null
  , pFormattedTitle        in varchar2       default null
  , pBeforeText            in varchar2       default null
  , pAfterText             in varchar2       default null
  , pSystemImagePath       in varchar2       default null
  , pCustom                in varchar2       default null
  ) return COMPONENT_REF;

  function ITEM
  ( pName                  in varchar2       default null
  , pPrompt                in varchar2       default null
  , pIsContext             in boolean        default false
  , pCustom                in varchar2       default null
  ) return ITEM_REF;

  -- "Get" methods
  -- BRANCH
  function GET_Name ( pRef in BRANCH_REF ) return varchar2;
  function GET_Top_Component ( pRef in BRANCH_REF ) return COMPONENT_REF;

  -- MODULE
  function GET_ShortName (pRef in MODULE_REF ) return varchar2;
  function GET_Branch (pRef in MODULE_REF ) return BRANCH_REF;
  function GET_FirstTitle (pRef in MODULE_REF ) return varchar2;
  function GET_FormattedFirstTitle (pRef in MODULE_REF ) return varchar2;
  function GET_Custom (pRef in MODULE_REF ) return varchar2;

  -- COMPONENT
  function GET_Branch (pRef in COMPONENT_REF ) return BRANCH_REF;
  function GET_Module (pRef in COMPONENT_REF ) return MODULE_REF;
  function GET_Context_For (pRef in COMPONENT_REF ) return COMPONENT_REF;
  function GET_Depth (pRef in COMPONENT_REF ) return binary_integer;
  function GET_Items (pRef in COMPONENT_REF ) return ITEM_REF_LIST;
  function GET_Name (pRef in COMPONENT_REF ) return varchar2;
  function GET_Title (pRef in COMPONENT_REF ) return varchar2;
  function GET_FormattedTitle (pRef in COMPONENT_REF ) return varchar2;
  function GET_BeforeText (pRef in COMPONENT_REF ) return varchar2;
  function GET_AfterText (pRef in COMPONENT_REF ) return varchar2;
  function GET_SystemImagePath (pRef in COMPONENT_REF ) return varchar2;
  function GET_Custom (pRef in COMPONENT_REF ) return varchar2;

  -- ITEM
  function GET_Name (pRef in ITEM_REF ) return varchar2;
  function GET_Prompt (pRef in ITEM_REF ) return varchar2;
  function GET_Value (pRef in ITEM_REF ) return varchar2;
  function GET_IsContext (pRef in ITEM_REF ) return boolean;
  function GET_Custom (pRef in ITEM_REF ) return varchar2;

  -- "Set" methods
  --
  -- COMPONENT
  procedure SET_BeforeText (pRef in COMPONENT_REF, pVal in varchar2 );
  procedure SET_AfterText (pRef in COMPONENT_REF, pVal in varchar2 );

  -- ITEM
  procedure SET_Value (pRef in ITEM_REF, pVal in varchar2 );

  -- "Add" methods
  -- COMPONENT
  procedure ADD_ITEMS
  ( pRef          in COMPONENT_REF
  , pAddMeRef     in ITEM_REF
  );

  -- "Query" methods
  -- BRANCH
  function GET_BRANCHS
    return BRANCH_REF_LIST;

  -- MODULE
  function GET_MODULES
    return MODULE_REF_LIST;

  -- COMPONENT
  function GET_COMPONENTS
    return COMPONENT_REF_LIST;

  function GET_COMPONENTS
  ( pBranch        in  BRANCH_REF
  ) return COMPONENT_REF_LIST;

  function GET_COMPONENTS
  ( pModule        in  MODULE_REF
  ) return COMPONENT_REF_LIST;

  function GET_COMPONENTS
  ( pDepth         in  binary_integer
  ) return COMPONENT_REF_LIST;

  -- "dump" methods
  procedure DUMP_BRANCH
  ( pRef          in  BRANCH_REF
  );

  procedure DUMP_MODULE
  ( pRef          in  MODULE_REF
  );

  procedure DUMP_COMPONENT
  ( pRef          in  COMPONENT_REF
  );

  procedure DUMP_ITEM
  ( pRef          in  ITEM_REF
  );

end;
/


CREATE OR REPLACE PACKAGE BODY VMSCMS.WSGOC is
--
-- Web PL/SQL Generator Object Cache
--

  -- make sure we don't keep this around after a call
  pragma SERIALLY_REUSABLE;

  -- storage types
  -- attribute records
  type BRANCH_T is record
  ( Name          varchar2(30)
  , Top_Component binary_integer
  );

  type MODULE_T is record
  ( Branch              binary_integer
  , ShortName           varchar2(30)
  , FirstTitle          varchar2(70)
  , FormattedFirstTitle varchar2(1000)
  , Custom              varchar2(2000)
  );

  type COMPONENT_T is record
  ( Branch           binary_integer
  , Module           binary_integer
  , Context_For      binary_integer
  , Depth            binary_integer
  , Items            varchar2(255)
  , Name             varchar2(30)
  , Title            varchar2(70)
  , FormattedTitle   varchar2(1000)
  , BeforeText       varchar2(10000)
  , AfterText        varchar2(10000)
  , SystemImagePath  varchar2(1000)
  , Custom           varchar2(2000)
  );

  type ITEM_T is record
  ( Name          varchar2(30)
  , Prompt        varchar2(1000)
  , Value         varchar2(32767)
  , IsContext     boolean
  , Custom        varchar2(2000)
  );

  -- collections
  type BRANCH_T_LIST is table of BRANCH_T index by binary_integer;
  type MODULE_T_LIST is table of MODULE_T index by binary_integer;
  type COMPONENT_T_LIST is table of COMPONENT_T index by binary_integer;
  type ITEM_T_LIST is table of ITEM_T index by binary_integer;

  -- storage variables
  BRANCHS      BRANCH_T_LIST;
  MODULES      MODULE_T_LIST;
  COMPONENTS   COMPONENT_T_LIST;
  ITEMS        ITEM_T_LIST;

----------------------
--
--    Dump stream formatter
--    Always adds a new line characters at the end
--
---------------------
procedure dump(pChar in varchar2)
is
   recs integer := ceil(lengthb(pChar)/255);
begin
   for i in 1..recs loop
      if o.last is null then
         o(1).buff := substrb(pChar,(i-1)*255 +1, 255 );
      else
         o(o.last + 1).buff := substrb(pChar,(i-1)*255 +1, 255 );
      end if;
      o(o.last).terminate := FALSE;
   end loop;
   if o.last is null then
      o(1).terminate := TRUE;
   else
      o(o.last).terminate := TRUE;
   end if;
end;

----------------------
--
--    Operators for type REFS
--
---------------------

-- types operators
function IS_NULL(pObj in BRANCH_REF) return boolean is
begin if pObj.id is null then return TRUE; end if; return FALSE;
end;

function IS_SAME(pLft in BRANCH_REF, pRht in BRANCH_REF) return boolean is
begin if pLft.id = pRht.id then return TRUE;
      elsif pLft.id is null and pRht.id is null then return true;
      end if;
      return false;
end;

function IS_NULL(pObj in MODULE_REF) return boolean is
begin if pObj.id is null then return TRUE; end if; return FALSE;
end;

function IS_SAME(pLft in MODULE_REF, pRht in MODULE_REF) return boolean is
begin if pLft.id = pRht.id then return TRUE;
      elsif pLft.id is null and pRht.id is null then return true;
      end if;
      return false;
end;

function IS_NULL(pObj in COMPONENT_REF) return boolean is
begin if pObj.id is null then return TRUE; end if; return FALSE;
end;

function IS_SAME(pLft in COMPONENT_REF, pRht in COMPONENT_REF) return boolean is
begin if pLft.id = pRht.id then return TRUE;
      elsif pLft.id is null and pRht.id is null then return true;
      end if;
      return false;
end;

function IS_NULL(pObj in ITEM_REF) return boolean is
begin if pObj.id is null then return TRUE; end if; return FALSE;
end;

function IS_SAME(pLft in ITEM_REF, pRht in ITEM_REF) return boolean is
begin if pLft.id = pRht.id then return TRUE;
      elsif pLft.id is null and pRht.id is null then return true;
      end if;
      return false;
end;



----------------------
--
--    Constructor methods
--
--
-- NOTES
--   attributes in param list defined by COMPLETE_FLAG = 'Y' on column
---------------------

--
--    BRANCH
--
function BRANCH
( pName           in  varchar2
) return BRANCH_REF
is
   l_return       BRANCH_REF;
   oid            binary_integer := BRANCHS.count + 1;
   this           BRANCH_T;
begin
   this.name := pName;

   -- check for mandatory attributes
   if ( this.name is null ) then
      raise MISSING_MANDATORY_ATTRIBUTE;
   end if;

   BRANCHS(oid) := this;
   l_return.id := oid;
   return l_return;
end;

--
--    MODULE
--
function MODULE
( pShortName            in varchar2
, pBranch               in BRANCH_REF
, pFirstTitle           in varchar2
, pFormattedFirstTitle  in varchar2
, pCustom               in varchar2
) return MODULE_REF
is
   l_return       MODULE_REF;
   oid            binary_integer := MODULES.count + 1;
   this           MODULE_T;
begin
   this.ShortName := pShortName;
   this.Branch := pBranch.id;
   this.FirstTitle := pFirstTitle;
   this.FormattedFirstTitle  := pFormattedFirstTitle ;
   this.Custom := pCustom;

   -- user code
   -- check for a branch
   if ( this.Branch is null ) then
      if ( BRANCHS.count > 0 ) then
         this.Branch := BRANCHS.last;
      else
         this.Branch := BRANCH().id;
      end if;
   end if;

   -- check for mandatory attributes
   if (   this.shortname is null
       or this.branch is null )
   then
      raise MISSING_MANDATORY_ATTRIBUTE;
   end if;

   MODULES(oid) := this;
   l_return.id := oid;
   return l_return;
end;

--
--    COMPONENT
--
function COMPONENT
( pBranch            in BRANCH_REF
, pModule            in MODULE_REF
, pContext_For       in COMPONENT_REF
, pName              in varchar2
, pTitle             in varchar2
, pFormattedTitle    in varchar2
, pBeforeText        in varchar2
, pAfterText         in varchar2
, pSystemImagePath   in varchar2
, pCustom            in varchar2
) return COMPONENT_REF
is
   l_return       COMPONENT_REF;
   oid            binary_integer := COMPONENTS.count + 1;
   this           COMPONENT_T;
begin
   this.Branch := pBranch.id;
   this.Module := pModule.id;
   this.Context_For := pContext_For.id;
   this.Name := pName;
   this.Title := pTitle;
   this.FormattedTitle := pFormattedTitle;
   this.BeforeText := pBeforeText;
   this.AfterText := pAfterText;
   this.SystemImagePath := pSystemImagePath;
   this.Custom := pCustom;

   -- Check for branch
   if ( this.Branch is null ) then
      if ( BRANCHS.count > 0 ) then
         this.Branch := BRANCHS.last;
      else
         this.Branch := BRANCH().id;
      end if;
   end if;

   -- Set Depth
   if ( this.Context_For is not null ) then
      this.Depth := COMPONENTS(this.Context_For).Depth + 1;
   else
      this.Depth := 0;
   end if;

   -- keep track of top component on this branch
   BRANCHS(this.branch).Top_Component := oid;

   -- check for mandatory attributes
   if (   this.Branch is null
       or this.Depth is null )
   then
      raise MISSING_MANDATORY_ATTRIBUTE;
   end if;

   COMPONENTS(oid) := this;
   l_return.id := oid;
   return l_return;
end;

--
--    ITEM
--
function ITEM
( pName           in varchar2
, pPrompt         in varchar2
, pIsContext      in boolean
, pCustom         in varchar2
) return ITEM_REF
is
   l_return       ITEM_REF;
   oid            binary_integer := ITEMS.count + 1;
   this           ITEM_T;
begin
   this.Name := pName;
   this.Prompt := pPrompt;
   this.IsContext := pIsContext;
   this.Value := null;
   this.Custom := pCustom;

   -- check for mandatory attributes

   -- store attributes
   ITEMS(oid) := this;
   l_return.id := oid;
   return l_return;
end;

----------------------
--
--    "Get" methods
--
----------------------

----------------------
--    "Get" methods on BRANCH
----------------------

--
--    GET_Name
--
function GET_Name ( pRef in BRANCH_REF )
return varchar2
is
begin
   return BRANCHS(pRef.id).Name;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_Top_Component
--
function GET_Top_Component ( pRef in BRANCH_REF )
return COMPONENT_REF
is
   l_return COMPONENT_REF;
begin
   l_return.id := BRANCHS(pRef.id).Top_Component;
   return l_return;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

----------------------
--    "Get" methods on MODULE
----------------------

--
--    GET_ShortName
--
function GET_ShortName ( pRef in MODULE_REF )
return varchar2
is
begin
   return MODULES(pRef.id).ShortName;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_Branch
--
function GET_Branch ( pRef in MODULE_REF )
return BRANCH_REF
is
   l_return BRANCH_REF;
begin
   l_return.id := MODULES(pRef.id).Branch;
   return l_return;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_FirstTitle
--
function GET_FirstTitle ( pRef in MODULE_REF )
return varchar2
is
begin
   return MODULES(pRef.id).FirstTitle;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_FormattedFirstTitle
--
function GET_FormattedFirstTitle ( pRef in MODULE_REF )
return varchar2
is
begin
   return MODULES(pRef.id).FormattedFirstTitle;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_Custom
--
function GET_Custom ( pRef in MODULE_REF )
return varchar2
is
begin
   return MODULES(pRef.id).Custom;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

----------------------
--    "Get" methods on COMPONENT
----------------------

--
--    GET_Branch
--
function GET_Branch ( pRef in COMPONENT_REF )
return BRANCH_REF
is
   l_return BRANCH_REF;
begin
   l_return.id := COMPONENTS(pRef.id).Branch;
   return l_return;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_Module
--
function GET_Module ( pRef in COMPONENT_REF )
return MODULE_REF
is
   l_return MODULE_REF;
begin
   l_return.id := COMPONENTS(pRef.id).Module;
   return l_return;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_Context_For
--
function GET_Context_For ( pRef in COMPONENT_REF )
return COMPONENT_REF
is
   l_return COMPONENT_REF;
begin
   l_return.id := COMPONENTS(pRef.id).Context_For;
   return l_return;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_Depth
--
function GET_Depth ( pRef in COMPONENT_REF )
return binary_integer
is
begin
   return COMPONENTS(pRef.id).Depth;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_Items
--
function GET_Items (pRef in COMPONENT_REF )
return ITEM_REF_LIST
is
   l_list   ITEM_REF_LIST;
   l_ref    ITEM_REF;
   l_refs   varchar2(255);
   l_sep    number;
   l_index  binary_integer := 1;
begin
   l_refs := COMPONENTS(pRef.id).items;
   while l_refs is not null loop
      l_sep := instr(l_refs, ',');
      l_ref.id := to_number(substr(l_refs,1,l_sep-1));
      l_refs := substr(l_refs,l_sep+1);
      l_list(l_index) := l_ref;
      l_index := l_index + 1;
   end loop;
   return l_list;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;


--
--    GET_Name
--
function GET_Name ( pRef in COMPONENT_REF )
return varchar2
is
begin
   return COMPONENTS(pRef.id).Name;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_Title
--
function GET_Title ( pRef in COMPONENT_REF )
return varchar2
is
begin
   return COMPONENTS(pRef.id).Title;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_FormattedTitle
--
function GET_FormattedTitle ( pRef in COMPONENT_REF )
return varchar2
is
begin
   return COMPONENTS(pRef.id).FormattedTitle;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_BeforeText
--
function GET_BeforeText ( pRef in COMPONENT_REF )
return varchar2
is
begin
   return COMPONENTS(pRef.id).BeforeText;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_AfterText
--
function GET_AfterText ( pRef in COMPONENT_REF )
return varchar2
is
begin
   return COMPONENTS(pRef.id).AfterText;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_SystemImagePath
--
function GET_SystemImagePath ( pRef in COMPONENT_REF )
return varchar2
is
begin
   return COMPONENTS(pRef.id).SystemImagePath;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_Custom
--
function GET_Custom ( pRef in COMPONENT_REF )
return varchar2
is
begin
   return COMPONENTS(pRef.id).Custom;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

----------------------
--    "Get" methods on ITEM
----------------------

--
--    GET_Name
--
function GET_Name ( pRef in ITEM_REF )
return varchar2
is
begin
   return ITEMS(pRef.id).Name;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_Prompt
--
function GET_Prompt ( pRef in ITEM_REF )
return varchar2
is
begin
   return ITEMS(pRef.id).Prompt;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_Value
--
function GET_Value ( pRef in ITEM_REF )
return varchar2
is
begin
   return ITEMS(pRef.id).Value;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_IsContext
--
function GET_IsContext ( pRef in ITEM_REF )
return boolean
is
begin
   return ITEMS(pRef.id).IsContext;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    GET_Custom
--
function GET_Custom ( pRef in ITEM_REF )
return varchar2
is
begin
   return ITEMS(pRef.id).Custom;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

----------------------
--
--    "Set" methods
--
----------------------

----------------------
--    "Set" methods on COMPONENT
----------------------
--
--    SET_BeforeText
--
procedure SET_BeforeText (pRef in COMPONENT_REF, pVal in varchar2 )
is
begin
   COMPONENTS(pRef.id).BeforeText := pVal;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

--
--    SET_AfterText
--
procedure SET_AfterText (pRef in COMPONENT_REF, pVal in varchar2 )
is
begin
   COMPONENTS(pRef.id).AfterText := pVal;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;

----------------------
--    "Set" methods on ITEM
----------------------
--
--    SET_Value
--
procedure SET_Value (pRef in ITEM_REF, pVal in varchar2 )
is
begin
   ITEMS(pRef.id).Value := pVal;
exception when no_data_found or value_error then
   raise INVALID_OBJECT_HANDLE;
end;


----------------------
--
--    "Add" methods
--
----------------------

----------------------
--    "Add" methods on COMPONENT
----------------------

procedure ADD_ITEMS
( pRef          in COMPONENT_REF
, pAddMeRef     in ITEM_REF
)
is
begin
   -- insert into nested table of refs
   COMPONENTS(pRef.id).items := COMPONENTS(pRef.id).items || to_char(pAddMeRef.id) || ',';
end;

----------------------
--
--    "Query" methods
--
----------------------

----------------------
--    "Query" methods for BRANCH
----------------------

function GET_BRANCHS
return BRANCH_REF_LIST
is
   l_list   BRANCH_REF_LIST;
   l_ref    BRANCH_REF;
   l_data   binary_integer := BRANCHS.first;
begin
   for i in 1..BRANCHS.count loop
      l_ref.id := l_data;
      l_list(i) := l_ref;
      l_data   := BRANCHS.next(l_data);
   end loop;
   return l_list;
end;

----------------------
--    "Query" methods for MODULE
----------------------

function GET_MODULES
return MODULE_REF_LIST
is
   l_list   MODULE_REF_LIST;
   l_ref    MODULE_REF;
   l_data   binary_integer := MODULES.first;
begin
   for i in 1..MODULES.count loop
      l_ref.id := l_data;
      l_list(i) := l_ref;
      l_data    := MODULES.next(l_data);
   end loop;
   return l_list;
end;


----------------------
--    "Query" methods for COMPONENT
----------------------

function GET_COMPONENTS
return COMPONENT_REF_LIST
is
   l_list   COMPONENT_REF_LIST;
   l_ref    COMPONENT_REF;
   l_data   binary_integer := COMPONENTS.first;
begin
   for i in 1..COMPONENTS.count loop
      l_ref.id := l_data;
      l_list(i) := l_ref;
      l_data    := COMPONENTS.next(l_data);
   end loop;
   return l_list;
end;

function GET_COMPONENTS
( pBranch        in  BRANCH_REF
) return COMPONENT_REF_LIST
is
   l_list   COMPONENT_REF_LIST;
   l_ref    COMPONENT_REF;
   l_data   binary_integer := COMPONENTS.first;
   l_index  binary_integer := 1;
begin
   loop
      if ( COMPONENTS(l_data).branch = pBranch.id ) then
         l_ref.id := l_data;
         l_list(l_index) := l_ref;
         l_index := l_index + 1;
      end if;
      l_data   := COMPONENTS.next(l_data);
   end loop;
exception when value_error then
   return l_list;
end;

function GET_COMPONENTS
( pModule        in  MODULE_REF
) return COMPONENT_REF_LIST
is
   l_list   COMPONENT_REF_LIST;
   l_ref    COMPONENT_REF;
   l_data   binary_integer := COMPONENTS.first;
   l_index  binary_integer := 1;
begin
   loop
      if ( COMPONENTS(l_data).Module = pModule.id ) then
         l_ref.id := l_data;
         l_list(l_index) := l_ref;
         l_index := l_index + 1;
      end if;
      l_data   := COMPONENTS.next(l_data);
   end loop;
exception when value_error then
   return l_list;
end;

function GET_COMPONENTS
( pDepth         in  binary_integer
) return COMPONENT_REF_LIST
is
   l_list   COMPONENT_REF_LIST;
   l_ref    COMPONENT_REF;
   l_data   binary_integer := COMPONENTS.first;
   l_index  binary_integer := 1;
begin
   loop
      if ( COMPONENTS(l_data).Depth = pDepth ) then
         l_ref.id := l_data;
         l_list(l_index) := l_ref;
         l_index := l_index + 1;
      end if;
      l_data   := COMPONENTS.next(l_data);
   end loop;
exception when value_error then
   return l_list;
end;

--
--    DUMP_BRANCH
--
procedure DUMP_BRANCH
( pRef        in  BRANCH_REF
)
is
begin
   dump('Dumping BRANCH(' || to_char(pRef.id) || ')');
   dump('...Name:"' || BRANCHS(pRef.id).name || '"');
   dump('...Top_Component:' || BRANCHS(pRef.id).top_component);
end;

--
--    DUMP_MODULE
--
procedure DUMP_MODULE
( pRef        in  MODULE_REF
)
is
begin
   dump('Dumping MODULE(' || to_char(pRef.id) || ')');
   dump('...Branch:' || MODULES(pRef.id).Branch);
   dump('...Shortname:"' || MODULES(pRef.id).Shortname || '"');
   dump('...FirstTitle:"' || MODULES(pRef.id).FirstTitle || '"');
   dump('...FormattedFirstTitle:"' || MODULES(pRef.id).FormattedFirstTitle || '"');
   dump('...Custom:"' || MODULES(pRef.id).Custom || '"');
end;

--
--    DUMP_COMPONENT
--
procedure DUMP_COMPONENT
( pRef        in  COMPONENT_REF
)
is
   l_items     ITEM_REF_LIST;
begin
   dump('Dumping COMPONENT(' || to_char(pRef.id) || ')');
   dump('...Branch:' || COMPONENTS(pRef.id).Branch );
   dump('...Module:' || COMPONENTS(pRef.id).Module );
   dump('...Context_for:' || COMPONENTS(pRef.id).Context_for );
   dump('...Depth:' || to_char(COMPONENTS(pRef.id).Depth) );
   dump('...Name:"' || COMPONENTS(pRef.id).Name || '"' );
   dump('...Title:"' || COMPONENTS(pRef.id).Title || '"' );
   dump('...FormattedTitle:"' || COMPONENTS(pRef.id).FormattedTitle || '"');
   dump('...BeforeText:"' || COMPONENTS(pRef.id).BeforeText || '"');
   dump('...AfterText:"' || COMPONENTS(pRef.id).AfterText || '"');
   dump('...SystemImagePath:"' || COMPONENTS(pRef.id).SystemImagePath || '"');
   dump('...Custom:"' || COMPONENTS(pRef.id).Custom || '"' );
   dump('...Embedded Items;');
   l_items := get_items(pRef);
   for i in 1..l_items.count loop
      dump_item(l_items(i));
   end loop;
end;

--
--    DUMP_ITEM
--
procedure DUMP_ITEM
( pRef        in  ITEM_REF
)
is
begin
   dump('Dumping ITEM(' || to_char(pRef.id) || ')' );
   dump('...Name:"' || ITEMS(pRef.id).name || '"' );
   dump('...Prompt:"' || ITEMS(pRef.id).prompt || '"' );
   dump('...Value:"' || ITEMS(pRef.id).value || '"' );
   if ( ITEMS(pRef.id).IsContext ) then
      dump('...Value:true' );
   else
      dump('...Value:false' );
   end if;
   dump('...Custom:"' || ITEMS(pRef.id).custom || '"' );
end;

end;
/


