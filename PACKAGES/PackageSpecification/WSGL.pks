CREATE OR REPLACE PACKAGE VMSCMS.wsgl is

--------------------------------------------------------------------------------
-- Declare constants for use in Layout procedures
   LAYOUT_TABLE      constant number(1) := 1;
   LAYOUT_PREFORMAT  constant number(1) := 2;
   LAYOUT_BULLET     constant number(1) := 3;
   LAYOUT_NUMBER     constant number(1) := 4;
   LAYOUT_CUSTOM     constant number(1) := 5;
   LAYOUT_WRAP       constant number(1) := 6;

   MENU_LONG         constant number(1) := 1;
   MENU_SHORT        constant number(1) := 2;

   TYPE_CHAR         constant number(1) := 1;
   TYPE_CHAR_UPPER   constant number(1) := 2;
   TYPE_DATE         constant number(1) := 3;
   TYPE_NUMBER       constant number(1) := 4;

-------------------------------------------------------------------------------
-- Declare constants used for system images
   IMG_TYPE_TICK     constant number(1) := 1;
   IMG_TYPE_RADIO    constant number(1) := 2;

   IMG_TICK          constant varchar2(50) := 'cg_tick.gif';
   IMG_BLANK         constant varchar2(50) := 'cg_blnk.gif';

   IMG_RADIO_SEL     constant varchar2(50) := 'cg_rad_s.gif';
   IMG_RADIO_UNSEL   constant varchar2(50) := 'cg_rad_u.gif';

--------------------------------------------------------------------------------
-- Declare constant for Max number of rows which can be returned
   MAX_ROWS          constant number(4) := 1000;

--------------------------------------------------------------------------------
-- Declare types used in Domain Validation

   DV_TEXT            constant number(1) := 1;
   DV_CHECK           constant number(1) := 2;
   DV_RADIO           constant number(1) := 3;
   DV_LIST            constant number(1) := 4;
   DV_RADIO_ACROSS    constant number(1) := 5;

   type typString240Table is table of varchar2(240)
                          index by binary_integer;

   type typDVRecord is record
        (ColAlias    varchar2(30) := null,
         Initialised boolean      := false,
         ControlType number(1)    := DV_TEXT,
         DispWidth   number(5)    := 30,
         DispHeight  number(5)    := 1,
         MaxWidth    number(5)    := 30,
         UseMeanings boolean      := false,
         ColOptional boolean      := false,
         NumOfVV     integer      := 0,
         Vals typString240Table,
         Meanings typString240Table,
         Abbreviations typString240Table);

   EmptyStringTable  typString240Table;
   EmptyVCArr        owa.vc_arr;
   EmptyVCArrLong    owa_text.vc_arr;

--------------------------------------------------------------------------------
-- Declare types used in building controls
   CTL_READONLY     constant number(1) := 1;
   CTL_UPDATABLE    constant number(1) := 2;
   CTL_INSERTABLE   constant number(1) := 3;
   CTL_QUERY        constant number(1) := 4;

--------------------------------------------------------------------------------
-- Declare constants for form status
   FORM_STATUS_OK      constant number(1) := 0;
   FORM_STATUS_ERROR   constant number(1) := 1;
   FORM_STATUS_INS     constant number(1) := 2;
   FORM_STATUS_UPD     constant number(1) := 3;
   FORM_STATUS_NO_UPD  constant number(1) := 4;

--------------------------------------------------------------------------------
-- Declare constants message types
   MESS_INFORMATION    constant number(1) := 1;
   MESS_SUCCESS        constant number(1) := 2;
   MESS_WARNING        constant number(1) := 3;
   MESS_ERROR          constant number(1) := 4;
   MESS_ERROR_QRY      constant number(1) := 5;
   MESS_EXCEPTION      constant number(1) := 6;

--------------------------------------------------------------------------------
-- Declare security constants and exceptions
   WSG_CLIENTID_COOKIE constant varchar(30) := 'WSGSEC$WSGSECCLIENTID';
   invalid_user exception;
--------------------------------------------------------------------------------
-- Declare WebServer Generator Library procedures and functions

   function IsSupported (feature in varchar2) return boolean;
   pragma restrict_references(IsSupported, WNDS);

   procedure LayoutOpen(p_layout_style in number,
                        p_border in boolean default false,
                        p_custom_bullet in varchar2 default null,
                        p_no_spacing in boolean default false);

   procedure LayoutClose;

   procedure LayoutRowStart(p_valign in varchar2 default null,
                            p_attrs  in varchar2 default null);
   pragma restrict_references(LayoutRowStart, WNDS);

   procedure LayoutRowEnd;

   procedure LayoutHeader(p_width in number,
                          p_align in varchar2,
                          p_title in varchar2);
   pragma restrict_references(LayoutHeader, WNDS);

   procedure LayoutData(p_text in varchar2,
                        p_align in varchar2 default null);
   pragma restrict_references(LayoutData, WNDS);

   procedure LayoutData(p_date in date);
   pragma restrict_references(LayoutData, WNDS);

   procedure LayoutData(p_number in number);
   pragma restrict_references(LayoutData, WNDS);

   procedure LayoutComputed ( p_prompt_col   in   number,
                              p_prompt       in   varchar2,
                              p_item_col     in   number,
                              p_item         in   varchar2,
                              p_total_cols   in   number,
                              p_row_attrs    in   varchar2 default null);

   procedure LayoutTextLine ( p_text  in  varchar2 );

   procedure Separator ( p_from_col   in   number,
                         p_to_col     in   number,
                         p_total      in   number,
                         p_attrs      in   varchar2 default null);

   procedure Separator (p_attrs      in   varchar2);

   procedure DefinePageHead(p_title in varchar2 default null,
                            p_bottomframe in boolean default false);

   procedure StylesheetLink(p_stylesheetURL in varchar2);

   procedure OpenPageHead(p_title in varchar2 default null,
                          p_bottomframe in boolean default false);

   procedure ClosePageHead;

   procedure OpenPageBody(p_center in boolean default false,
                          p_attributes in varchar2 default null);

   procedure ClosePageBody;

   function  InBottomFrame return boolean;
   pragma restrict_references(InBottomFrame, WNDS, WNPS);

   function  Preformat(p_text in varchar2) return varchar2;
   pragma restrict_references(Preformat, WNDS, WNPS);

   procedure DefaultPageCaption(p_caption in varchar2 default null,
                                p_headlevel in number default null);

   procedure BuildWhere(p_field1   in varchar2,
                        p_field2   in varchar2,
                        p_sli      in varchar2,
                        p_datatype in number,
                        p_where    in out varchar2,
                        p_date_format in varchar2 default null,
                        p_outerjoin in boolean default false);
   pragma restrict_references(BuildWhere, WNDS);

   procedure BuildWhere(p_field    in varchar2,
                        p_sli      in varchar2,
                        p_datatype in number,
                        p_where    in out varchar2,
                        p_date_format in varchar2 default null,
                        p_caseinsensitive in boolean default true,
                        p_outerjoin in boolean default false);
   pragma restrict_references(BuildWhere, WNDS);

   procedure BuildWhere(p_field    in typString240Table,
                        p_sli      in varchar2,
                        p_datatype in number,
                        p_where    in out varchar2,
                        p_date_format in varchar2 default null,
                        p_outerjoin in boolean default false);
   pragma restrict_references(BuildWhere, WNDS);

   function SearchComponents(p_search in varchar2,
                             p_uu in out varchar2,
                             p_ul in out varchar2,
                             p_lu in out varchar2,
                             p_ll in out varchar2) return number;
   pragma restrict_references(SearchComponents, WNDS);

   procedure NavLinks(p_style in number default null,
                      p_caption in varchar2 default null,
                      p_menu_level in number default 0,
                      p_proc in varchar2 default null,
                      p_target in varchar2 default '_top',
                      p_attributes in varchar2 default null,
                      p_img in varchar2 default null,
                      p_img_height  in number default 0,
                      p_img_width   in number default 0,
                      p_output_line in boolean default TRUE,
                      p_list_item   in boolean default TRUE,
                      p_menu_required in boolean default TRUE);

   function  TablesSupported return boolean;
   pragma restrict_references(TablesSupported, WNDS, WNPS);

   procedure Info(p_full in boolean default true,
                  p_app in varchar2 default null,
                  p_mod in varchar2 default null,
                  p_usr in varchar2 default null);

   procedure EmptyPage(p_attributes in varchar2 default null);

   function  EmptyPageURL(p_attributes in varchar2 default null) return varchar2;
   pragma restrict_references(EmptyPageURL, WNDS, WNPS);

   procedure SubmitButton(p_name in varchar2,
                          p_title in varchar2,
                          p_type in varchar2,
                          buttonJS in varchar2 default null,
                          p_target in varchar2 default null);

   function ReturnSubmitButton(p_name in varchar2,
                               p_title in varchar2,
                               p_type in varchar2,
                               buttonJS in varchar2 default null,
                               p_target in varchar2 default null,
                               p_index in number default 0) return varchar2;
   pragma restrict_references(ReturnSubmitButton, WNDS);

   procedure ResetForMultipleForms;
   pragma restrict_references(ResetForMultipleForms, WNDS);

   procedure RecordListButton(p_reqd in boolean,
                              p_name in varchar2,
                              p_title in varchar2,
                              p_mess in varchar2 default null,
                              p_dojs in boolean default false,
                              buttonJS in varchar2 default null,
                              p_type_button in boolean default false
                             );

   function  CountHits(
             P_SQL in varchar2) return number;

   procedure LoadDomainValues(
             P_REF_CODE_TABLE in varchar2,
             P_DOMAIN in varchar2,
             P_DVREC in out typDVRecord);

   function ValidDomainValue(
            P_DVREC in typDVRecord,
            P_VALUE in out varchar2) return boolean;
   pragma restrict_references(ValidDomainValue, WNDS);

   function DomainMeaning(
            P_DVREC in typDVRecord,
            P_VALUE in varchar2) return varchar2;
   pragma restrict_references(DomainMeaning, WNDS);

   function DomainValue(
            P_DVREC in typDVRecord,
            P_MEANING in varchar2) return varchar2;
   pragma restrict_references(DomainValue, WNDS);

   function DomainValue(
            P_DVREC in typDVRecord,
            P_MEANING in typString240Table) return typString240Table;
   pragma restrict_references(DomainValue, WNDS);

   function BuildDVControl(
            P_DVREC in typDVRecord,
            P_CTL_STYLE in number,
            P_CURR_VAL in varchar2 default null,
            p_onclick in boolean default false,
            p_onchange in boolean default false,
            p_onblur in boolean default false,
            p_onfocus in boolean default false,
            p_onselect in boolean default false,
            p_row in number default null,
            p_multirow in boolean default false,
            p_alwaysquery in boolean default false,
            p_img_path in varchar2 default '/') return varchar2;
   pragma restrict_references(BuildDVControl, WNDS);

   function BuildTextControl(
            p_alias in varchar2,
            p_size in varchar2 default null,
            p_height in varchar2 default null,
            p_maxlength in varchar2 default null,
            p_value in varchar2 default null,
            p_onclick in boolean default false,
            p_onchange in boolean default false,
            p_onblur in boolean default false,
            p_onfocus in boolean default false,
            p_onselect in boolean default false,
            p_cal_but_text    in varchar2 default null,
            p_cal_date_format in varchar2 default null,
            p_form in varchar2 default 'forms[0]',
            p_row in number default null,
            p_img_path in varchar2 default '/',
            p_cal_prompt in varchar2 default null) return varchar2;
   pragma restrict_references(BuildTextControl, WNDS);

   function BuildQueryControl(
            p_alias in varchar2,
            p_size in varchar2 default null,
            p_range in boolean default false,
            p_onclick in boolean default false,
            p_onchange in boolean default false,
            p_onblur in boolean default false,
            p_onfocus in boolean default false,
            p_onselect in boolean default false,
            p_cal_but_text    in varchar2 default null,
            p_cal_date_format in varchar2 default null,
            p_form in varchar2 default 'forms[0]',
            p_maxlength in varchar2 default null,
            p_cal_prompt in varchar2 default null) return varchar2;
   pragma restrict_references(BuildQueryControl, WNDS);

   function BuildDerivationControl(p_name in varchar2,
                                   p_size in varchar2,
                                   p_value in varchar2,
                                   p_onclick in boolean default false,
                                   p_onblur in boolean default false,
                                   p_onfocus in boolean default false,
                                   p_onselect in boolean default false,
                                   p_row in number default null) return varchar2;
   pragma restrict_references(BuildDerivationControl, WNDS);

   function InitSysImage(p_image_type in number,
                         p_image_path in varchar2,
                         p_image_name in varchar2,
                         p_initial_val in varchar2) return varchar2;
   pragma restrict_references(InitSysImage, WNDS, WNPS);

   procedure HiddenField(p_paramname in varchar2,
                         p_paramval in varchar2);

   procedure HiddenField(p_paramname in varchar2,
                         p_paramval in typString240Table);

   function GetLayNumberOfPages return number;

   procedure DisplayMessage(p_type in number,
                            p_mess in varchar2,
                            p_title in varchar2 default null,
                            p_attributes in varchar2 default null,
                            p_location in varchar2 default null,
                            p_context in varchar2 default null,
                            p_action in varchar2 default null);

   procedure StoreErrorMessage(p_mess in varchar2);

   function MsgGetText(p_MsgNo in number,
                       p_DfltText in varchar2 default null,
                       p_Subst1 in varchar2 default null,
                       p_Subst2 in varchar2 default null,
                       p_Subst3 in varchar2 default null,
                       p_LangId in number default null) return varchar2;
   pragma restrict_references(MsgGetText, WNDS, WNPS);

   function EscapeURLParam(p_param in varchar2 ) return varchar2;
   pragma restrict_references(EscapeURLParam, WNDS, WNPS);

   function GetUser return varchar2;

   procedure RegisterURL(p_url in varchar2);

   procedure AddURLParam(p_paramname in varchar2,
                         p_paramval in varchar2);
   pragma restrict_references(AddURLParam, WNDS);

   procedure AddURLParam(p_paramname in varchar2,
                         p_paramval in typString240Table);
   pragma restrict_references(AddURLParam, WNDS);

   procedure RefreshURL;

   function NotLowerCase return boolean;

   function ExternalCall(p_proc in varchar2) return boolean;

   function CalledDirect(p_proc in varchar2) return boolean;

   procedure StoreURLLink(p_level in number,
                          p_caption in varchar2,
                          p_open in boolean default true,
                          p_close in boolean default true);

   procedure ReturnLinks(p_levels in varchar2,
                         p_style  in number,
                         p_target in varchar2 default '_top',
                         p_menu   in boolean  default true);

   function Checksum(p_buff in varchar2) return number;
   pragma restrict_references(Checksum, WNDS, WNPS);

   function ValidateChecksum(p_buff in varchar2, p_checksum in varchar2) return boolean;

   -- R2.1 Backward compatibility
   function EscapeURLParam(p_param in varchar2,
                           p_space in boolean default true,
                           p_plus in boolean default true,
                           p_percent in boolean,
                           p_doublequote in boolean default true,
                           p_hash in boolean default true,
                           p_ampersand in boolean ) return varchar2;
   pragma restrict_references(EscapeURLParam, WNDS, WNPS);


   -- R1.3 Backward compatibility
   procedure RowContext(p_context in varchar2);

   procedure PageHeader(p_title in varchar2,
                        p_header in varchar2,
                        p_background in varchar2 default null,
                        p_center in boolean default false);

   procedure PageFooter;

   function  MAX_ROWS_MESSAGE return varchar2;
   pragma restrict_references(MAX_ROWS_MESSAGE, WNDS, WNPS);

  procedure Output_Calendar
    (
     Z_FIELD_NAME      in VarChar2,
     Z_FIELD_VALUE     in Varchar2,
     Z_FIELD_FORMAT    in Varchar2,
     Page_Header       in Varchar2,
     Body_Attributes   in Varchar2,
     PKG_Name          in Varchar2,
     Close_But_Caption in Varchar2,
     First_Part        in Boolean,
     Z_DEFAULT_FORMAT  in varchar2 default null
    );

  procedure Output_Format_Cal_JS
    (
     Page_Header     in Varchar2,
     Body_Attributes in Varchar2,
     Chosen_Date     in Varchar2,
     Field_Format    in Varchar2
    );


  procedure StoreClientID( p_client_id_str  in  varchar2,
                           p_open_header    in  boolean   default true,
                           p_close_header   in  boolean   default true );

  function GetClientID return varchar2;

  -- version to get around bug 872931
  function Anchor2
    ( curl           in       varchar2,
      ctext          in       varchar2,
      cname          in       varchar2   DEFAULT NULL,
      ctarget        in       varchar2   DEFAULT NULL,
      cattributes    in       varchar2   DEFAULT NULL
    ) return varchar2;
  pragma restrict_references(Anchor2, WNDS, WNPS);

  -- version to get around bug 965862
  function img (
   curl           in       varchar2,
   calign         in       varchar2   DEFAULT NULL,
   calt           in       varchar2   DEFAULT NULL,
   cismap         in       varchar2   DEFAULT NULL,
   cattributes    in       varchar2   DEFAULT NULL
  ) return varchar2;
  pragma restrict_references(img, WNDS, WNPS);

  function EscapeItem( z_item_text in varchar2 ) return varchar2;
  pragma restrict_references( EscapeItem, WNDS, WNPS );

end;
/


CREATE OR REPLACE PACKAGE BODY VMSCMS.wsgl is

-- Current version of WSGL
   WSGL_VERSION constant varchar2(30) := '6.5.22.0.0';
   v_current_client_id  varchar2(240);

--------------------------------------------------------------------------------
-- Define types for pl/sql tables of number(10), varchar(20) and boolean
-- for use internally in layout
   type typNumberTable   is table of number(10)
                         index by binary_integer;

   type typString20Table is table of varchar2(20)
                         index by binary_integer;

   type typBooleanTable  is table of boolean
                         index by binary_integer;

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- Define the features and subfeatures tables for browsers
--
--

type featuresRecT is record
(
   browser   varchar2 (50),
   feature   varchar2 (50),
   supported boolean
);

type featuresTableT is table of featuresRecT index by binary_integer;

featuresTable featuresTableT;

--------------------------------------------------------------------------------
-- Define Layout variables.  These retain their value only for the
-- duration of the creation of a single page.
   LayNumOfCols       number(3) := 0;
   LayCurrentCol      number(3) := 0;
   LayColumnWidths    typNumberTable;
   LayColumnAlign     typString20Table;
   LayPageCenter      typBooleanTable;
   LayOutputLine      Long;
   LayPaddedText      Long;
   LayDataSegment     Long;
   LayEmptyLine       boolean := TRUE;
   LayActionCreated   boolean := FALSE;
   LayStyle           number(1) := LAYOUT_TABLE;
   LayBorderTable     boolean := FALSE;
   LayVertBorderChars varchar2(4);
   LayHoriBorderChars varchar2(2000);
   LayCustomBullet    varchar2(256) := '';
   LayNumberOfPages   number(2) := 0;
   LayNumberOfRLButs  number(2) := 0;
   LayMenuLevel       number(3) := -1;
   LayInBottomFrame   boolean := false;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Define variable to hold URL currently being built.
   CurrentURL   varchar2(2000);
   URLComplete  boolean := false;
   URLCookieSet boolean := false;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Declare private procedure for padding preformatted text
   procedure LayoutPadTextToLength(p_text in out varchar2,
                                   p_length in number,
                                   p_align in varchar2);
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Declare private procedure for where clause predicates
   function BuildWherePredicate(p_field1   in varchar2,
                                p_field2   in varchar2,
                                p_sli      in varchar2,
                                p_datatype in number,
                                p_where    in out varchar2,
                                p_date_format in varchar2,
                                p_caseinsensitive in boolean,
                                p_outerjoin in boolean default FALSE) return varchar2;
   function CaseInsensitivePredicate(p_sli in varchar2,
                                     p_field in varchar2,
                                     p_operator in varchar2) return varchar2;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Name:        Info
--
-- Description: Display information about WSGL.  Useful for debugging purposes.
--
-- Parameters:  p_full is a full list reequired (no if called from About)
--              p_app  name of application system
--              p_mod  name of module
--
--------------------------------------------------------------------------------
procedure Info(p_full in boolean default true,
               p_app in varchar2 default null,
               p_mod in varchar2 default null,
               p_usr in varchar2 default null ) is
   cursor c1 is
      select product, version, status
      from   product_component_version
      where  upper(product) like '%ORACLE%SERVER%'
      or     upper(product) like '%PL/SQL%'
      order  by product;
   current_user varchar2(255);
begin
   if p_usr is not null then
      current_user := p_usr;
   else
      current_user := GetUser;
   end if;
   if p_full then
      DefinePageHead(MsgGetText(101,WSGLM.DSP101_WSGL_INFO));
      OpenPageBody;
      DefaultPageCaption(MsgGetText(101,WSGLM.DSP101_WSGL_INFO));
   end if;
   LayoutOpen(LAYOUT_TABLE, TRUE);
   LayoutRowStart;
   LayoutHeader(50, 'LEFT', NULL);
   LayoutHeader(50, 'LEFT', NULL);
   LayoutRowEnd;
   LayoutRowStart;
   LayoutData(MsgGetText(102,WSGLM.DSP102_WSGL));
   LayoutData(WSGL_VERSION);
   LayoutRowEnd;
   LayoutRowStart;
   LayoutData(MsgGetText(103,WSGLM.DSP103_USER));
   LayoutData(current_user);
   LayoutRowEnd;
   for c1rec in c1 loop
      LayoutRowStart;
      LayoutData(c1rec.product);
      LayoutData(c1rec.version||' '||c1rec.status);
      LayoutRowEnd;
   end loop;
   if not p_full then
      LayoutRowStart;
      LayoutData(MsgGetText(105,WSGLM.DSP105_WEB_SERVER));
      LayoutData(owa_util.get_cgi_env('SERVER_SOFTWARE'));
      LayoutRowEnd;
      LayoutRowStart;
      LayoutData(MsgGetText(106,WSGLM.DSP106_WEB_BROWSER));
      LayoutData(owa_util.get_cgi_env('HTTP_USER_AGENT'));
      LayoutRowEnd;
      LayoutRowStart;
      LayoutData(MsgGetText(125,WSGLM.DSP125_REPOS_APPSYS));
      LayoutData(p_app);
      LayoutRowEnd;
      LayoutRowStart;
      LayoutData(MsgGetText(126,WSGLM.DSP126_REPOS_MODULE));
      LayoutData(p_mod);
      LayoutRowEnd;
   end if;
   LayoutClose;
   if p_full then
      htp.header(LayNumberOfPages, MsgGetText(104,WSGLM.DSP104_ENVIRONMENT));
      owa_util.print_cgi_env;
      ClosePageBody;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.Info<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        IsSupported
--
-- Description: Maps HTML and Javascript features to browsers to determine if
--              the browser being used supports a given feature or subfeature
--
-- Parameters:  feature    IN the main feature we want to know if the browser
--                            supports
--------------------------------------------------------------------------------

function IsSupported (feature in varchar2) return boolean is

  browser        varchar2(2000) := owa_util.get_cgi_env ('HTTP_USER_AGENT');
  featureSupport boolean        := True;

begin

  -- Browser string must be unique

  featuresTable (1).browser   := 'MOZILLA/2.__%';
  featuresTable (1).feature   := 'NOSCRIPT';
  featuresTable (1).supported := False;

  -- Search the features table for a matching entry

  for i in 1..featuresTable.count
  loop

    if (upper (browser) like upper (featuresTable (i).browser)) and
       (upper (feature) =    upper (featuresTable (i).feature))
    then

      featureSupport := featuresTable (i).supported;

    end if;

  end loop;

  return featureSupport;

end IsSupported;

--------------------------------------------------------------------------------
-- Name:        LayoutOpen
--
-- Description: This procedure is used to set up information which will
--              control how data/fields are layed out in the generated
--              pages.  A number of layout styles are supported, defined
--              by the constants LAYOUT_TABLE, LAYOUT_BULLET etc
--
-- Parameters:  p_layout_style   IN  The layout style
--              p_border         IN  If layout style is TABLE, should the
--                                   table have a border
--              p_custom_bullet  IN  If the layout style is CUSTOM, the
--                                   expression to use as the custom bullet
--------------------------------------------------------------------------------
procedure LayoutOpen(p_layout_style in number,
                     p_border in boolean,
                     p_custom_bullet in varchar2,
                     p_no_spacing in boolean) is
begin
   -- Initialise the layout parameters

   LayStyle := p_layout_style;
   LayCustomBullet := p_custom_bullet;
   LayBorderTable := p_border;
   LayVertBorderChars := ' ';
   LayHoriBorderChars := NULL;
   LayNumOfCols := 0;
   LayCurrentCol := 0;
   if (LayStyle = LAYOUT_BULLET)
   then
      -- Open List
      htp.ulistOpen;
   elsif (LayStyle = LAYOUT_NUMBER)
   then
      -- Open List
      htp.olistOpen;
   elsif (LayStyle = LAYOUT_TABLE)
   then
      -- If tables are requested, check that the current browser
      -- supports them, if not, default to PREFORMAT
      if (TablesSupported) then
         htp.para;
         -- Open Table
         if (p_border) then

            htp.tableOpen('BORDER');
         else
            if p_no_spacing then
                htp.tableOpen(cattributes=>'BORDER=0 cellspacing=0 cellpadding=4');
            else
                htp.tableOpen;
            end if;
         end if;
      else
         LayoutOpen(LAYOUT_PREFORMAT, p_border, p_custom_bullet);
      end if;
   elsif (LayStyle = LAYOUT_PREFORMAT)
   then
      -- Open Preformat
      htp.preOpen;
      if (p_border) then
         LayVertBorderChars := '|';
      end if;
   else
      -- Start a new paragraph if WRAP
      htp.para;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.LayoutOpen<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        LayoutClose
--
-- Description: End the layout area.
--
-- Parameters:  None
--
--------------------------------------------------------------------------------
procedure LayoutClose is
begin
   if LayCurrentCol <> LayNumOfCols then
      LayCurrentCol := LayNumOfCols;
      LayoutRowEnd;
   end if;
   if (LayStyle = LAYOUT_BULLET)
   then
      htp.ulistClose;
   elsif (LayStyle = LAYOUT_NUMBER)
   then
      htp.olistClose;
   elsif (LayStyle = LAYOUT_TABLE)
   then
      htp.tableClose;
   elsif (LayStyle = LAYOUT_PREFORMAT)
   then
      if LayBorderTable then
         htp.p(LayHoriBorderChars);
      end if;
      htp.preClose;
   end if;
   htp.para;
exception
   when others then
      raise_application_error(-20000, 'WSGL.LayoutClose<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        LayoutRowStart
--
-- Description: Starts a 'row' in the current layout style.  This may be
--              a real row if it is a table, or a new list item for lists
--              etc.
--
--              Initialises the variable LayOutputLine which is used to
--              build the entire 'row' until it is printed using
--              LayoutRowEnd().
--
-- Parameters:  p_valign  IN   The verical alignment of the row if TABLE
--
--------------------------------------------------------------------------------
procedure LayoutRowStart(p_valign in varchar2,
                         p_attrs  in varchar2) is
begin
   if LayCurrentCol <> LayNumOfCols then
      return;
   end if;
   LayCurrentCol := 0;
   LayEmptyLine := TRUE;
   if (LayStyle = LAYOUT_BULLET) or
      (LayStyle = LAYOUT_NUMBER)
   then
      -- Add list item marker
      LayOutputLine :=  htf.ListItem;
   elsif (LayStyle = LAYOUT_CUSTOM)
   then
      -- Add the Custom Bullet
      LayOutputLine := LayCustomBullet || ' ';
   elsif (LayStyle = LAYOUT_TABLE)
   then
      -- Start a new row
      LayOutputLine := htf.tableRowOpen(cvalign=>p_valign, cattributes=>p_attrs);
   elsif (LayStyle = LAYOUT_PREFORMAT)
   then
      LayOutputLine := LayVertBorderChars;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.LayoutRowStart<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        LayoutRowEnd
--
-- Description: If anything in the current row, it is output using htp.p()
--              procedure, and then LayOutputLine is cleared.
--
-- Parameters:  None
--
--------------------------------------------------------------------------------
procedure LayoutRowEnd is
   l_loop number(4) := 0;
begin
   if LayCurrentCol <> LayNumOfCols then
      return;
   end if;
   if not LayEmptyLine
   then
      if (LayStyle = LAYOUT_BULLET) or
         (LayStyle = LAYOUT_NUMBER)
      then
         htp.p(LayOutputLine);
      elsif (LayStyle = LAYOUT_CUSTOM)
      then
         htp.p(LayOutputLine);
         htp.nl;
      elsif (LayStyle = LAYOUT_TABLE)
      then
         htp.p(LayOutputLine || htf.tableRowClose);
      else
         if LayStyle = LAYOUT_PREFORMAT and LayBorderTable then
            if LayHoriBorderChars is null then
               LayHoriBorderChars := '-';
               for l_loop in 1..LayNumOfCols loop
                 LayHoriBorderChars := LayHoriBorderChars || rpad('-', LayColumnWidths(l_loop) + 1, '-');
               end loop;
            end if;
            htp.p(LayHoriBorderChars);
         end if;
         htp.p(LayOutputLine);

      end if;
   end if;
   LayOutputLine := '';
exception
   when others then
      raise_application_error(-20000, 'WSGL.LayoutRowEnd<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        LayoutHeader
--
-- Description: This is used when layout style is TABLE or PREFORMAT and
--              defines the 'Columns' of the table.  Each has a width
--              (not used for TABLE), an alignment and a title.  The pl/sql
--              tables LayColumnWidths and LayColumnAlign are initilaised in
--              order that later calls to LayoutData will be correctly
--              position data/fields.
--
--              This procedure has no effect when layout style is not
--              TABLE or PREFORMAT,
--
-- Parameters:  p_width   IN   Column width
--              p_align   IN   Horizontal alignment or data in this column
--              p_title   IN   Title, if any
--
--------------------------------------------------------------------------------
procedure LayoutHeader(p_width in number,
                       p_align in varchar2,
                       p_title in varchar2) is
   l_width number(5);
begin
   LayNumOfCols := LayNumOfCols + 1;
   LayCurrentCol := LayNumOfCols;
   -- Only applicable if TABLE or PREFORMAT
   if ( (LayStyle != LAYOUT_TABLE) and
        (LayStyle != LAYOUT_PREFORMAT)
      ) then
      return;
   end if;
   -- If a title is defined, check if it is longer than the width of the
   -- data in the column, in which case PREFORMAT column would need to be
   -- wider
   if p_title is not null then
      l_width := length(p_title);
   else
      l_width := 0;
   end if;

   -- Record the required column width
   if l_width > p_width then
      LayColumnWidths(LayCurrentCol) := l_width;
   else
      LayColumnWidths(LayCurrentCol) := p_width;
   end if;
   -- Record the required column alignment
   LayColumnAlign(LayCurrentCol) := p_align;
   -- If TABLE, create table header
   if (LayStyle = LAYOUT_TABLE)
   then
      LayOutputLine := LayOutputLine || htf.tableHeader(p_title, p_align);
      if p_title is not null then
         LayEmptyLine := FALSE;
      end if;
   -- If PREFORMAT, simulate table header
   elsif (LayStyle = LAYOUT_PREFORMAT)
   then
      LayPaddedText := htf.bold(p_title);
      LayoutPadTextToLength(LayPaddedText,
                            LayColumnWidths(LayCurrentCol),
                            LayColumnAlign(LayCurrentCol));
      LayOutputLine := LayOutputLine || LayPaddedText || LayVertBorderChars;

      if p_title is not null then
         LayEmptyLine := FALSE;
      end if;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.LayoutHeader<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        LayoutData
--
-- Description: Add the text to LayOutputLine in the current layout style,
--              in prepeartion for being written out by a call to
--              LayoutRowEnd.
--
-- Parameters:  p_text   IN   The text (or field definition etc, any html)
--                            to be output.
--              p_align  IN   The alignment for this item if different from
--                            previous rows. (Default null).
--
--------------------------------------------------------------------------------
procedure LayoutData(p_text in varchar2,
                     p_align in varchar2) is
   l_align    varchar2(30);
begin
   LayCurrentCol := LayCurrentCol + 1;
   LayEmptyLine := FALSE;
   if p_align is null then
      if (LayStyle = LAYOUT_TABLE) or (LayStyle = LAYOUT_PREFORMAT) then
         l_align := LayColumnAlign(LayCurrentCol);
      end if;
   else
      l_align := p_align;
   end if;

   if (LayStyle = LAYOUT_TABLE)
   then
      -- Add Table data, with specified alignment
      LayOutputLine := LayOutputLine ||
           htf.tableData(p_text, l_align);
   elsif (LayStyle = LAYOUT_PREFORMAT)
   then
      -- Create a copy of p_text in LayPaddedText, padded in such a way as to
      -- be the correct width and with the correct alignment
      LayPaddedText := nvl(p_text, ' ');
      if (LayCurrentCol <= LayNumOfCols) then
         LayoutPadTextToLength(LayPaddedText,
                               LayColumnWidths(LayCurrentCol),
                               l_align);
      else
         LayPaddedText := LayPaddedText || ' ';
      end if;
      LayOutputLine := LayOutputLine || LayPaddedText || LayVertBorderChars;
   else
      -- For styles other than TABLE and PREFORMAT, simply add the text to
      -- LayOutputLine
      LayOutputLine := LayOutputLine || p_text || ' ';
   end if;

exception
   when others then
      raise_application_error(-20000, 'WSGL.LayoutData<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        LayoutData
--
-- Description: LayoutData overloaded with a date parameter
--
-- Parameters:  p_date   IN  The date to be displayed
--
--------------------------------------------------------------------------------
procedure LayoutData(p_date in date) is
begin
   LayoutData(to_char(p_date));
exception
   when others then
      raise_application_error(-20000, 'WSGL.LayoutData2<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        LayoutData
--
-- Description: LayoutData overloaded with a number parameter

--
-- Parameters:  p_number   IN  The number to be displayed
--
--------------------------------------------------------------------------------
procedure LayoutData(p_number in number) is
begin
   LayoutData(to_char(p_number));
exception
   when others then
      raise_application_error(-20000, 'WSGL.LayoutData3<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        LayoutPadTextToLength
--
-- Description: Pads the given string to the specified length and alignment.
--              Anything that appears between < and > will not be counted
--              when determining the width because it is assumed this is
--              HTML tags which are not displayed.
--
-- Parameters:  p_text   IN/OUT   The text to be padded
--              p_length IN       The width to pad to
--              p_align  IN       The alignment (LEFT/CENTER/RIGHT)
--

--------------------------------------------------------------------------------
procedure LayoutPadTextToLength(p_text in out varchar2,
                                p_length in number,
                                p_align in varchar2) is
   l_loop   number(4) := 0;
   l_count  number(4) := 0;
   l_pad    number(4) := 0;
   l_pre    varchar2(1000);
   l_post   varchar2(1000);
   l_ignore boolean := FALSE;
begin
   for l_loop in 1..length(p_text) loop
      if substr(p_text, l_loop, 1) = '<' then
         l_ignore := TRUE;
      elsif l_ignore then
         if substr(p_text, l_loop - 1, 1) = '>' then
            l_ignore := FALSE;
         end if;
      end if;
      if (not l_ignore) then
         l_count := l_count + 1;
      end if;
   end loop;

   l_pad := p_length - l_count;
   if l_pad > 0 then
      if p_align = 'LEFT' then
         l_pre := '';
         l_post := rpad(' ', l_pad);
      elsif p_align = 'CENTER' then
         if l_pad > 1 then
            l_pre := rpad(' ', floor(l_pad / 2));
            l_post := rpad(' ', ceil(l_pad / 2));
         else
            l_pre := '';
            l_post := rpad(' ', l_pad);
         end if;
      elsif p_align = 'RIGHT' then
         l_pre := rpad(' ', l_pad);
         l_post := '';
      end if;
      p_text := l_pre || p_text || l_post;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.LayoutPadTextToLength<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        LayoutComputed
--
-- Description: Draws a computed item and its prompt on a new row.
--
-- Parameters:  p_prompt_col   in   number    Column to display item prompt
--              p_prompt       in   varchar2  Item prompt text
--              p_item_col     in   number    Column to display item value
--              p_item         in   varchar2  Item value text
--              p_total_cols   in   number    Total no of cols in record list
--              p_row_attrs    in   varchar2  Attributes to assign to table row
--
--
-- BUG 1331123 :: Made sure procedure can cope if p_prompt_col >= p_item_col by
--                displaying prompt and item value in same column as the
--                original code did when prompt and item column = 1.
--------------------------------------------------------------------------------
procedure LayoutComputed ( p_prompt_col   in   number,
                           p_prompt       in   varchar2,
                           p_item_col     in   number,
                           p_item         in   varchar2,
                           p_total_cols   in   number,
                           p_row_attrs    in   varchar2) is
   i           integer;
   prompt_col  number := p_prompt_col;
begin
   LayoutRowStart(p_attrs=>p_row_attrs);

   if ( p_prompt_col > p_item_col )
   then
      prompt_col := p_item_col;
   end if;

   for i in 1..(prompt_col - 1)
   loop
      LayoutData('&nbsp');
   end loop;

   if ( prompt_col = p_item_col )
   then
      LayoutData(p_prompt || ' ' || p_item);
   else
      LayoutData(p_prompt, 'RIGHT');
      for i in (prompt_col + 1)..(p_item_col - 1)
      loop
         LayoutData('&nbsp');
      end loop;
      LayoutData(p_item);
   end if;

   for i in (p_item_col + 1)..p_total_cols
   loop
      LayoutData('&nbsp');
   end loop;

   LayoutRowEnd;
exception
   when others then
      raise_application_error(-20000, 'WSGL.LayoutComputed<br>'||SQLERRM);
end;
--------------------------------------------------------------------------------
-- Name:        LayoutTextLine
--
-- Description: Draws a row containing the specified text. The text may span the
--              entire line. This is used for embedding lines of text within
--              tables.
--
-- Parameters:  p_text       IN   The text to display.
--
--------------------------------------------------------------------------------
procedure LayoutTextLine ( p_text  in  varchar2 )
is
begin
   LayCurrentCol := LayNumOfCols;
   LayoutRowStart('TOP');
   if (LayStyle = LAYOUT_TABLE) then
       LayOutputLine := LayOutputLine || htf.tableData( cvalue=>p_text, ccolspan=>LayNumOfCols );
   else
       LayOutputLine := LayOutputLine || p_text;
   end if;
   LayCurrentCol := LayNumOfCols;
   LayEmptyLine := false;
   LayoutRowEnd;
exception
   when others then
      raise_application_error(-20000, 'WSGL.LayoutTextLine<br>'||SQLERRM);
end;
--------------------------------------------------------------------------------
-- Name:        Separator
--
-- Description: Draws a row containing a line from column p_from_col to
--              p_to_col. Used to seperate computed items from data items
--              on the record list.
--
-- Parameters:  p_from_col   IN   Column number for beginning of line.
--              p_to_col     IN   Column number for end of line.
--              p_total      IN   Total number of columns in record list
--

--------------------------------------------------------------------------------
procedure Separator ( p_from_col   in   number,
                      p_to_col     in   number,
                      p_total      in   number,
                      p_attrs      in   varchar2) is
   i            integer;
   j            integer;
   l_string     varchar2(255);
begin
   LayoutRowStart(p_attrs=>p_attrs);
   for i in 1..(p_from_col - 1) loop
      LayoutData('&nbsp');
   end loop;
   for i in p_from_col..p_to_col loop
       if (LayStyle = LAYOUT_TABLE) then
          LayoutData('<HR size=1 noshade>');
       elsif (LayStyle = LAYOUT_PREFORMAT) then
          l_string := '';
          for j in 1..(LayColumnWidths(LayCurrentCol + 1)) loop
             l_string := l_string || '-';
          end loop;
          LayoutData(l_string);
       end if;
   end loop;
   for i in (p_to_col + 1)..LayColumnAlign.count loop
      LayoutData('&nbsp');
   end loop;
   LayoutRowEnd;
exception
   when others then
      raise_application_error(-20000, 'WSGL.Separator<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        Separator (overloaded)
--
-- Description: Draws a line across the page
--
-- Parameters:  p_attrs    in varchar2  - Style attributes for separator
--
--
--------------------------------------------------------------------------------
procedure Separator (p_attrs      in   varchar2) is
   i            integer;
   j            integer;
   l_string     varchar2(255);
begin
   LayoutRowStart(p_attrs=>p_attrs);
   for i in 1..LayColumnAlign.count loop
       if (LayStyle = LAYOUT_TABLE) then
          LayoutData('<HR size=1 noshade>');
       elsif (LayStyle = LAYOUT_PREFORMAT) then
          l_string := '';
          for j in 1..(LayColumnWidths(LayCurrentCol + 1)) loop
             l_string := l_string || '-';
          end loop;
          LayoutData(l_string);
       end if;
   end loop;

   LayoutRowEnd;
exception
   when others then
      raise_application_error(-20000, 'WSGL.Separator<br>'||SQLERRM);
end;
--------------------------------------------------------------------------------
-- Name:        DefinePageHead
--
-- Description: Short cut call of OpenPageHead and ClosePageHead
--
-- Parameters:  p_title       IN   Page Title caption
--      p_bottomframe IN   Is this the bottom frame ?
--
--------------------------------------------------------------------------------
procedure DefinePageHead(p_title in varchar2,
                         p_bottomframe in boolean) is
begin
   OpenPageHead(p_title, p_bottomframe);
   ClosePageHead;
exception
   when others then
      raise_application_error(-20000, 'WSGL.DefinePageHead<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        OpenPageHead
--
-- Description:
--
-- Parameters:  p_title       IN   Page Title caption
--      p_bottomframe IN   Is this the bottom frame ?
--
--------------------------------------------------------------------------------
procedure OpenPageHead(p_title in varchar2 default null,
                       p_bottomframe in boolean default false) is
begin
   LayNumberOfPages := LayNumberOfPages + 1;
   LayInBottomFrame := p_bottomframe;

   if (LayNumberOfPages = 1) then
      htp.htmlOpen;
      htp.headOpen;
      if p_title is not null then
         htp.title(p_title);
      end if;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.OpenPageHead<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        StylesheetLink
--
-- Description: Output stylesheet link tag..
--
-- Parameters:  Stylesheet URL.
--
--------------------------------------------------------------------------------
procedure StylesheetLink(p_stylesheetURL in varchar2)
is
begin
   if (LayNumberOfPages = 1) then
      htp.p('<link REL="Stylesheet" TYPE="text/css" HREF="'||
            p_stylesheetURL||'">');
   end if;
exception
   when others then
      raise_application_error(-20000,'WSGL.StylesheetLink<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        ClosePageHead
--
-- Description:
--
-- Parameters:  None
--
--------------------------------------------------------------------------------
procedure ClosePageHead is
begin
   if (LayNumberOfPages = 1) then
      htp.headClose;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.ClosePageHead<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        OpenPageBody
--

-- Description:
--
-- Parameters:  p_center     IN   Center Alignment
--      p_attributes IN   Body attributes
--
--------------------------------------------------------------------------------
procedure OpenPageBody(p_center in boolean,
                       p_attributes in varchar2) is
  l_prev_centered boolean := FALSE;
begin
   LayPageCenter(LayNumberOfPages) := p_center;
   if (LayNumberOfPages = 1) then
      htp.bodyOpen(cattributes=>p_attributes);
   end if;
   if (LayNumberOfPages > 1) then
      l_prev_centered := LayPageCenter(LayNumberOfPages - 1);
   end if;
   if LayPageCenter(LayNumberOfPages) and not l_prev_centered then
      htp.p('<CENTER>');
   elsif not LayPageCenter(LayNumberOfPages) and l_prev_centered then
      htp.p('</CENTER>');
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.OpenPageBody<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        ClosePageBody
--
-- Description: Terminate page with </BODY> and </HTML> tags if appropriate
--
-- Parameters:  None
--
--------------------------------------------------------------------------------
procedure ClosePageBody is
  l_this_centered boolean := FALSE;
begin
   if (LayNumberOfPages > 1) then
      l_this_centered := LayPageCenter(LayNumberOfPages - 1);
   end if;
   if l_this_centered and not LayPageCenter(LayNumberOfPages) then
      htp.p('<CENTER>');
   elsif not l_this_centered and LayPageCenter(LayNumberOfPages) then
      htp.p('</CENTER>');
   end if;
   if (LayNumberOfPages = 1) then
      htp.bodyClose;
      htp.htmlClose;
   end if;
   LayNumberOfPages := LayNumberOfPages - 1;
exception
   when others then
      raise_application_error(-20000, 'WSGL.ClosePageBody<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        InBottomFrame
--
-- Description: Test if building page for bottom frame
--
-- Parameters:  None
--
-- Returns:     True if building page for bottom frame
--              False otherwise
--
--------------------------------------------------------------------------------
function InBottomFrame return boolean is
begin
   return LayInBottomFrame;
end;

--------------------------------------------------------------------------------
-- Name:        Preformat
--
-- Description: Builds Preformatted HTML string
--
-- Parameters:  p_text
--
-- Returns:     Preformatted HTML string
--
--------------------------------------------------------------------------------
function Preformat(p_text in varchar2) return varchar2 is
begin
   return '<PRE>'||p_text||'</PRE>';
end;

--------------------------------------------------------------------------------
-- Name:        DefaultPageCaption
--
-- Description:
--
-- Parameters:  p_caption    IN   Page caption
--
--------------------------------------------------------------------------------
procedure DefaultPageCaption(p_caption in varchar2,
                             p_headlevel in number) is
begin
   htp.header(nvl(p_headlevel, LayNumberOfPages), p_caption);
exception
   when others then
      raise_application_error(-20000, 'WSGL.DefaultPageCaption<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        BuildWherePredicate
--
-- Description: The purpose of this procedure is to build WHERE clause
--              predicates based on the value of two parameters p_field1
--              and p_field2.  The values of these two parameters will be
--              determined by values entered into a Query Form.
--              If a range query is supported (for numeric and date fields
--              which are not in a Primary, Unique or Foreign key constraint)
--              then the two parameters are populated independantly from
--              two fields on the form, otherwise both parameters are
--              populated with the same value, from the same field.
--
--              Using the value(s) of these two input parameters, the
--              Select List Item (SLI) they are constraining, and the
--              datatype, a predicate is built and added to the WHERE clause.
--
--              Values entered for columns of datatype NUMBER or DATE are
--              tested to be valid entry by applying to_number/to_date
--              functions (using the format mask supplied, if any, for date
--              columns).  If this validation fails, an EXCEPTION will be
--              raised which should be handled by calling procedure.
--
--
-- Parameters:  p_field1       IN       Query criteria field 1
--              p_field2       IN       Query criteria field 2
--              p_sli          IN       The Select List Item
--              p_datatype     IN       The datatype
--              p_where        IN/OUT   The WHERE clause
--              p_date_format  IN       (Optional) Date Format Mask
--
--------------------------------------------------------------------------------
function BuildWherePredicate(p_field1   in varchar2,
                             p_field2   in varchar2,
                             p_sli      in varchar2,
                             p_datatype in number,
                             p_where    in out varchar2,
                             p_date_format in varchar2,
                             p_caseinsensitive in boolean,
                             p_outerjoin in boolean default false) return varchar2 is
   l_predicate varchar2(2000);
   l_field1    varchar2(255) := rtrim(p_field1);
   l_field2    varchar2(255) := rtrim(p_field2);
   l_num1      number;
   l_num2      number;
   l_date1     date := null;
   l_date2     date := null;
   l_newsli    varchar2(255);
begin
   -- If this is an outer-join, then add the appropriate
   -- symbol to the select list item.
   if p_outerjoin then
      l_newsli := p_sli || '(+)';
   else
      l_newsli := p_sli;
   end if;
   -- No where clause predicate required for this SLI
   if (l_field1 is null and l_field2 is null) then
      return null;
   -- Support user defined expression
   elsif (substr(ltrim(l_field1), 1, 1) = '#') then
      l_predicate := l_newsli || ' ' || substr(ltrim(l_field1),2);
   -- Special case where 'Unknown' string is entered for an optional col in a domain
   elsif (l_field1 = MsgGetText(1,WSGLM.CAP001_UNKNOWN)) then
      l_predicate := l_newsli || ' is null';
   else
      -- check for single apostrophies in query
      if (instr(l_field1,'''') != 0) then
         l_field1:=replace(l_field1,'''','''''');
      end if;
      -- Add <sli> like '<field1>'
      if (instr(l_field1, '%') != 0) or (instr(l_field1, '_') != 0) then
         if p_datatype = TYPE_DATE then
            if p_date_format is null then
               l_predicate := 'to_char('||l_newsli||') like ''' || l_field1 || '''';
            else
               l_predicate := 'to_char('||l_newsli||', '''||p_date_format||

                              ''') like ''' || l_field1 || '''';
            end if;
         elsif p_datatype = TYPE_CHAR_UPPER then
            l_predicate := l_newsli || ' like ''' || upper(l_field1) || '''';
         elsif p_datatype = TYPE_CHAR and p_caseinsensitive then
            l_predicate := CaseInsensitivePredicate(l_newsli,l_field1,'LIKE');
         else
            l_predicate := l_newsli || ' like ''' || l_field1 || '''';
         end if;
      elsif p_datatype = TYPE_CHAR_UPPER then
         -- Add <sli> = <field1>
         l_predicate := l_newsli || ' = ''' || upper(l_field1) || '''';
      elsif p_datatype = TYPE_CHAR and p_caseinsensitive then
         l_predicate := CaseInsensitivePredicate(l_newsli,l_field1,'=');
      elsif p_datatype = TYPE_CHAR then
         -- Add <sli> = <field1>
         l_predicate := l_newsli || ' = ''' || l_field1 || '''';
      elsif p_datatype = TYPE_NUMBER then
         -- validate the specified field(s) are valid numbers
         if l_field1 is not null then
            l_num1 := to_number(l_field1);
         end if;
         if l_field2 is not null then
            l_num2 := to_number(l_field2);
         end if;
         -- Add <sli> = <field1>
         if (l_field1 = l_field2) then

            l_predicate := l_newsli || ' = ' || l_field1;
         -- Add <sli> <= <field2>
         elsif (l_field1 is null) then
            l_predicate := l_newsli || ' <= ' || l_field2;
         -- Add <sli> >= <field1>
         elsif (l_field2 is null) then
            l_predicate := l_newsli || ' >= ' || l_field1;
         -- Add <sli> between <field1> and <filed2>
         elsif (l_num1 < l_num2) then
            l_predicate := l_newsli || ' between ' || l_field1 ||
                                     ' and ' || l_field2;
         -- Add <sli> between <field2> and <filed1>
         else
            l_predicate := l_newsli || ' between ' || l_field2 ||
                                     ' and ' || l_field1;
         end if;
      elsif p_datatype = TYPE_DATE then
         -- validate the specified field(s) are valid dates
         if p_date_format is not null and l_field1 is not null then
            l_date1 := to_date(l_field1, p_date_format);
         elsif l_field1 is not null then
            l_date1 := to_date(l_field1);
         end if;

         if p_date_format is not null and l_field2 is not null then
            l_date2 := to_date(l_field2, p_date_format);
         elsif l_field2 is not null then
            l_date2 := to_date(l_field2);
         end if;
         -- if we get this far, ie no exception raised, then valid dates were entered,
         -- build strings for RHSs
         if p_date_format is not null and l_field1 is not null then
            l_field1 := 'to_date('''||l_field1||''', '''||p_date_format||''')';
         elsif l_field1 is not null then
            l_field1 := 'to_date('''||l_field1||''')';
         end if;
         if p_date_format is not null and l_field2 is not null then
            l_field2 := 'to_date('''||l_field2||''', '''||p_date_format||''')';
         elsif l_field2 is not null then
            l_field2 := 'to_date('''||l_field2||''')';
         end if;
         -- Add <sli> = '<field1>'
         if (l_field1 = l_field2) then
            l_predicate := l_newsli || ' = ' || l_field1;
         -- Add <sli> <= '<field2>'
         elsif (l_field1 is null) then
            l_predicate := l_newsli || ' <= ' || l_field2;

         -- Add <sli> >= '<field1>'
         elsif (l_field2 is null) then
            l_predicate := l_newsli || ' >= ' || l_field1;
         -- Add <sli> between '<field1>' and '<field2>'
         elsif (l_date1 < l_date2) then
            l_predicate := l_newsli || ' between ' || l_field1 || ' and ' || l_field2;
         -- Add <sli> between '<field1>' and '<field2>'
         else
            l_predicate := l_newsli || ' between ' || l_field2 || ' and ' || l_field1;
         end if;
      end if;
   end if;
   return l_predicate;
end;

--------------------------------------------------------------------------------
-- Name:        BuildWhere
--
-- Description: Overloaded version of buildwhere which is used when there is
--              only one Query Criteria filed.  Simply calls the main BuildWhere
--              procedure, passing p_field1 in twice.
--
-- Parameters:  p_field        IN       Query criteria field
--              p_sli          IN       The Select List Item
--              p_datatype     IN       The datatype
--              p_where        IN/OUT   The WHERE clause
--              p_date_format  IN       (Optional) Date Format Mask
--
--------------------------------------------------------------------------------
procedure BuildWhere(p_field1   in varchar2,
                     p_field2   in varchar2,
                     p_sli      in varchar2,
                     p_datatype in number,
                     p_where    in out varchar2,
                     p_date_format in varchar2,
                     p_outerjoin in boolean default false) is
   l_predicate varchar2(2000);
begin
   l_predicate := BuildWherePredicate(p_field1, p_field2, p_sli, p_datatype,
                                      p_where, p_date_format, FALSE,
                                      p_outerjoin=>p_outerjoin);
   if l_predicate is null then
      return;
   elsif p_where is null or p_where = '' then
      p_where := ' where (' || l_predicate || ')';
   else
      p_where := p_where || ' and (' || l_predicate || ')';
   end if;
end;

--------------------------------------------------------------------------------
-- Name:        BuildWhere
--
-- Description: Overloaded version of buildwhere which is used when there is
--              only one Query Criteria filed.  Simply calls the main BuildWhere
--              procedure, passing p_field1 in twice.
--
-- Parameters:  p_field        IN       Query criteria field
--              p_sli          IN       The Select List Item
--              p_datatype     IN       The datatype
--              p_where        IN/OUT   The WHERE clause
--              p_date_format  IN       (Optional) Date Format Mask
--
--------------------------------------------------------------------------------
procedure BuildWhere(p_field    in varchar2,
                     p_sli      in varchar2,
                     p_datatype in number,
                     p_where    in out varchar2,
                     p_date_format in varchar2,
                     p_caseinsensitive in boolean,
                     p_outerjoin in boolean default false) is
   l_predicate varchar2(2000);
begin
   l_predicate := BuildWherePredicate(p_field, p_field, p_sli, p_datatype,
                                      p_where, p_date_format, p_caseinsensitive,
                                      p_outerjoin=>p_outerjoin);
   if l_predicate is null then
      return;
   elsif p_where is null or p_where = '' then
      p_where := ' where (' || l_predicate || ')';
   else
      p_where := p_where || ' and (' || l_predicate || ')';
   end if;
end;

--------------------------------------------------------------------------------
-- Name:        BuildWhere
--
-- Description: Overloaded version of buildwhere which is used when there is
--              only one Query Criteria filed.  Simply calls the main BuildWhere
--              procedure, passing p_field1 in twice.
--
-- Parameters:  p_field        IN       Query criteria field
--              p_sli          IN       The Select List Item
--              p_datatype     IN       The datatype
--              p_where        IN/OUT   The WHERE clause
--              p_date_format  IN       (Optional) Date Format Mask
--
--------------------------------------------------------------------------------
procedure BuildWhere(p_field    in typString240Table,
                     p_sli      in varchar2,
                     p_datatype in number,
                     p_where    in out varchar2,
                     p_date_format in varchar2,
                     p_outerjoin in boolean default false) is
   l_count number := 1;
   l_field varchar2(240);
   l_predicate varchar2(2000);
   l_new varchar2(2000);
begin
   begin
      while true loop
         l_field := p_field(l_count);
         l_predicate := BuildWherePredicate(l_field, l_field, p_sli, p_datatype,
                                            p_where, p_date_format, FALSE,
                                            p_outerjoin=>p_outerjoin);
         if l_predicate is not null then
            if l_new is not null then
               l_new := l_new || ' or ';
            end if;
            l_new := l_new || '(' || l_predicate || ')';
         end if;
         l_count := l_count + 1;
      end loop;
   exception
      when no_data_found then
         null;
      when others then
         raise;
   end;
   if l_new is not null then
      if p_where is null or p_where = '' then
         p_where := ' where (' || l_new || ')';
      else
         p_where := p_where || ' and (' || l_new || ')';
      end if;
   end if;
end;

--------------------------------------------------------------------------------
-- Name:        CaseInsensitivePredicate
--
-- Description: Build an efficient case insensitive query.  This function will
--              build a where clause predicate which attempts to minimise the
--              effect of losing the index on a search column.
--
-- Parameters:  p_sli          IN       The Select List Item
--              p_field        IN       Query criteria field
--              p_operator     IN       The operator (=/like)
--
--------------------------------------------------------------------------------
function CaseInsensitivePredicate(p_sli in varchar2,
                                  p_field in varchar2,
                                  p_operator in varchar2) return varchar2 is
   l_uu  varchar2(2000) := null;
   l_ul  varchar2(2000) := null;
   l_lu  varchar2(2000) := null;
   l_ll  varchar2(2000) := null;
   l_retval number;
begin
   l_retval := SearchComponents(p_field, l_uu, l_ul, l_lu, l_ll);
   if l_retval = -1 then
      return 'upper('|| p_sli || ') ' || p_operator || ' ''' || upper(p_field) || '''';
   elsif l_retval = 0 then
      return p_sli || ' ' || p_operator || ' ''' || p_field || '''';
   elsif l_retval = 1 then
      return p_sli || ' ' || p_operator || ' ''' || l_uu || ''' or ' ||
             p_sli || ' ' || p_operator || ' ''' || l_ll || '''';
   elsif l_retval = 2 then
      return p_sli || ' ' || p_operator || ' ''' || l_uu || ''' or ' ||
             p_sli || ' ' || p_operator || ' ''' || l_ul || ''' or ' ||
             p_sli || ' ' || p_operator || ' ''' || l_lu || ''' or ' ||
             p_sli || ' ' || p_operator || ' ''' || l_ll || '''';
   else
      return '('|| p_sli || ' like ''' || l_uu || '%'' or ' ||
                   p_sli || ' like ''' || l_ul || '%'' or ' ||
                   p_sli || ' like ''' || l_lu || '%'' or ' ||
                   p_sli || ' like ''' || l_ll || '%'') and upper('||
                   p_sli || ') ' || p_operator || ' ''' || upper(p_field) || '''';
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.CaseInsensitivePredicate<br>'||SQLERRM);
      return null;
end;

--------------------------------------------------------------------------------
-- Name:        SearchComponents
--
-- Description: This procedure determines the components of a case insensitive
--              query.
--
-- Parameters:  p_search  IN      The search string
--              p_uu      IN OUT  Substring with first two alphas uppercase
--              p_ul      IN OUT  Substring with first two alphas upper/lowercase
--              p_lu      IN OUT  Substring with first two alphas lower/uppercase
--              p_ll      IN OUT  Substring with first two alphas lowercase
--
-- Returns:     The number of case sensitive chars in search string
--              -  3 means >2
--              - -1 means the first character was a wild card
--------------------------------------------------------------------------------
function SearchComponents(p_search in varchar2,
                          p_uu in out varchar2,
                          p_ul in out varchar2,
                          p_lu in out varchar2,
                          p_ll in out varchar2) return number is
   l_upp varchar2(4)   := null;
   l_low varchar2(4)   := null;
   l_chars number      := 0;
   l_count number      := 0;
begin

   p_uu := null;
   p_ul := null;
   p_lu := null;
   p_ll := null;

   while ((l_chars < 3) and (l_count < length(p_search))) loop
      l_count := l_count + 1;
      l_upp := upper(substr(p_search,l_count,1));
      l_low := lower(substr(p_search,l_count,1));
      if l_upp = l_low then
         p_uu := p_uu || l_upp;
         p_ul := p_ul || l_upp;
         p_lu := p_lu || l_upp;
         p_ll := p_ll || l_upp;
      else
         l_chars := l_chars + 1;
         if l_chars = 1 then
            p_uu := p_uu || l_upp;
            p_ul := p_ul || l_upp;
            p_lu := p_lu || l_low;
            p_ll := p_ll || l_low;
         elsif l_chars = 2 then
            p_uu := p_uu || l_upp;
            p_ul := p_ul || l_low;
            p_lu := p_lu || l_upp;
            p_ll := p_ll || l_low;
          end if;
      end if;
   end loop;

   if substr(p_search,1,1) = '%' or substr(p_search,1,1) = '_' then
      return -1;
   else
      return l_chars;
   end if;

exception
   when others then
      raise_application_error(-20000, 'WSGL.SearchComponents<br>'||SQLERRM);
      return null;
end;

--------------------------------------------------------------------------------
-- Name:        NavLinks
--
-- Description: Builds 'Menu' of navigation links.
--
-- Parameters:  p_style      IN   The style (LONG/SHORT) or NULL to
--                                indicate end of menu
--              p_caption    IN   The menu/link caption
--              p_menu_level IN   The menu level
--              p_proc       IN   The procedure to call, or null if menu
--                                caption
--
-------------------------------------------------------------------------------
procedure NavLinks(p_style         in number,
                   p_caption       in varchar2,
                   p_menu_level    in number,
                   p_proc          in varchar2,
                   p_target        in varchar2,
                   p_attributes    in varchar2,
                   p_img           in varchar2,
                   p_img_height    in number,
                   p_img_width     in number,
                   p_output_line   in boolean default TRUE,
                   p_list_item     in boolean default TRUE,
                   p_menu_required in boolean default TRUE ) is
   levels    number(2) := 0;
   i         number(2) := 0;
   img_attrs varchar2(40) null;
begin
   -- the variable 'levels' is the change in menu level, i.e. indentation,
   -- from last level (LayMenuLevel) to the new level (p_menu_level)
   if p_style is null then
      -- close all opened menus
      levels := LayMenuLevel + 1;
      if levels > 0 then
         for i in 1..levels loop
            htp.menulistClose;
         end loop;
      end if;
      LayMenuLevel := -1;
      return;
   end if;
   if LayMenuLevel = -1 then
      -- first menu, put out a line
     if p_output_line then
        htp.para;
        htp.line;
     end if;
   end if;
   if p_menu_required then
      -- If there is a change in menu level, open or close menus as
      -- appropriate
      levels := (p_menu_level - LayMenuLevel);
      if levels > 0 then
         for i in 1..levels loop
            htp.menulistOpen;
         end loop;
      elsif levels < 0 then
         for i in 1..-levels loop
            htp.menulistClose;
         end loop;
         htp.para;
      end if;
   end if;
   -- if a procedure has been defined, build a link to it, or otherwise
   -- just display the menu caption
   if p_proc is null then
      htp.para;
      if p_style = MENU_LONG then
         htp.listItem;
      end if;
      htp.bold(p_caption);
   elsif p_img is not null then
      -- An image has been defined. Use this instead of the
     -- text supplied.
      if p_img_height > 0 then
        img_attrs := 'height=' || p_img_height;
      end if;
      if p_img_width > 0 then
        img_attrs := img_attrs || ' width=' || p_img_width;
      end if;
      -- Is this to be a list item or not?
     if p_list_item then
        htp.p(htf.listItem||htf.anchor2(p_proc, htf.img (curl=>p_img, calt=>p_caption, cattributes=>img_attrs), ctarget=>p_target, cattributes=>p_attributes)||' ');
     else
        htp.p(htf.anchor2(p_proc, htf.img (curl=>p_img, calt=>p_caption, cattributes=>img_attrs), ctarget=>p_target, cattributes=>p_attributes)||' ');
      end if;
   elsif p_style = MENU_SHORT then
      htp.p(htf.anchor2(p_proc, '['||p_caption||']', ctarget=>p_target, cattributes=>p_attributes)||' ');
   elsif p_style = MENU_LONG then
      -- Is this to be a list item or not?
     if p_list_item then
        htp.p(htf.listItem||htf.anchor2(p_proc, p_caption, ctarget=>p_target, cattributes=>p_attributes)||' ');
     else
        htp.p(htf.anchor2(p_proc, p_caption, ctarget=>p_target, cattributes=>p_attributes)||' ');
      end if;
   end if;
   LayMenuLevel := p_menu_level;
exception
   when others then
      raise_application_error(-20000, 'WSGL.NavLinks<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        TablesSupported
--
-- Description: Does the current browser support HTML tables?
--
--
-- Parameters:  None
--
-- Returns:     True   If browser supports HTML tables
--              False  Otherwise
--
--------------------------------------------------------------------------------
function TablesSupported return boolean is
begin
   -- This function can be modified if it is anticipated that
   -- the server/browser combination does not support tables
   -- Use owa_util.get_cgi_env('http_user_agent') to get the
   -- the name of the browser being used, and construct a test
   -- based on that.  Default behaviour is just to return true
   -- as all common browsers support HTML tables.
   return true;
end;

--------------------------------------------------------------------------------
-- Name:        EmptyPage
--
-- Description: Create an empty page
--
-- Parameters:  p_attributes IN Body attributes
--
--------------------------------------------------------------------------------
procedure EmptyPage(p_attributes in varchar2) is
begin
   DefinePageHead;
   OpenPageBody(FALSE, p_attributes);
   ClosePageBody;
end;

--------------------------------------------------------------------------------
-- Name:        EmptyPageURL
--
-- Description: Create URL for call to WSGL.EmptyPage
--
-- Parameters:  p_attributes IN Body attributes
--
--------------------------------------------------------------------------------
function EmptyPageURL(p_attributes in varchar2 default null) return varchar2 is
begin
   return 'wsgl.emptypage?P_ATTRIBUTES=' ||
          replace(replace(replace(p_attributes,' ','%20'),
                          '"', '%22'),
                  '=', '%3D');
end;

--------------------------------------------------------------------------------
-- Name:        SubmitButton
--
-- Description: Creates HTML/JavaScript code which is interpreted as follows:
--              - If the Browser does not support JavaScript a Submit button
--                of the given name, and with the given title is created
--              - If the Browser supports JavaScript a button is created with
--                a call to an event handler on the onClick event.  If this is
--                the first call, JavaScript code is also created to build a
--                hidden field called p_name.
--
-- Parameters:  p_name    IN   The name of the submit button, or hidden field
--              p_title   IN   Button caption
--              p_type    IN   The type of button, used in creating name of
--                             event handler
--              p_target  IN   Name of target frame to perform action in.
--
--------------------------------------------------------------------------------
procedure SubmitButton(p_name in varchar2,
                       p_title in varchar2,
                       p_type in varchar2,
                       buttonJS in varchar2 default null,
                       p_target in varchar2 default null) is

New_Button_JS varchar2 (2000) := buttonJS;
New_Title     varchar2 (2000) := p_title;

begin
   -- Conditionally escape '' in p_title depending upon whether it is already escaped or not

   if instr (p_title, '\''', 1) = 0
   then
      -- Not already escaped

     New_Title := replace (p_title, '''', '\''');
   end if;

   if NOT LayActionCreated then

      htp.p('<SCRIPT><!--');
      htp.p('document.write(''<input type=hidden name="'||p_name||'">'')');
      htp.p('//-->');
      htp.p('</SCRIPT>');
      LayActionCreated := true;

   end if;

   htp.p('<SCRIPT><!--');

   if buttonJS is null
   then

     htp.p('//--> '||htf.formSubmit(p_name, p_title)||' <!--');
     if p_target is null
     then
       htp.p('document.write(''<input type=button value="'||New_Title||'" onClick="return ' ||p_type||'_OnClick(this)">'')');
     else
       htp.p('document.write(''<input type=button value="'||New_Title||'" onClick="return ' ||p_type||'_OnClick(this,0,&quot;' || p_target|| '&quot;)">'')');
     end if;
     htp.p('//-->');
     htp.p('</SCRIPT>');

   else

     -- Conditionally escape '' in buttonJS depending upon whether it is already escaped or not

     if instr (buttonJS, '\''', 1) = 0
     then
       -- Not already escaped

       New_Button_JS := replace (buttonJS, '''', '\''');
     end if;

     if p_target is null
     then
       htp.p ('document.write(''<input type=button value="'||New_Title||'" onClick="' ||
               New_Button_JS || '; return ' ||p_type||'_OnClick(this)">'')');
     else
       htp.p ('document.write(''<input type=button value="'||New_Title||'" onClick="' ||
               New_Button_JS || '; return ' ||p_type||'_OnClick(this,0,&quot;' || p_target|| '&quot;)">'')');
     end if;
     htp.p ('//-->');
     htp.p ('</SCRIPT>');

     if WSGL.IsSupported ('NOSCRIPT')
     then

       htp.p ('<NOSCRIPT>');
       htp.p (htf.formSubmit(p_name, p_title));
       htp.p ('</NOSCRIPT>');

     end if;

   end if;  -- buttonJS is null

exception
   when others then
      raise_application_error(-20000, 'WSGL.SubmitButton<br>'||SQLERRM);
end;


--------------------------------------------------------------------------------
-- Name:        ReturnSubmitButton
--
-- Description: Creates HTML/JavaScript code which is interpreted as follows:
--              - If the Browser does not support JavaScript a Submit button
--                of the given name, and with the given title is created
--              - If the Browser supports JavaScript a button is created with
--                a call to an event handler on the onClick event.  If this is
--                the first call, JavaScript code is also created to build a
--                hidden field called p_name.
--              This code is then returned to the calling function.
--
-- Parameters:  p_name    IN   The name of the submit button, or hidden field
--              p_title   IN   Button caption
--              p_type    IN   The type of button, used in creating name of
--                             event handler
--              p_target  IN   Name of target frame to perform action in.
--
--------------------------------------------------------------------------------
function ReturnSubmitButton(p_name in varchar2,
                            p_title in varchar2,
                            p_type in varchar2,
                            buttonJS in varchar2 default null,
                            p_target in varchar2 default null,
                            p_index  in number default 0) return varchar2 is

New_Button_JS      varchar2 (2000) := buttonJS;
New_Title          varchar2 (2000) := p_title;
Submit_Button_Text varchar2 (2000) := 'foo';
Z_Action_Text      varchar2 (2000) := '';

begin
   -- Conditionally escape '' in p_title depending upon whether it is already escaped or not

   if instr (p_title, '\''', 1) = 0
   then
      -- Not already escaped

     New_Title := replace (p_title, '''', '\''');
   end if;

   if NOT LayActionCreated then
      Z_Action_Text := '
<SCRIPT><!--
document.write(''<input type=hidden name="'||p_name||'">'')//-->
</SCRIPT>';
      LayActionCreated := true;
   end if;

   Submit_Button_Text := Z_Action_Text ||'
<SCRIPT><!--';

   if buttonJS is null
   then

     if p_target is null
     then
       Submit_Button_Text := Submit_Button_Text ||'
document.write(''<input type=button value="'||New_Title||'" onClick="return ' ||p_type||'_OnClick(this,'||p_index||')">'')';
     else
       Submit_Button_Text := Submit_Button_Text ||'
document.write(''<input type=button value="'||New_Title||'" onClick="return ' ||p_type||'_OnClick(this,'||p_index||',&quot;' || p_target|| '&quot;)">'')';
     end if;
     Submit_Button_Text := Submit_Button_Text ||'
//-->';
     Submit_Button_Text := Submit_Button_Text ||'
</SCRIPT>';

     if WSGL.IsSupported ('NOSCRIPT')
     then

       Submit_Button_Text := Submit_Button_Text ||'
<NOSCRIPT>';
       Submit_Button_Text := Submit_Button_Text ||
htf.formSubmit(p_name, p_title);
       Submit_Button_Text := Submit_Button_Text ||'
</NOSCRIPT>';

     end if;

   else

     -- Conditionally escape '' in buttonJS depending upon whether it is already escaped or not

     if instr (buttonJS, '\''', 1) = 0
     then
       -- Not already escaped

       New_Button_JS := replace (buttonJS, '''', '\''');
     end if;

     if p_target is null
     then
       Submit_Button_Text := Submit_Button_Text ||'document.write(''<input type=button value="'||New_Title||'" onClick="' ||
               New_Button_JS || '; return ' ||p_type||'_OnClick(this,'||p_index||')">'')';
     else
       Submit_Button_Text := Submit_Button_Text ||'document.write(''<input type=button value="'||New_Title||'" onClick="' ||
               New_Button_JS || '; return ' ||p_type||'_OnClick(this,'||p_index||',&quot;' || p_target|| '&quot;)">'')';
     end if;

     Submit_Button_Text := Submit_Button_Text ||'
//-->';
     Submit_Button_Text := Submit_Button_Text ||'
</SCRIPT>';

     if WSGL.IsSupported ('NOSCRIPT')
     then

       Submit_Button_Text := Submit_Button_Text ||'
<NOSCRIPT>';
       Submit_Button_Text := Submit_Button_Text ||
htf.formSubmit(p_name, p_title);
       Submit_Button_Text := Submit_Button_Text ||'
</NOSCRIPT>';

     end if;

   end if;  -- buttonJS is null

   return Submit_Button_Text ;

exception
   when others then
      raise_application_error(-20000, 'WSGL.SubmitButton<br>'||SQLERRM);
end;


--------------------------------------------------------------------------------
-- Name:        ResetForMultipleForms
--
-- Description: This procedure is provided to handle the situation where
--              there is more than one form created within the current page
--              (for example, when the detail form is displayed on the same
--              page as the master).
--              It resets the "LayActionCreated" flag to it's initial value
--              of FALSE. This flag determines whether or not a hidden field
--              for the submit action has been created for this form. If it is
--              not reset, and there is more than one form within the page,
--              the second form will not get the hidden field created, resulting
--              in a javascript error whenever the submit action is performed.
--
-- Parameters:  None
--
--------------------------------------------------------------------------------
procedure ResetForMultipleForms is
begin
   LayActionCreated := FALSE ;
end;

--------------------------------------------------------------------------------
-- Name:        RecordListButton
--
-- Description: If the functionality of the button is required, an HTML Submit
--              button is created.  If it is not required, for example, the
--              'Next' button, when at the end of the Record List, then either JavaScript
--              code is written out to create a button which issues an Alert with
--              the given message or no buttons are displayed depending on user preference.
--          If JavaScript is not supported, then no button is created.
--
-- Parameters:  p_reqd    IN   Is the button functionality required
--              p_name    IN   Submit Button name
--              p_title   IN   Button caption
--              p_mess    IN   The message to issue if the functionality is not
--                             required
--      p_dojs    IN   Is JS Alert issued or buttons not displayed
--
--------------------------------------------------------------------------------
procedure RecordListButton(p_reqd in boolean,
                           p_name in varchar2,
                           p_title in varchar2,
                           p_mess in varchar2,
                           p_dojs in boolean default false,
                           buttonJS in varchar2 default null,
                           p_type_button in boolean default false
                  ) is

New_Button_JS varchar2 (2000) := buttonJS;

begin
   if (p_reqd) then

     htp.p ('<SCRIPT><!--');

     -- Conditionally escape '' in buttonJS depending upon whether it is already escaped or not

     if instr (buttonJS, '\''', 1) = 0
     then

       -- Not already escaped

       New_Button_JS := replace (buttonJS, '''', '\''');

     end if;
     if p_type_button then
        htp.p ('document.write (''<input type=button value="' || p_title || '" ' || New_Button_JS || '>'')');
     else
        htp.p ('document.write (''<input type=submit value="' || p_title || '" ' || New_Button_JS || '>'')');
     end if;

     htp.p('//-->');
     htp.p('</SCRIPT>');

     if WSGL.IsSupported ('NOSCRIPT')
     then

       htp.p ('<NOSCRIPT>');
       htp.p (htf.formSubmit(p_name, p_title));
       htp.p ('</NOSCRIPT>');

     end if;

   elsif (p_dojs) then

     LayNumberOfRLButs := LayNumberOfRLButs + 1;
     htp.p('<SCRIPT><!--');
     htp.p('var msg'||to_char(LayNumberOfRLButs)||'="'||p_mess||'"');
     htp.p('document.write(''<input type=button value="'||p_title||
           '" onClick="alert(msg'||to_char(LayNumberOfRLButs)||')">'')');
     htp.p('//-->');
     htp.p('</SCRIPT>');

     if WSGL.IsSupported ('NOSCRIPT')
     then

       htp.p ('<NOSCRIPT>');
       htp.p (htf.formSubmit(p_name, p_title));
       htp.p ('</NOSCRIPT>');

     end if;

   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.RecordListButton<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        CountHits
--
-- Description: Takes a SQL SELECT statement and replaces the Select list
--              with count(*), then executes the SQL to return the number
--              of hits.
--
-- Parameters:  P_SQL  The SELECT statement
--
-- Returns:     Number of hits
--              -1 if an error occurs
--
--------------------------------------------------------------------------------
   function  CountHits(
             P_SQL in varchar2) return number is
      I_QUERY     varchar2(2000) := '';
      I_CURSOR    integer;
      I_VOID      integer;
      I_FROM_POS  integer := 0;
      I_COUNT     number(10);
   begin
      I_FROM_POS := instr(upper(P_SQL), ' FROM ');
      if I_FROM_POS = 0 then
         return -1;
      end if;
      I_QUERY := 'SELECT count(*)' ||
                 substr(P_SQL, I_FROM_POS);
      I_CURSOR := dbms_sql.open_cursor;
      dbms_sql.parse(I_CURSOR, I_QUERY, dbms_sql.v7);
      dbms_sql.define_column(I_CURSOR, 1, I_COUNT);
      I_VOID := dbms_sql.execute(I_CURSOR);
      I_VOID := dbms_sql.fetch_rows(I_CURSOR);

      dbms_sql.column_value(I_CURSOR, 1, I_COUNT);
      dbms_sql.close_cursor(I_CURSOR);
      return I_COUNT;
   exception
      when others then
         return -1;
   end;

--------------------------------------------------------------------------------
-- Name:        LoadDomainValues
--
-- Description: Load values into Domain Record from the specified Ref Codes
--              Table
--
-- Parameters:  P_REF_CODE_TABLE The name of the Ref Codes Table
--              P_DOMAIN         The name of the domain
--              P_DVREC          Record defining Domain details to be loaded
--
--------------------------------------------------------------------------------
   procedure LoadDomainValues(
             P_REF_CODE_TABLE in varchar2,
             P_DOMAIN in varchar2,
             P_DVREC in out typDVRecord) is
      I_CURSOR      integer;

      I_VOID        integer;
      I_ROWS        integer := 0;
      I_SQL         varchar2(256);
      L_VALUE       varchar2(240);
      L_MEANING     varchar2(240);
      L_ABBR        varchar2(240);
   begin
      I_SQL := 'SELECT RV_LOW_VALUE, RV_MEANING, RV_ABBREVIATION
                FROM   ' || P_REF_CODE_TABLE ||
              ' WHERE  RV_DOMAIN = ''' || P_DOMAIN ||
              ''' ORDER BY ';
      if P_DVREC.UseMeanings then
         I_SQL := I_SQL || 'RV_MEANING';
      else
         I_SQL := I_SQL || 'RV_LOW_VALUE';
      end if;
      I_CURSOR := dbms_sql.open_cursor;
      dbms_sql.parse(I_CURSOR, I_SQL, dbms_sql.v7);
      dbms_sql.define_column(I_CURSOR, 1, L_VALUE, 240);
      dbms_sql.define_column(I_CURSOR, 2, L_MEANING, 240);
      dbms_sql.define_column(I_CURSOR, 3, L_ABBR, 240);
      I_VOID := dbms_sql.execute(I_CURSOR);
      while (dbms_sql.fetch_rows(I_CURSOR) <> 0) loop

         I_ROWS := I_ROWS + 1;
         dbms_sql.column_value(I_CURSOR, 1, L_VALUE);
         dbms_sql.column_value(I_CURSOR, 2, L_MEANING);
         dbms_sql.column_value(I_CURSOR, 3, L_ABBR);
         P_DVREC.Vals(I_ROWS) := L_VALUE;
         P_DVREC.Meanings(I_ROWS) := L_MEANING;
         P_DVREC.Abbreviations(I_ROWS) := L_ABBR;
      end loop;
      P_DVREC.NumOfVV := I_ROWS;
      dbms_sql.close_cursor(I_CURSOR);
   exception
      when others then
         raise_application_error(-20000, 'WSGL.LoadDomainValues<br>'||SQLERRM);
   end;

--------------------------------------------------------------------------------
-- Name:        ValidDomainValue
--
-- Description: Tests whether the given value is valid for the specified domain
--
-- Parameters:  P_DVREC      Record defining Domain details
--              P_VALUE      The value to test
--                           - If an abbreviation or meaning was entered,
--                             this is replaced by the value. If the value
--                             entered was HTML escaped, it is replaced with
--                             the non-escaped value.
--
-- Returns:     True if valid value
--              False otherwise
--
--------------------------------------------------------------------------------
   function ValidDomainValue(
            P_DVREC in typDVRecord,
            P_VALUE in out varchar2) return boolean is
      I_LOOP integer;
   begin
      if not P_DVREC.Initialised then
         raise_application_error(-20000, 'WSGL.ValidDomainValue<br>'||MsgGetText(201,WSGLM.MSG201_DV_INIT_ERR));
      end if;
--      if P_VALUE is null and P_DVREC.ColOptional then
      if P_VALUE is null then
         return true;
      end if;

      for I_LOOP in 1..P_DVREC.NumOfVV loop
          if ( (P_VALUE = P_DVREC.Vals(I_LOOP)) or
               (P_VALUE = EscapeItem(P_DVREC.Vals(I_LOOP)))
             )
          then
              P_VALUE := P_DVREC.Vals(I_LOOP);
              return true;
          end if;
      end loop;

      if (P_DVREC.UseMeanings)
      then
          for I_LOOP in 1..P_DVREC.NumOfVV loop
              if ( (P_VALUE = P_DVREC.Meanings(I_LOOP)) or
                   (P_VALUE = EscapeItem(P_DVREC.Meanings(I_LOOP)))
                 )
              then
                    P_VALUE := P_DVREC.Vals(I_LOOP);
                  return true;
              end if;
          end loop;
      end if;

      for I_LOOP in 1..P_DVREC.NumOfVV loop
         if ( (P_VALUE = P_DVREC.Abbreviations(I_LOOP)) or
              (P_VALUE = EscapeItem(P_DVREC.Abbreviations(I_LOOP)))
            )
         then
              P_VALUE := P_DVREC.Vals(I_LOOP);
            return true;
         end if;
      end loop;

      return false;
   exception
      when others then
         raise_application_error(-20000, 'WSGL.ValidDomainValue<br>'||SQLERRM);
   end;

--------------------------------------------------------------------------------
-- Name:        DomainMeaning
--
-- Description: Returns the meaning of a value in a domain
--
-- Parameters:  P_DVREC      Record defining Domain details
--              P_VALUE      The value
--
-- Returns:     The associated meaning of the domain value if found
--              The value, otherwise
--
--------------------------------------------------------------------------------
   function DomainMeaning(
            P_DVREC in typDVRecord,
            P_VALUE in varchar2) return varchar2 is
      I_LOOP integer;
   begin
      if not P_DVREC.Initialised then
         raise_application_error(-20000, 'WSGL.DomainMeaning<br>'||MsgGetText(201,WSGLM.MSG201_DV_INIT_ERR));
      end if;
      if P_DVREC.UseMeanings then
         for I_LOOP in 1..P_DVREC.NumOfVV loop
            if P_VALUE = P_DVREC.Vals(I_LOOP) then
               return P_DVREC.Meanings(I_LOOP);
            end if;
         end loop;
      end if;
      return P_VALUE;
   exception
      when others then
         raise_application_error(-20000, 'WSGL.DomainMeaning<br>'||SQLERRM);
   end;

--------------------------------------------------------------------------------
-- Name:        DomainValue
--
-- Description: Returns the value of a domain whose meaning is given
--
-- Parameters:  P_DVREC      Record defining Domain details
--              P_MEANING    The meaning
--
-- Returns:     The associated value of the domain if found
--              The meaning, otherwise
--
--------------------------------------------------------------------------------
   function DomainValue(
            P_DVREC in typDVRecord,
            P_MEANING in varchar2) return varchar2 is
      I_LOOP integer;
   begin
      if not P_DVREC.Initialised then
         raise_application_error(-20000, 'WSGL.DomainValue<br>'||MsgGetText(201,WSGLM.MSG201_DV_INIT_ERR));
      end if;
      if P_DVREC.UseMeanings then
         for I_LOOP in 1..P_DVREC.NumOfVV loop
            if P_MEANING = P_DVREC.Meanings(I_LOOP) then
               return P_DVREC.Vals(I_LOOP);
            end if;
         end loop;
      end if;
      return P_MEANING;
   exception
      when others then
         raise_application_error(-20000, 'WSGL.DomainValue<br>'||SQLERRM);
   end;


--------------------------------------------------------------------------------
-- Name:        DomainValue
--
-- Description: Returns the value of a domain whose meaning is given
--
-- Parameters:  P_DVREC      Record defining Domain details
--              P_MEANING    The meaning
--
-- Returns:     The associated value of the domain if found
--              The meaning, otherwise
--
--------------------------------------------------------------------------------
function DomainValue(
         P_DVREC in typDVRecord,
         P_MEANING in typString240Table) return typString240Table is
   ret_array typString240Table;
   i number := 1;
begin
   while true loop
      ret_array(i) := DomainValue(P_DVREC, P_MEANING(i));
      i := i+1;
   end loop;
exception
   when no_data_found then
      return ret_array;
   when others then
      raise_application_error(-20000, 'WSGL.DomainValue2<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        BuildDVControl
--
-- Description: Builds the HTML required to render the given domain
--
-- Parameters:  P_DVREC      Record defining Domain details
--              P_CTL_STYLE  CTL_READONLY - Read only
--                           CTL_UPDATABLE - Updatable
--                           CTL_INSERTABLE - Insertable
--                           CTL_QUERY - Query
--              P_CURR_VAL   The current value of the column
--
-- Returns:     The HTML required to render the given domain
--
--------------------------------------------------------------------------------
   function BuildDVControl(
            P_DVREC       in typDVRecord,
            P_CTL_STYLE   in number,
            P_CURR_VAL    in varchar2,
            p_onclick     in boolean default false,
            p_onchange    in boolean default false,
            p_onblur      in boolean default false,
            p_onfocus     in boolean default false,
            p_onselect    in boolean default false,
            p_row         in number default null,
            p_multirow    in boolean default false,
            p_alwaysquery in boolean default false,
            p_img_path    in varchar2 default '/') return varchar2 is
      L_RET_VALUE     varchar2(20000) := null;
      L_DISPLAY_VAL   varchar2(200);
      l_events        varchar2(1000)  := null;
      l_radio_options number          := 0;
      p_rownum_txt    varchar2(30);
      l_curr_val      varchar2(32767) := P_CURR_VAL;
      l_img_text      varchar2(1000)  := null;
      l_onclick_text  varchar2(100)   := null;
      l_formname      varchar2(15)    := null;
      l_valid_option  boolean         := true;
   begin
      if p_row is not null then
         p_rownum_txt := ', '||to_char(p_row - 1);
      end if;
      if (P_CTL_STYLE = CTL_UPDATABLE or P_CTL_STYLE = CTL_INSERTABLE) then
         -- Cannot just automatically add on onclick event handling.
         -- In certain cases the onclick event handler needs to be combined with some
         -- other code.
         if ((P_DVREC.ControlType = DV_RADIO or P_DVREC.ControlType = DV_RADIO_ACROSS) and (p_multirow)) then
            if p_onclick then
              l_onclick_text := ''||P_DVREC.ColAlias||'_OnClick(this'||p_rownum_txt||');';
            end if;
            l_onclick_text := l_onclick_text ||' return false;';
         else
            if p_onclick then
              l_events := l_events || ' onClick="return '||P_DVREC.ColAlias||'_OnClick(this'||p_rownum_txt||');"';
            end if;
         end if;
         if p_onchange then
            l_events := l_events || ' onChange="return '||P_DVREC.ColAlias||'_OnChange(this'||p_rownum_txt||');"';
         end if;
         if p_onblur then
            l_events := l_events || ' onBlur="return '||P_DVREC.ColAlias||'_OnBlur(this'||p_rownum_txt||');"';
         end if;
         if p_onfocus then
            l_events := l_events || ' onFocus="return '||P_DVREC.ColAlias||'_OnFocus(this'||p_rownum_txt||');"';
         end if;
         if p_onselect then
            l_events := l_events || ' onSelect="return '||P_DVREC.ColAlias||'_OnSelect(this'||p_rownum_txt||');"';
         end if;
      end if;
      if not P_DVREC.Initialised then
         raise_application_error(-20000, 'WSGL.BuildDVControl<br>'||MsgGetText(201,WSGLM.MSG201_DV_INIT_ERR));
      end if;
      if P_DVREC.UseMeanings then
         L_DISPLAY_VAL := DomainMeaning(P_DVREC, P_CURR_VAL);
      else
         L_DISPLAY_VAL := P_CURR_VAL;
      end if;
      if P_CTL_STYLE = CTL_READONLY then
         return L_DISPLAY_VAL;
      end if;
      if P_DVREC.ControlType = DV_TEXT then
         if (P_CTL_STYLE = CTL_UPDATABLE or P_CTL_STYLE = CTL_INSERTABLE) then
            L_RET_VALUE := htf.formText('P_'||P_DVREC.ColAlias,
                                         to_char(P_DVREC.DispWidth),
                                         to_char(P_DVREC.MaxWidth),
                                         replace(L_DISPLAY_VAL,'"','&quot;'),
                                         cattributes=>l_events);
         else
            L_RET_VALUE := htf.formText('P_'||P_DVREC.ColAlias,
                                         to_char(P_DVREC.DispWidth));
         end if;
     elsif P_DVREC.ControlType = DV_LIST then
         if ( not ValidDomainValue(P_DVREC, l_curr_val)) or ((P_CURR_VAL is null) and (not P_DVREC.ColOptional)) then
            l_valid_option := false;
         end if;
         if P_CTL_STYLE = CTL_QUERY and (P_DVREC.DispHeight <> 1) then
            L_RET_VALUE := htf.formSelectOpen('P_'||P_DVREC.ColAlias,
                                              nsize=>to_char(P_DVREC.DispHeight),
                                              cattributes=>'MULTIPLE CLASS = cgdvlist'||l_events);
         else
            L_RET_VALUE := htf.formSelectOpen('P_'||P_DVREC.ColAlias,
                                              nsize=>to_char(P_DVREC.DispHeight),
                                              cattributes=>'CLASS = cgdvlist'||l_events);
         end if;
         if (P_CTL_STYLE = CTL_UPDATABLE or ((P_CTL_STYLE = CTL_INSERTABLE) and (P_CURR_VAL is not null))) then
            if ( not l_valid_option ) then
               L_RET_VALUE := L_RET_VALUE || htf.formSelectOption(MsgGetText(28,WSGLM.CAP028_INVALID_VAL), 'SELECTED',
                                             'VALUE="'||MsgGetText(28,WSGLM.CAP028_INVALID_VAL)||'"');
            end if;
         end if;
         if (P_CTL_STYLE = CTL_UPDATABLE or P_CTL_STYLE = CTL_INSERTABLE) and P_DVREC.ColOptional then
            if P_CURR_VAL is null then
               L_RET_VALUE := L_RET_VALUE || htf.formSelectOption(' ', 'SELECTED');
            else
               L_RET_VALUE := L_RET_VALUE || htf.formSelectOption(' ');
            end if;
         end if;
         if P_CTL_STYLE = CTL_QUERY and not p_alwaysquery then
            L_RET_VALUE := L_RET_VALUE || htf.formSelectOption(' ', 'SELECTED');
         end if;
         for I_LOOP in 1..P_DVREC.NumOfVV loop
            if P_DVREC.UseMeanings then
               L_DISPLAY_VAL := EscapeItem(P_DVREC.Meanings(I_LOOP));
            else
               L_DISPLAY_VAL := EscapeItem(P_DVREC.Vals(I_LOOP));
            end if;
            if (P_DVREC.Vals(I_LOOP) = DomainValue(P_DVREC, l_curr_val)) or
               ((I_LOOP = 1) and (P_CTL_STYLE = CTL_INSERTABLE) and (P_CURR_VAL is null) and (not P_DVREC.ColOptional)) then
               L_RET_VALUE := L_RET_VALUE || htf.formSelectOption(L_DISPLAY_VAL, 'SELECTED',
                                             'VALUE="'||EscapeItem(P_DVREC.Vals(I_LOOP))||'"');
            else
               L_RET_VALUE := L_RET_VALUE || htf.formSelectOption(L_DISPLAY_VAL, NULL,
                                             'VALUE="'||EscapeItem(P_DVREC.Vals(I_LOOP))||'"');
            end if;
         end loop;
         if P_CTL_STYLE = CTL_QUERY and P_DVREC.ColOptional then
            L_RET_VALUE := L_RET_VALUE || htf.formSelectOption(MsgGetText(1,WSGLM.CAP001_UNKNOWN));
         end if;
         L_RET_VALUE := L_RET_VALUE || htf.formSelectClose;
     elsif (P_DVREC.ControlType = DV_CHECK) and ((P_CTL_STYLE <> CTL_QUERY) or p_alwaysquery) then
        if (P_CURR_VAL = P_DVREC.Vals(1)) or (P_CURR_VAL = EscapeItem(P_DVREC.Vals(1))) then
           if p_row is null then
              L_RET_VALUE := htf.formCheckbox('P_'||P_DVREC.ColAlias, EscapeItem(P_DVREC.Vals(1)), 'CHECKED', cattributes=>l_events);
           else
              L_RET_VALUE := htf.formCheckbox('P_'||P_DVREC.ColAlias, to_char( p_row ), 'CHECKED', cattributes=>l_events);
           end if;
        else
           if p_row is null then
              L_RET_VALUE := htf.formCheckbox('P_'||P_DVREC.ColAlias, EscapeItem(P_DVREC.Vals(1)), cattributes=>l_events);
           else
              L_RET_VALUE := htf.formCheckbox('P_'||P_DVREC.ColAlias, to_char( p_row ), cattributes=>l_events);
           end if;
        end if;
     elsif (((P_DVREC.ControlType = DV_RADIO or P_DVREC.ControlType = DV_RADIO_ACROSS) and not p_multirow) or
            ((P_DVREC.ControlType = DV_CHECK) and (P_CTL_STYLE = CTL_QUERY))
           ) then
         if ( not ValidDomainValue(P_DVREC, l_curr_val)) or ((P_CURR_VAL is null) and (not P_DVREC.ColOptional)) then
            l_valid_option := false;
         end if;
         for I_LOOP in 1..P_DVREC.NumOfVV loop
            if P_DVREC.UseMeanings or P_DVREC.Vals(I_LOOP) is null then
               L_DISPLAY_VAL := EscapeItem(P_DVREC.Meanings(I_LOOP));
            else
               L_DISPLAY_VAL := EscapeItem(P_DVREC.Vals(I_LOOP));
            end if;
            if ((P_DVREC.Vals(I_LOOP) = DomainValue(P_DVREC, l_curr_val)) or
                ( (not P_DVREC.ColOptional) and (P_CURR_VAL is null) and
                (P_CTL_STYLE = CTL_INSERTABLE) and (I_LOOP = 1))
               ) then
               L_RET_VALUE := L_RET_VALUE ||
                               htf.formRadio('P_'||P_DVREC.ColAlias,
                                             EscapeItem(P_DVREC.Vals(I_LOOP)),
                                             'CHECKED',
                                              cattributes=>l_events);
            else
               L_RET_VALUE := L_RET_VALUE ||
                               htf.formRadio('P_'||P_DVREC.ColAlias,
                                             EscapeItem(P_DVREC.Vals(I_LOOP)),
                                             cattributes=>l_events);
            end if;
            L_RET_VALUE := L_RET_VALUE || ' ' || L_DISPLAY_VAL;
            if I_LOOP <> P_DVREC.NumOfVV then
              if LayStyle = LAYOUT_TABLE and P_DVREC.ControlType != DV_RADIO_ACROSS then
                  L_RET_VALUE := L_RET_VALUE || htf.nl;
               else
                  L_RET_VALUE := L_RET_VALUE || ' ';
               end if;
            end if;
         end loop;

         if (P_DVREC.ColOptional) then
            if LayStyle = LAYOUT_TABLE and P_DVREC.ControlType != DV_RADIO_ACROSS then
               L_RET_VALUE := L_RET_VALUE || htf.nl;
            else
               L_RET_VALUE := L_RET_VALUE || ' ';
            end if;
            if P_CURR_VAL is null and (P_CTL_STYLE = CTL_UPDATABLE or P_CTL_STYLE = CTL_INSERTABLE) then
               L_RET_VALUE := L_RET_VALUE ||
                               htf.formRadio('P_'||P_DVREC.ColAlias,
                                             null,
                                             'CHECKED',
                                             cattributes=>l_events);
            elsif (P_CTL_STYLE = CTL_UPDATABLE or P_CTL_STYLE = CTL_INSERTABLE) then
               L_RET_VALUE := L_RET_VALUE ||
                               htf.formRadio('P_'||P_DVREC.ColAlias,
                                             null,
                                             cattributes=>l_events);
            else
               L_RET_VALUE := L_RET_VALUE ||
                               htf.formRadio('P_'||P_DVREC.ColAlias,
                                             MsgGetText(1,WSGLM.CAP001_UNKNOWN),
                                             cattributes=>l_events);
            end if;
            L_RET_VALUE := L_RET_VALUE || ' ' || MsgGetText(1,WSGLM.CAP001_UNKNOWN);

         end if;
         if (P_CTL_STYLE = CTL_UPDATABLE or ((P_CTL_STYLE = CTL_INSERTABLE) and (P_CURR_VAL is not null))) then
            if ( not l_valid_option ) then
               if LayStyle = LAYOUT_TABLE and P_DVREC.ControlType != DV_RADIO_ACROSS then
                  L_RET_VALUE := L_RET_VALUE || htf.nl;
               else
                  L_RET_VALUE := L_RET_VALUE || ' ';
               end if;
               L_RET_VALUE := L_RET_VALUE ||
                               htf.formRadio('P_'||P_DVREC.ColAlias,
                                             MsgGetText(28,WSGLM.CAP028_INVALID_VAL),
                                             'CHECKED',
                                             cattributes=>l_events);
              L_RET_VALUE := L_RET_VALUE || ' '|| MsgGetText(28,WSGLM.CAP028_INVALID_VAL);
            end if;
         end if;
      elsif ((P_DVREC.ControlType = DV_RADIO or P_DVREC.ControlType = DV_RADIO_ACROSS) and (p_multirow)) then
         if ( not ValidDomainValue(P_DVREC, l_curr_val)) or ((P_CURR_VAL is null) and (not P_DVREC.ColOptional)) then
            l_valid_option := false;
         end if;
         if (P_CTL_STYLE = CTL_INSERTABLE) and (P_CURR_VAL is null) and not (P_DVREC.ColOptional) then
            L_RET_VALUE := L_RET_VALUE || htf.formHidden('P_'||P_DVREC.ColAlias, (P_DVREC.Vals(P_DVREC.Vals.first)));
         else
            L_RET_VALUE := L_RET_VALUE ||
                           htf.formHidden('P_'||P_DVREC.ColAlias, (l_curr_val));
         end if;
         if P_CTL_STYLE = CTL_UPDATABLE then
            l_formname := 'VForm';
         else
            l_formname := 'IForm';
         end if;
         l_radio_options := P_DVREC.NumOfVV;
         if (P_DVREC.ColOptional and (P_CTL_STYLE <> CTL_QUERY or not p_alwaysquery))then
            l_radio_options := l_radio_options + 1;
         end if;
         if (P_CTL_STYLE = CTL_UPDATABLE or ((P_CTL_STYLE = CTL_INSERTABLE) and (P_CURR_VAL is not null))) then
            if ( not l_valid_option ) then
               l_radio_options := l_radio_options + 1;
            end if;
         end if;
         if (P_DVREC.ControlType = DV_RADIO_ACROSS) then
            L_RET_VALUE := L_RET_VALUE || '<nobr>';
         end if;
         if p_row = 1 then
            L_RET_VALUE := L_RET_VALUE || '<SCRIPT>var RADIO_P_' || P_DVREC.ColAlias || '_option = new Array();</SCRIPT>' ;
         end if;
         L_RET_VALUE := L_RET_VALUE || '<SCRIPT>var RADIO_P_' || P_DVREC.ColAlias || (p_row - 1) || '_values = new Array();</SCRIPT>' ;
         for I_LOOP in 1..P_DVREC.NumOfVV loop
            if P_DVREC.UseMeanings or P_DVREC.Vals(I_LOOP) is null then
               L_DISPLAY_VAL := (P_DVREC.Meanings(I_LOOP));
            else
               L_DISPLAY_VAL := (P_DVREC.Vals(I_LOOP));
            end if;
            if ((P_DVREC.Vals(I_LOOP) = DomainValue(P_DVREC, l_curr_val)) or
                ( (P_CTL_STYLE = CTL_QUERY) and p_alwaysquery and
                  (P_CURR_VAL is null) and (I_LOOP = 1) )                 or
                ( (not P_DVREC.ColOptional) and (P_CURR_VAL is null) and
                  (P_CTL_STYLE = CTL_INSERTABLE) and (I_LOOP = 1))
               ) then
               l_img_text := WSGL.InitSysImage(WSGL.IMG_TYPE_RADIO,
                                               p_img_path,
                                               'RADIO_P_'||P_DVREC.ColAlias||to_char(p_row - 1),
                                               'Y');
               L_RET_VALUE := L_RET_VALUE || '<SCRIPT>RADIO_P_' || P_DVREC.ColAlias || '_option[' || to_char(p_row - 1) || '] = ' || I_LOOP || ';</SCRIPT>' ;
            else
               l_img_text := WSGL.InitSysImage(WSGL.IMG_TYPE_RADIO,
                                               p_img_path,
                                               'RADIO_P_'||P_DVREC.ColAlias||to_char(p_row - 1),
                                               'N');
            end if;
            L_RET_VALUE := L_RET_VALUE || '<SCRIPT>RADIO_P_' || P_DVREC.ColAlias || (p_row - 1) || '_values[' || (I_LOOP - 1) || '] = "' || EscapeItem(P_DVREC.Vals(I_LOOP)) || '";</SCRIPT>' ;

            L_RET_VALUE := L_RET_VALUE || '<SCRIPT>document.write(''<a href="" name="RADIO_P_'||P_DVREC.ColAlias
                                       || '" onMouseOver="window.status=&quot;&quot;; return true;" onClick="JSLRadioChange( &quot;'||l_formname||'&quot;, &quot;RADIO_P_'||P_DVREC.ColAlias||'&quot;,&quot;'
                                       || replace(P_DVREC.Vals(I_LOOP), '"','\\&quot;') || '&quot;, '  || to_char(p_row - 1) || ', '             || I_LOOP ||', '
                                       || l_radio_options      || ', &quot;' || p_img_path         || '&quot; );'
                                       || l_onclick_text       || '" '       || l_events           ||'>'
                                       || l_img_text           || '</a>''); </SCRIPT>' ;

            L_RET_VALUE := L_RET_VALUE || ' ' || L_DISPLAY_VAL;
            if I_LOOP <> P_DVREC.NumOfVV then
               if LayStyle = LAYOUT_TABLE and P_DVREC.ControlType != DV_RADIO_ACROSS then
                  L_RET_VALUE := L_RET_VALUE || htf.nl;
               else
                  L_RET_VALUE := L_RET_VALUE || ' ';
               end if;
            end if;
         end loop;
         if (P_DVREC.ColOptional and (P_CTL_STYLE <> CTL_QUERY or not p_alwaysquery))then
            if LayStyle = LAYOUT_TABLE and P_DVREC.ControlType != DV_RADIO_ACROSS then
               L_RET_VALUE := L_RET_VALUE || htf.nl;
            else
               L_RET_VALUE := L_RET_VALUE || ' ';
            end if;
            if P_CURR_VAL is null and (P_CTL_STYLE = CTL_UPDATABLE or P_CTL_STYLE = CTL_INSERTABLE) then
               l_img_text := WSGL.InitSysImage(WSGL.IMG_TYPE_RADIO,
                                               p_img_path,
                                               'RADIO_P_'||P_DVREC.ColAlias||to_char(p_row - 1),
                                               'Y');
               L_RET_VALUE := L_RET_VALUE || '<SCRIPT>RADIO_P_' || P_DVREC.ColAlias || '_option[' || to_char(p_row - 1) || '] = ' || l_radio_options || ';</SCRIPT>' ;

            elsif (P_CTL_STYLE = CTL_UPDATABLE or P_CTL_STYLE = CTL_INSERTABLE) then
               l_img_text := WSGL.InitSysImage(WSGL.IMG_TYPE_RADIO,
                                              p_img_path,
                                              'RADIO_P_'||P_DVREC.ColAlias||to_char(p_row - 1),
                                              'N');
            end if;

            L_RET_VALUE := L_RET_VALUE || '<SCRIPT>RADIO_P_' || P_DVREC.ColAlias || (p_row - 1) || '_values[' || to_char(P_DVREC.NumOfVV + 1) || '] = "' || MsgGetText(1,WSGLM.CAP001_UNKNOWN) || '";</SCRIPT>' ;

            L_RET_VALUE := L_RET_VALUE || '<SCRIPT>document.write(''<a href="" name="RADIO_P_'||P_DVREC.ColAlias
                                       || '" onMouseOver="status=&quot;&quot;; return true;" onClick="JSLRadioChange( &quot;'||l_formname||'&quot;, &quot;RADIO_P_'||P_DVREC.ColAlias||'&quot;,&quot;'
                                       || null            || '&quot;, '  || to_char(p_row - 1) || ', '           || to_char(P_DVREC.NumOfVV + 1) ||', '
                                       || l_radio_options || ', &quot;' || p_img_path         || '&quot; );'
                                       || l_onclick_text  || '" '       || l_events           ||'>'
                                       || l_img_text      || '</a>''); </SCRIPT>' ;


            L_RET_VALUE := L_RET_VALUE || ' ' || MsgGetText(1,WSGLM.CAP001_UNKNOWN);
         end if;
         if (P_CTL_STYLE = CTL_UPDATABLE or ((P_CTL_STYLE = CTL_INSERTABLE) and (P_CURR_VAL is not null))) then
            if ( not l_valid_option ) then
               if LayStyle = LAYOUT_TABLE and P_DVREC.ControlType != DV_RADIO_ACROSS then
                  L_RET_VALUE := L_RET_VALUE || htf.nl;
               else
                  L_RET_VALUE := L_RET_VALUE || ' ';
               end if;
               l_img_text := WSGL.InitSysImage(WSGL.IMG_TYPE_RADIO,
                                               p_img_path,
                                               'RADIO_P_'||P_DVREC.ColAlias||to_char(p_row - 1),
                                               'Y');
               L_RET_VALUE := L_RET_VALUE || '<SCRIPT>RADIO_P_' || P_DVREC.ColAlias || '_option[' || to_char(p_row - 1) || '] = ' || to_char(l_radio_options) || ';</SCRIPT>' ;

               L_RET_VALUE := L_RET_VALUE || '<SCRIPT>RADIO_P_' || P_DVREC.ColAlias || (p_row - 1) || '_values[' || to_char(P_DVREC.NumOfVV + 1) || '] = "' || MsgGetText(28,WSGLM.CAP028_INVALID_VAL) || '";</SCRIPT>' ;

               L_RET_VALUE := L_RET_VALUE || '<SCRIPT>document.write(''<a href="" name="RADIO_P_'||P_DVREC.ColAlias
                                          || '" onMouseOver="status=&quot;&quot;; return true;" onClick="JSLRadioChange( &quot;'||l_formname||'&quot;, &quot;RADIO_P_'||P_DVREC.ColAlias||'&quot;,&quot;'
                                          || MsgGetText(28,WSGLM.CAP028_INVALID_VAL) || '&quot;, '  || to_char(p_row - 1) || ', '           || to_char(l_radio_options) ||', '
                                          || l_radio_options || ', &quot;' || p_img_path         || '&quot; );'
                                          || l_onclick_text  || '" '       || l_events           ||'>'
                                          || l_img_text      || '</a>''); </SCRIPT>' ;

               L_RET_VALUE := L_RET_VALUE || ' '|| MsgGetText(28,WSGLM.CAP028_INVALID_VAL);
            end if;
         end if;
         if (P_DVREC.ControlType = DV_RADIO_ACROSS) then
            L_RET_VALUE := L_RET_VALUE || '</nobr>';
         end if;
      else
         raise_application_error(-20000, 'WSGL.BuildDVControl<br>'||MsgGetText(202,WSGLM.MSG202_DV_CTL_ERR));
         return '';
      end if;
      return L_RET_VALUE;
   exception
      when others then
         raise_application_error(-20000, 'WSGL.BuildDVControl<br>'||SQLERRM);
   end;

--------------------------------------------------------------------------------
-- Name:        BuildTextControl
--
-- Description: Create a text control
--
-- Parameters:  p_alias           IN The alias of the control
--              p_size            IN The display width
--              p_height          IN The height (if > 1, then text area)
--              p_maxlength       IN The maximum length of data
--              p_value           IN Current value
--              p_onclick         IN Is an OnClick event required
--              p_onchange        IN Is an OnChange event required
--              p_onblur          IN Is an OnBlur event required
--              p_onfocus         IN Is an OnFocus event required
--              p_onselect        IN Is an OnSelect event required
--              p_cal_but_text    IN Text for Calendar button
--              p_cal_date_format IN Date format for Calendar button
--              p_form            IN Name of the calling form (only required
--                                   when a Calendar link is to be created)
--              p_row             IN For multirow forms, the current form. Used
--                                   to create CAL button call.
--
--------------------------------------------------------------------------------
function BuildTextControl(p_alias in varchar2,
                          p_size in varchar2 default null,
                          p_height in varchar2 default null,
                          p_maxlength in varchar2 default null,
                          p_value in varchar2 default null,
                          p_onclick in boolean default false,
                          p_onchange in boolean default false,
                          p_onblur in boolean default false,
                          p_onfocus in boolean default false,
                          p_onselect in boolean default false,
                          p_cal_but_text    in varchar2 default null,
                          p_cal_date_format in varchar2 default null,
                          p_form in varchar2 default 'forms[0]',
                          p_row in number default null,
                          p_img_path in varchar2 default '/',
                          p_cal_prompt in varchar2 default null) return varchar2 is

   l_name       varchar2(30) := 'P_'||p_alias;
   l_events     varchar2(1000) := null;
   l_rows       integer := to_number(p_height);
   l_cols       integer := to_number(p_size);
   p_rownum_txt varchar2(30);
begin
   if p_row is not null then
      p_rownum_txt := ', '||to_char(p_row - 1);
   end if;
   if p_onclick then
      l_events := l_events || ' onClick="return '||p_alias||'_OnClick(this'||p_rownum_txt||')"';
   end if;
   if p_onchange then
      l_events := l_events || ' onChange="return '||p_alias||'_OnChange(this'||p_rownum_txt||')"';
   end if;
   if p_onblur then
      l_events := l_events || ' onBlur="return '||p_alias||'_OnBlur(this'||p_rownum_txt||')"';
   end if;
   if p_onfocus then
      l_events := l_events || ' onFocus="return '||p_alias||'_OnFocus(this'||p_rownum_txt||')"';
   end if;
   if p_onselect then
      l_events := l_events || ' onSelect="return '||p_alias||'_OnSelect(this'||p_rownum_txt||')"';
   end if;
   if p_height = '1' then

      if p_cal_but_text is null then

        return htf.formText(cname=>l_name, csize=>p_size, cmaxlength=>p_maxlength,
                            cvalue=>replace(p_value,'"','&quot;'), cattributes=>l_events);

      else

        return htf.formText(cname=>l_name, csize=>p_size, cmaxlength=>p_maxlength,
                            cvalue=>replace(p_value,'"','&quot;'), cattributes=>l_events) || ' ' ||
               WSGJSL.CALButton (l_name, p_cal_but_text, p_cal_date_format, p_form, p_row - 1, p_img_path=>p_img_path, p_field_prompt=>p_cal_prompt);

      end if;  -- p_cal_but_text ...

   else
      return htf.formTextareaOpen2(cname=>l_name, nrows=>l_rows, ncolumns=>l_cols, cwrap=>'VIRTUAL', cattributes=>l_events) ||
             replace(p_value,'"','&quot;') ||
             htf.formTextareaClose;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.BuildTextControl<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        BuildQueryControl
--
-- Description: Create text control(s) for query form
--
-- Parameters:  p_alias           IN The alias of the control
--              p_size            IN The display width
--              p_onclick         IN Is an OnClick event required
--              p_onchange        IN Is an OnChange event required
--              p_onblur          IN Is an OnBlur event required
--              p_onfocus         IN Is an OnFocus event required
--              p_onselect        IN Is an OnSelect event required
--              p_cal_but_text    IN Text for Calendar button
--              p_cal_date_format IN Date format for Calendar button
--              p_form            IN Name of the calling form (only required
--                                   when a Calendar link is to be created)
--
--------------------------------------------------------------------------------
function BuildQueryControl(
         p_alias in varchar2,
         p_size in varchar2,
         p_range in boolean,
         p_onclick in boolean,
         p_onchange in boolean,
         p_onblur in boolean,
         p_onfocus in boolean,
         p_onselect in boolean,
         p_cal_but_text    in varchar2 default null,
         p_cal_date_format in varchar2 default null,
         p_form in varchar2 default 'forms[0]',
         p_maxlength in varchar2 default null,
         p_cal_prompt in varchar2 default null) return varchar2 is

   l_name1   varchar2(30) := 'P_'||p_alias;
   l_name2   varchar2(30) := 'U_'||p_alias;
   l_events  varchar2(1000) := null;
   l_maxlength varchar2(6) := p_maxlength;
begin
   if p_onclick then
      l_events := l_events || ' onClick="return '||p_alias||'_OnClick(this)"';
   end if;
   if p_onchange then
      l_events := l_events || ' onChange="return '||p_alias||'_OnChange(this)"';
   end if;
   if p_onblur then
      l_events := l_events || ' onBlur="return '||p_alias||'_OnBlur(this)"';
   end if;
   if p_onfocus then
      l_events := l_events || ' onFocus="return '||p_alias||'_OnFocus(this)"';
   end if;
   if p_onselect then
      l_events := l_events || ' onSelect="return '||p_alias||'_OnSelect(this)"';
   end if;
   if l_maxlength is null then
      l_maxlength := p_size;
   end if;
   if not p_range then
      if p_cal_but_text is null then
         return htf.formText(cname=>l_name1, csize=>p_size, cmaxlength=>l_maxlength, cattributes=>l_events);
      else
         return htf.formText(cname=>l_name1, csize=>p_size, cmaxlength=>l_maxlength, cattributes=>l_events) || ' ' ||
                WSGJSL.CALButton (l_name1, p_cal_but_text, p_cal_date_format, p_form, p_field_prompt=>p_cal_prompt);
      end if;
   else

      if p_cal_but_text is null then

        return htf.formText(cname=>l_name1, csize=>p_size, cmaxlength=>l_maxlength, cattributes=>l_events) || ' ' ||
               htf.bold(MsgGetText(119,WSGLM.DSP119_RANGE_TO)) || ' ' ||
               htf.formText(cname=>l_name2, csize=>p_size, cmaxlength=>l_maxlength, cattributes=>l_events);

      else

        -- It's a range of date fields, so create a calendar link for each field

        return htf.formText(cname=>l_name1, csize=>p_size, cmaxlength=>l_maxlength, cattributes=>l_events)     || ' ' ||
               WSGJSL.CALButton (l_name1, p_cal_but_text, p_cal_date_format, p_form, p_field_prompt=>p_cal_prompt)  || ' ' ||
               htf.bold(MsgGetText(119,WSGLM.DSP119_RANGE_TO))                        || ' ' ||
               htf.formText(cname=>l_name2, csize=>p_size, cmaxlength=>l_maxlength, cattributes=>l_events)     || ' ' ||
               WSGJSL.CALButton (l_name2, p_cal_but_text, p_cal_date_format, p_form, p_field_prompt=>p_cal_prompt);

      end if;  -- p_cal_but_text ...

   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.BuildQueryControl<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        BuildDerivationControl
--
-- Description: Create a text control for displaying a derivation expression if
--              JavaScript is supported, otherwise, just display the value
--
-- Parameters:  p_name      IN The name of the control
--              p_size      IN The display width
--              p_value     IN Current value
--
--------------------------------------------------------------------------------
function BuildDerivationControl(p_name in varchar2,
                                p_size in varchar2,
                                p_value in varchar2,
                                p_onclick in boolean,
                                p_onblur in boolean,
                                p_onfocus in boolean,
                                p_onselect in boolean,
                                p_row in number) return varchar2 is
   l_events  varchar2(1000);
   l_rownum_txt varchar2(30);
begin
   if p_row is not null then
       l_rownum_txt := ', ' || to_char(p_row);
   end if;
   l_events := 'onChange="return '||substr(p_name, 3)||'_OnChange(this'||l_rownum_txt||')"';
   if p_onclick then
      l_events := l_events || ' onClick="return '||substr(p_name, 3)||'_OnClick(this'||l_rownum_txt||')"';
   end if;
   if p_onblur then
      l_events := l_events || ' onBlur="return '||substr(p_name, 3)||'_OnBlur(this'||l_rownum_txt||')"';
   end if;
   if p_onfocus then
      l_events := l_events || ' onFocus="return '||substr(p_name, 3)||'_OnFocus(this'||l_rownum_txt||')"';
   end if;
   if p_onselect then
      l_events := l_events || ' onSelect="return '||substr(p_name, 3)||'_OnSelect(this'||l_rownum_txt||')"';
   end if;
   return '
<SCRIPT><!--
//--> '||p_value||' <!--
document.write(''<input type=text name="'||p_name||'" value="'||p_value||'" size="'||p_size||'" '||l_events||'>'')
//-->
</SCRIPT>
';
exception
   when others then
      raise_application_error(-20000, 'WSGL.BuildDerivationControl<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        InitSysImage
--
-- Description: Return string to display system image
--
--------------------------------------------------------------------------------
function InitSysImage(p_image_type in number,
                      p_image_path in varchar2,
                      p_image_name in varchar2,
                      p_initial_val in varchar2) return varchar2
is
   l_return_string varchar2(2000);
begin
   if p_image_type = IMG_TYPE_TICK then
      if p_initial_val = 'Y' then
         l_return_string := '&nbsp;'||htf.img(curl=>(p_image_path||IMG_TICK),
                                    cattributes=>('NAME='||p_image_name))||'&nbsp;';
      else
         l_return_string := '&nbsp;'||htf.img(curl=>(p_image_path||IMG_BLANK),
                                    cattributes=>('NAME='||p_image_name))||'&nbsp;';
      end if;
   elsif p_image_type = IMG_TYPE_RADIO then
      if p_initial_val = 'Y' then
         l_return_string := ''||htf.img(curl=>(p_image_path||IMG_RADIO_SEL),
                                    cattributes=>('NAME="'||p_image_name || '" ALIGN="bottom" BORDER=0 hspace=5'))||'';
      else
         l_return_string := ''||htf.img(curl=>(p_image_path||IMG_RADIO_UNSEL),
                                    cattributes=>('NAME="'||p_image_name || '" ALIGN="bottom" BORDER=0 hspace=5'))||'';
      end if;
   end if;
   return l_return_string;
end;

--------------------------------------------------------------------------------
-- Name:        HiddenField
--
-- Description: Create a hidden field with given value
--
--------------------------------------------------------------------------------
procedure HiddenField(p_paramname in varchar2,
                      p_paramval in varchar2) is
begin
   --htp.formHidden(p_paramname, replace(p_paramval,'"','&quot;'));
   htp.formHidden(p_paramname, EscapeItem(p_paramval));
exception
   when others then
      raise_application_error(-20000, 'WSGL.HiddenField<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        HiddenField
--
-- Description: Create hidden fields with given values
--
--------------------------------------------------------------------------------
procedure HiddenField(p_paramname in varchar2,
                      p_paramval in typString240Table) is
   i number := 1;
begin
   while true loop
      --htp.formHidden(p_paramname, replace(p_paramval(i),'"','&quot;'));
      htp.formHidden(p_paramname, EscapeItem(p_paramval(i)));
      i := i+1;
   end loop;
exception
   when no_data_found then
      null;
   when others then
      raise_application_error(-20000, 'WSGL.HiddenField2<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:        GetLayNumberOfPages
--
-- Description: Returns the value of LayNumberOfPages
--
-- Parameters:  None
--
--------------------------------------------------------------------------------
function GetLayNumberOfPages return number is
begin
     return LayNumberOfPages;
end;

--------------------------------------------------------------------------------
-- Name:        DisplayMessage
--
-- Description: Provides mechanism for display of messages
--
-- Parameters:  p_mess    The info message
--
--------------------------------------------------------------------------------
procedure DisplayMessage(p_type in number,
                         p_mess in varchar2,
                         p_title in varchar2,
                         p_attributes in varchar2,
                         p_location in varchar2,
                         p_context in varchar2,
                         p_action in varchar2) is
   l_mess varchar2(2000) := htf.bold(htf.header(2,p_mess));
begin
   -- Build HTML output string
   l_mess := replace(p_mess, '
', '<br>
');
   DefinePageHead(p_title);
   OpenPageBody(FALSE, p_attributes);
   if LayNumberOfPages = 1 then
      DefaultPageCaption(p_title);
      htp.para;
   end if;
   if p_type = MESS_INFORMATION then
      htp.bold(l_mess);
   elsif p_type = MESS_SUCCESS then
      htp.bold('<font color="008000" size=+2>'||htf.italic(MsgGetText(121,WSGLM.DSP121_SUCCESS))||
                '</font><br>'||l_mess);
   elsif p_type = MESS_WARNING then
      -- NB, MESS_WARNING not used at present, just issue error message
      htp.bold('<font color="ff4040" size=+2>'||htf.italic(MsgGetText(122,WSGLM.DSP122_ERROR))||
                '</font><br>'||l_mess);
   elsif p_type = MESS_ERROR then

      htp.bold('<font color="ff4040" size=+2>'||htf.italic(MsgGetText(122,WSGLM.DSP122_ERROR))||
                '</font><br>'||l_mess);
   elsif p_type = MESS_ERROR_QRY then
      htp.bold('<font color="ff4040" size=+2>'||htf.italic(MsgGetText(122,WSGLM.DSP122_ERROR))||
               '</font><br>');
      htp.bold(p_context);
      htp.para;
      htp.small(l_mess);
      if p_action is not null then
         htp.para;
         htp.bold(p_action);
      end if;
   elsif p_type = MESS_EXCEPTION then
      htp.bold('<font color="ff4040" size=+2>'||htf.italic(MsgGetText(122,WSGLM.DSP122_ERROR))||
               '</font><br>');
      htp.bold(MsgGetText(217,WSGLM.MSG217_EXCEPTION, p_location));
      htp.para;
      htp.p(l_mess);
      htp.para;
      htp.bold(MsgGetText(218,WSGLM.MSG218_CONTACT_SUPPORT));
   end if;
   htp.para;
   ClosePageBody;
end;

--------------------------------------------------------------------------------
-- Name:        StoreErrorMessage
--
-- Description: Pushes error message onto CG$ERRORS error stack
--
-- Parameters:  p_mess   The message
--
--------------------------------------------------------------------------------
procedure StoreErrorMessage(p_mess in varchar2) is
begin
  cg$errors.push(p_mess,'E','WSG',0,null);
end;


--------------------------------------------------------------------------------
-- Name:        MsgGetText
--
-- Description: Provides a mechanism for text translation.
--
-- Parameters:  p_MsgNo    The Id of the message
--              p_DfltText The Default Text
--              p_Subst1 (to 3) Substitution strings
--              p_LangId   The Language ID
--
--------------------------------------------------------------------------------
function MsgGetText(p_MsgNo in number,
                    p_DfltText in varchar2,
                    p_Subst1 in varchar2,
                    p_Subst2 in varchar2,
                    p_Subst3 in varchar2,
                    p_LangId in number) return varchar2 is
   l_temp varchar2(10000) := p_DfltText;
begin
   l_temp := replace(l_temp, '<p>',  p_Subst1);
   l_temp := replace(l_temp, '<p1>', p_Subst1);
   l_temp := replace(l_temp, '<p2>', p_Subst2);
   l_temp := replace(l_temp, '<p3>', p_Subst3);
   return l_temp;
end;

--------------------------------------------------------------------------------
-- Name:        EscapeURLParam
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
function EscapeURLParam(p_param in varchar2) return varchar2 is
   l_temp varchar2(1000) := p_param;
begin
      l_temp := replace(l_temp, '%', '%25');
      l_temp := replace(l_temp, ' ', '%20');
      l_temp := replace(l_temp, '+', '%2B');
      l_temp := replace(l_temp, '"', '%22');
      l_temp := replace(l_temp, '#', '%23');
      l_temp := replace(l_temp, '&', '%26');
   return l_temp;
end;

--------------------------------------------------------------------------------
-- Name:        GetUser
--
-- Description: Return the current user, or CGI REMOTE_USER setting if defined
--
-- Parameters:  None
--
--------------------------------------------------------------------------------
function GetUser return varchar2 is
   remote_user varchar2(30);
begin
   begin
      remote_user := upper(owa_util.get_cgi_env('REMOTE_USER'));
   exception
      when others then
         remote_user := null;
   end;
   return nvl(remote_user, user);
end;

--------------------------------------------------------------------------------
-- Name:
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
procedure RegisterURL(p_url in varchar2) is
   port_number varchar2(10) := ltrim(rtrim(owa_util.get_cgi_env('SERVER_PORT')));
begin
   if p_url is null then
      URLComplete := true;
   elsif not URLComplete then
      --CurrentURL := 'http://'||owa_util.get_cgi_env('SERVER_NAME');
      --if port_number is not null then
      --   CurrentURL := CurrentURL||':'||port_number;
      --end if;
      CurrentURL := owa_util.get_cgi_env('SCRIPT_NAME')||'/'||p_url;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.RegisterURL<br>'||SQLERRM);

end;

--------------------------------------------------------------------------------
-- Name:
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
function NotLowerCase return boolean is
begin
   URLComplete := true;
   if (owa_util.get_cgi_env('PATH_INFO') != lower(owa_util.get_cgi_env('PATH_INFO')))then
      htp.htmlOpen;
      htp.headOpen;
      RefreshURL;
      htp.headClose;
      htp.htmlClose;
      return true;
   end if;
   return false;
exception
   when others then

      raise_application_error(-20000, 'WSGL.NotLowerCase<br>'||SQLERRM);
      return true;
end;

--------------------------------------------------------------------------------
-- Name:
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
procedure RefreshURL is
begin
   htp.p('<META HTTP-EQUIV="Refresh" CONTENT="0;URL='||CurrentURL||'">');
exception
   when others then
      raise_application_error(-20000, 'WSGL.RefreshURL<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
function ExternalCall(p_proc in varchar2) return boolean is
   path_info     varchar2(1000):= substr(owa_util.get_cgi_env('PATH_INFO'),2);
   http_referrer varchar2(1000);
   pos_host      number;
   pos_script    number;
   pos_modname   number;
   pos_dollar    number;
begin
   URLComplete := true;
   -- if this procedue is not the one in URL, then it must have been called
   -- directly as a procedure call, so just return false
   if (lower(p_proc) != lower(substr(owa_util.get_cgi_env('PATH_INFO'),2))) then
      return false;
   end if;
   http_referrer := owa_util.get_cgi_env('HTTP_REFERER');
   if http_referrer is null then
      http_referrer := owa_util.get_cgi_env('HTTP_REFERRER');
   end if;
   -- some browsers store octal values for non alphanumerics in env vars
   http_referrer := replace(http_referrer,'%24','$');

   pos_host := instr(http_referrer, '//'||owa_util.get_cgi_env('SERVER_NAME'));
   pos_script := instr(http_referrer, owa_util.get_cgi_env('SCRIPT_NAME'));
   pos_dollar := instr(path_info,'$');
   pos_modname := instr(lower(http_referrer), lower(substr(path_info, 1, pos_dollar)));
   if (pos_host != 0 and pos_script > pos_host and pos_modname > pos_script) then
      return false;
   else
      DisplayMessage(MESS_ERROR, MsgGetText(231,WSGLM.MSG231_ACCESS_DENIED));
      return true;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.ExternalCall<br>'||SQLERRM);
      return true;
end;

--------------------------------------------------------------------------------
-- Name:
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
function CalledDirect(p_proc in varchar2) return boolean is
begin
   URLComplete := true;
   if (lower(p_proc) = lower(substr(owa_util.get_cgi_env('PATH_INFO'),2))) then
      DisplayMessage(MESS_ERROR, MsgGetText(231,WSGLM.MSG231_ACCESS_DENIED));
      return true;
   else
      return false;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.CalledDirect<br>'||SQLERRM);
      return true;
end;

--------------------------------------------------------------------------------
-- Name:
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
procedure AddURLParam(p_paramname in varchar2,
                      p_paramval in varchar2) is
begin
   if p_paramname is not null and not URLComplete then
      if instr(CurrentURL,'?') = 0 then
         CurrentURL := CurrentURL || '?';
      else
         CurrentURL := CurrentURL || '&';
      end if;
      CurrentURL := CurrentURL || p_paramname || '=' || EscapeURLParam(p_paramval);
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.AddURLParam<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
procedure AddURLParam(p_paramname in varchar2,
                      p_paramval in typString240Table) is
   i number := 1;
begin
   while true loop
      AddURLParam(p_paramname, p_paramval(i));
      i := i+1;
   end loop;
exception
   when no_data_found then
      null;
   when others then
      raise_application_error(-20000, 'WSGL.AddURLParam2<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
procedure StoreURLLink(p_level in number,
                       p_caption in varchar2,
                       p_open in boolean,
                       p_close in boolean) is
   thisCookie       owa_cookie.cookie;
   modname          varchar2(30);
begin
   modname := substr(owa_util.get_cgi_env('PATH_INFO'),2,30);
   modname := upper( substr(modname, 1, instr(modname,'$')) );
   if not URLCookieSet and LayNumberOfPages = 0 then
      if p_open then
         owa_util.mime_header('text/html',FALSE);
      end if;
      if p_level is not null then
         owa_cookie.send('WSG$'||modname||'URL'||to_char(p_level),
                         CurrentURL,
                         null,
                         owa_util.get_cgi_env('SCRIPT_NAME'),
                         owa_util.get_cgi_env('SERVER_NAME'));
         owa_cookie.send('WSG$'||modname||'CAP'||to_char(p_level),
                         replace(p_caption,' ','_'),
                         null,
                         owa_util.get_cgi_env('SCRIPT_NAME'),
                         owa_util.get_cgi_env('SERVER_NAME'));
      end if;
      if p_close then
         owa_util.http_header_close;
      end if;
   end if;
   if p_close then
      URLCookieSet := true;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.StoreURLLink<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
procedure ReturnLinks(p_levels in varchar2,
                      p_style  in number,
                      p_target in varchar2 default '_top',
                      p_menu   in boolean default true) is
   URLCookie  owa_cookie.cookie;
   CaptionCookie owa_cookie.cookie;
   any_done   boolean := false;
   modname    varchar2(30);
   l_levels   varchar2(100) := '.'||p_levels;
   next_level varchar2(3);
   pos        number;
begin
   if LayNumberOfPages = 1 then
      modname := substr(owa_util.get_cgi_env('PATH_INFO'),2,30);
      modname := upper( substr(modname, 1, instr(modname,'$')) );
      while l_levels is not null loop
         pos := instr(l_levels,'.',-1);
         next_level := substr(l_levels, pos+1);
         l_levels := substr(l_levels, 1, pos-1);
         URLCookie := owa_cookie.get('WSG$'||modname||'URL'||next_level);
         CaptionCookie := owa_cookie.get('WSG$'||modname||'CAP'||next_level);
         if (nvl(URLCookie.num_vals,0) > 0) and (nvl(CaptionCookie.num_vals,0) > 0) then
            if not any_done then
               NavLinks(p_style, MsgGetText(20,WSGLM.CAP020_RETURN_LINKS), 0, p_menu_required=>p_menu);
               any_done := true;

            end if;
            NavLinks(p_style, replace(CaptionCookie.vals(1),'_',' '), 1, URLCookie.vals(1),
                     p_target=>p_target, p_menu_required=>p_menu);
         end if;
      end loop;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.ReturnLinks'||'<br>'||SQLERRM);
end;

--------------------------------------------------------------------------------
-- Name:
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
function Checksum(p_buff in varchar2) return number is
   l_sum number default 0;
   l_n   number;
begin
   for i in 1 .. trunc(length(p_buff||'x'||p_buff)/2) loop
      l_n := ascii(substr(p_buff||'x'||p_buff, i*2-1, 1))*256 +
             ascii(substr(p_buff||'x'||p_buff, i*2, 1));
      l_sum := mod(l_sum+l_n,4294967296);
   end loop;
   while ( l_sum > 65536 ) loop
      l_sum := bitand( l_sum, 65535 ) + trunc(l_sum/65536);
   end loop;
   return l_sum;
end;

--------------------------------------------------------------------------------
-- Name:
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
function ValidateChecksum(p_buff in varchar2, p_checksum in varchar2)
         return boolean is
begin
   if (nvl(to_number(p_checksum),-1) != Checksum(p_buff)) then
      DisplayMessage(MESS_ERROR, MsgGetText(231,WSGLM.MSG231_ACCESS_DENIED));
      return false;
   else
      return true;
   end if;
end;

--------------------------------------------------------------------------------
-- Name:        EscapeURLParam
--
-- Description:
--
-- Parameters:
--
--------------------------------------------------------------------------------
function EscapeURLParam(p_param in varchar2,
                        p_space in boolean,
                        p_plus in boolean,
                        p_percent in boolean,
                        p_doublequote in boolean,
                        p_hash in boolean,
                        p_ampersand in boolean) return varchar2 is
   l_temp varchar2(1000) := p_param;
begin
   if p_percent then
      l_temp := replace(l_temp, '%', '%25');
   end if;
   if p_space then
      l_temp := replace(l_temp, ' ', '%20');
   end if;
   if p_plus then
      l_temp := replace(l_temp, '+', '%2B');
   end if;
   if p_doublequote then
      l_temp := replace(l_temp, '"', '%22');
   end if;
   if p_hash then
      l_temp := replace(l_temp, '#', '%23');
   end if;
   if p_ampersand then
      l_temp := replace(l_temp, '&', '%26');
   end if;
   return l_temp;
end;

--------------------------------------------------------------------------------
-- Name:        PageHeader
--
-- Description: Provided for backward compatibility with R1.3
--
-- Parameters:  p_title      IN   Page Title caption
--              p_header     IN   Page Header caption
--              p_background IN   Background gif file, if any
--      p_center     IN   Centre Alignment
--
--------------------------------------------------------------------------------
procedure PageHeader(p_title in varchar2,
                     p_header in varchar2,
                     p_background in varchar2,

                     p_center in boolean) is
  l_attributes varchar2(100) := null;
begin
   if (p_title <> p_header) then
      DefinePageHead(p_title||' : '||p_header);
   else
      DefinePageHead(p_title);
   end if;
   if p_background is not null then
      l_attributes := 'BACKGROUND="' || p_background || '"';
   end if;
   OpenPageBody(p_center, l_attributes);
   DefaultPageCaption(p_header);
end;

--------------------------------------------------------------------------------
-- Name:        PageFooter
--
-- Description: Provided for backward compatibility with R1.3
--
-- Parameters:  None
--
--------------------------------------------------------------------------------
procedure PageFooter is
begin
   ClosePageBody;
end;

--------------------------------------------------------------------------------
-- Name:        RowContext
--
-- Description: Provided for backward compatibility with R1.3
--
-- Parameters:  p_context   IN  The context string
--
--------------------------------------------------------------------------------
procedure RowContext(p_context in varchar2) is
begin
   htp.header(2, p_context);
end;

--------------------------------------------------------------------------------
-- Name:        MAX_ROWS_MESSAGE
--
-- Description: Provided for backward compatibility with R1.3 (Was a varchar2
--              constant in R1.3, but now accesses WSGLM text)
--
-- Parameters:  None
--

--------------------------------------------------------------------------------
function MAX_ROWS_MESSAGE return varchar2 is
begin
   return MsgGetText(203,WSGLM.MSG203_MAX_ROWS,to_char(MAX_ROWS));
end;

procedure Output_Calendar
  (
   Z_FIELD_NAME      in Varchar2,
   Z_FIELD_VALUE     in Varchar2,
   Z_FIELD_FORMAT    in Varchar2,
   Page_Header       in Varchar2,
   Body_Attributes   in Varchar2,
   PKG_Name          in Varchar2,
   Close_But_Caption in Varchar2,
   First_Part        in Boolean,
   Z_DEFAULT_FORMAT  in varchar2
  ) is

  day_of_week       Integer := 0;
  first_day_of_week Integer := 0;

begin

  if First_Part
  then

    -- Output the HTML that needs to go before the user defined template header

    OpenPageHead (Page_Header);

    htp.p (WSGJSL.OpenScript);
    htp.p ('function Close_OnClick() { close(); }');
    htp.p (WSGJSL.CALJavaScript (Z_FIELD_VALUE, Z_FIELD_FORMAT, Z_DEFAULT_FORMAT));
    htp.p (WSGJSL.CloseScript);

  else

    -- The rest of the calendar comes after the user defined template header

    ClosePageHead;

    OpenPageBody(FALSE, p_attributes => Body_Attributes || ' ONLOAD="setDate()"');
    htp.header(2, htf.italic(Page_Header));
    htp.formOpen(curl=> PKG_Name || '.format_cal_date', cattributes => 'name="calControl"');
    HiddenField('Z_FIELD_NAME', Z_FIELD_NAME);
    HiddenField('Z_FIELD_FORMAT', Z_FIELD_FORMAT);
    HiddenField('day', 1);

    htp.p('<input type="button" value="' || Close_But_Caption ||'" onclick="return Close_OnClick()">');

    -- Create the calendar

    htp.p ('
<CENTER>
<TABLE CELLPADDING=0 CELLSPACING=0 BORDER=0>
<TR><TD COLSPAN=7>
<CENTER>
');

    -- Create the month drop down

    htp.formSelectOpen (cname => 'month', cattributes => 'onChange=''selectDate()''');

    -- Output the names of the months in the appropriate language for the database - NLS Compliance

    for i in 1..12
    loop

      htp.formSelectOption (initcap (to_char (to_date (i, 'MM'), 'MONTH')));

    end loop;

    htp.formSelectClose;

    -- Now the year field

    htp.p ('<INPUT NAME="year" TYPE=TEXT SIZE=4 MAXLENGTH=4 onChange="selectDate()">');

    -- Finish this part of the table

    htp.p ('</CENTER></TD></TR>');

    -- Now display the movement buttons

    htp.p ('
<TR>
<TD COLSPAN=7>
<CENTER>
<INPUT TYPE=BUTTON NAME="previousYear" VALUE="<<"    onClick="return setPreviousYear()">
<INPUT TYPE=BUTTON NAME="previousYear" VALUE=" < "   onClick="return setPreviousMonth()">
<INPUT TYPE=BUTTON NAME="previousYear" VALUE="' || WSGLM.DSP129_CAL_TODAY || '" onClick="return setToday()">
<INPUT TYPE=BUTTON NAME="previousYear" VALUE=" > "   onClick="return setNextMonth()">
<INPUT TYPE=BUTTON NAME="previousYear" VALUE=">>"    onClick="return setNextYear()">
</CENTER>
</TD>
</TR>
');

    -- Display the days of the week along the top of the calendar

    htp.p ('<TR HEIGHT=10><TD></TD></TR><TR>');

    -- Find the first day of the week

    day_of_week       := to_number (to_char (to_date ('1', 'DD'), 'D'));
    first_day_of_week := (8 - day_of_week) + 1;

    for i in first_day_of_week..(first_day_of_week + 6)
    loop

      htp.prn ('<TD><CENTER><FONT SIZE=-1 FACE="Arial,Helv,Helvetica"><B>');
      htp.prn (initcap (substr (to_char (to_date (i, 'DD'), 'DAY'), 1, 2)));
      htp.p ('</B></FONT></CENTER></TD>');

    end loop;

    htp.p ('</TR>');

    -- Now display a button for each day on the calendar

    -- The calendar is made up of 6 rows

    for i in 1..6
    loop

      htp.p ('<TR>');

      for j in 1..7
      loop

        -- 7 days in each row

        htp.p ('<TD><INPUT TYPE="button" NAME="but' || ((i*j) - 2) || '"  value="    " onClick="return returnDate(this.value)"></TD>');

      end loop;  -- j in 1..7

      htp.p ('</TR>');

    end loop;  -- i in 1..6

    htp.p ('</TABLE></CENTER>');
    htp.formclose;
    ClosePageBody;

  end if;  -- First_Part

end Output_Calendar;

procedure Output_Format_Cal_JS
  (
   Page_Header     in Varchar2,
   Body_Attributes in Varchar2,
   Chosen_Date     in Varchar2,
   Field_Format    in Varchar2
  ) is

  -- This date format mask is internal and *intentional* DO NOT CHANGE
  -- DD for day number
  -- MONTH for actual text supplied by calendar drop down list
  -- YYYY y2k compliant year

  the_date date := to_date(Chosen_Date, 'DD-MONTH-YYYY');

begin

  WSGL.OpenPageHead(Page_Header);
  WSGL.ClosePageHead;
  WSGL.OpenPageBody(FALSE, p_attributes => Body_Attributes);
  htp.p ('<SCRIPT>');

  -- Convert from internal date above into display format required by field on main form

  htp.p ('opener.dateField.value = "' || to_char (the_date, Field_Format) || '";');
  htp.p ('opener.dateField.focus();');
  htp.p ('if(opener.dateField.onchange != null) { opener.dateField.onchange(); }'); --B1806675
  htp.p ('window.close();');
  htp.p ('</SCRIPT>');
  WSGL.ClosePageBody;

end Output_Format_Cal_JS;

procedure StoreClientID( p_client_id_str  in  varchar2,
                         p_open_header    in boolean,
                         p_close_header   in boolean   )
is
begin
   v_current_client_id := p_client_id_str;
   --
   if p_open_header then
      owa_util.mime_header('text/html', FALSE);
   end if;
   --
   owa_cookie.send( WSG_CLIENTID_COOKIE,
                    p_client_id_str,
                    null,
                    owa_util.get_cgi_env('SCRIPT_NAME'),
                    owa_util.get_cgi_env('SERVER_NAME'));
   --
   if p_close_header then
      owa_util.http_header_close;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.StoreClientID<br>'||SQLERRM);
end;

function GetClientID return varchar2 is
   v_client_cookie   owa_cookie.cookie;
begin
   if v_current_client_id is not null then
      return v_current_client_id;
   else
      v_client_cookie := owa_cookie.get(WSG_CLIENTID_COOKIE);
      if nvl(v_client_cookie.num_vals, 0) = 0 then
         return null;
      else
         v_current_client_id := v_client_cookie.vals(v_client_cookie.vals.first);
         return v_current_client_id;
      end if;
   end if;
exception
   when others then
      raise_application_error(-20000, 'WSGL.GetClientID<br>'||SQLERRM);
end;

-- version to get around bug 872931
function Anchor2
( curl           in       varchar2,
  ctext          in       varchar2,
  cname          in       varchar2,
  ctarget        in       varchar2,
  cattributes    in       varchar2
) return varchar2 is
begin
  if curl is null or ctext is null then
    return '<!-- ERROR in anchor2 usage, curl and cname cannot be NULL -->';
  else
    return htf.anchor2(curl,ctext,cname,ctarget,cattributes);
  end if;
end;

-- version to get around bug 965862
function img
(  curl           in       varchar2,
   calign         in       varchar2,
   calt           in       varchar2,
   cismap         in       varchar2,
   cattributes    in       varchar2
) return varchar2 is
begin
  if curl is null then
    return '<!-- NULL image source -->';
  else
    return htf.img(curl,calign,calt,cismap,cattributes);
  end if;
end;

function EscapeItem( z_item_text in varchar2 ) return varchar2
is
begin
   return (htf.escape_sc( z_item_text ));
end;


end;
/


