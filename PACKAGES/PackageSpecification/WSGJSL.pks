CREATE OR REPLACE PACKAGE VMSCMS.wsgjsl is

   function OpenScript return varchar2;
   function CloseScript return varchar2;

   function OpenEvent(p_alias in varchar2, p_event in varchar2) return varchar2;
   function CloseEvent return varchar2;
   function CallEvent(p_alias in varchar2, p_event in varchar2) return varchar2;
   function CallValidate(p_alias in varchar2) return varchar2;

   function RtnNotNull return varchar2;
   function RtnCheckRange return varchar2;
   function RtnCheckCharRange return varchar2;
   function RtnChkMaxLength return varchar2;
   function RtnChkNumPrecision return varchar2;
   function RtnChkNumScale return varchar2;
   function RtnStripMask return varchar2;
   function RtnToNumber return varchar2;
   function RtnMakeUpper return varchar2;
   function RtnChkConstraint return varchar2;
   function RtnRadioValue return varchar2;
   function RtnGetValue return varchar2;
   function RtnRadioChange return varchar2;
   function RtnCheckModified return varchar2;
   function RtnRevertForm return varchar2;
   function RtnOpenLOV return varchar2;
   function RtnFindTargetFrame return varchar2;
   function RtnFlagRow return varchar2;

   function RtnConcat return varchar2;
   function RtnInitCap return varchar2;
   function RtnInstr return varchar2;
   function RtnLength return varchar2;
   function RtnLower return varchar2;
   function RtnLPad return varchar2;
   function RtnLTrim return varchar2;
   function RtnNVL1 return varchar2;
   function RtnNVL2 return varchar2;
   function RtnReplace return varchar2;
   function RtnRound return varchar2;
   function RtnRPad return varchar2;
   function RtnRTrim return varchar2;
   function RtnSign return varchar2;
   function RtnSubstr return varchar2;
   function RtnTrunc return varchar2;
   function RtnUpper return varchar2;

   function CallCheckRange(p_ctl in varchar2, p_val in varchar2, p_lowval in number, p_hival in number, p_msg in varchar2, p_scale in number default 0, p_row in boolean default false) return varchar2;
   function CallCheckCharRange(p_ctl in varchar2, p_lowval in varchar2, p_hival in varchar2, p_msg in varchar2, p_row in boolean default false) return varchar2;
   function CallChkMaxLength(p_ctl in varchar2, p_length in number, p_msg in varchar2, p_row in boolean default false) return varchar2;
   function CallChkNumPrecision(p_ctl in varchar2, p_val in varchar2, p_precision in number, p_msg in varchar2, p_row in boolean default false) return varchar2;
   function CallChkNumScale(p_ctl in varchar2, p_val in varchar2, p_scale in number, p_msg in varchar2, p_row in boolean default false) return varchar2;
   function CallChkConstraint(p_constraint in varchar, p_msg in varchar, p_indent in boolean) return varchar2;
   function CallMakeUpper(p_ctl in varchar2) return varchar2;
   function CallNotNull(p_ctl in varchar2, p_msg in varchar2, p_row in boolean default false) return varchar2;

   function StandardSubmit (set_Z_ACTION boolean default true) return varchar2;
   function VerifyDelete(p_msg in varchar2) return varchar2;

   function LOVButton(p_alias in varchar2, p_lovbut in varchar2, p_form in varchar2 default 'forms[0]', p_row in number default null) return varchar2;

   function CALButton (field_name in varchar2,
                       p_calbut in varchar2,
                       field_format in varchar2,
                       p_form in varchar2 default 'forms[0]',
                       p_row in number default null,
                       p_img_path in varchar2 default '/',
                       p_field_prompt in varchar2 default null) return varchar2;
   pragma restrict_references(CALButton, WNDS);
   function CALJavaScript (field_value in varchar2, field_date_format in varchar2, default_format in varchar2 default null) return varchar2;

   procedure Output_Invoke_CAL_JS (PKG_Name in varchar2, window_props in varchar2);

   function DerivationField(p_name in varchar2, p_size in varchar2, p_value in varchar2) return varchar2;

   function AddCode(p_expr in varchar2) return varchar2;

end;
/


CREATE OR REPLACE PACKAGE BODY VMSCMS.wsgjsl is

---------------------
   function OpenScript return varchar2 is
   begin
      return '<SCRIPT>
<!-- Hide from old browsers';
   end;
---------------------
   function CloseScript return varchar2 is
   begin
      return '//-->
</SCRIPT>';
   end;
---------------------
   function OpenEvent(p_alias in varchar2, p_event in varchar2) return varchar2 is
   begin
      return 'function '||p_alias||'_'||p_event||'(ctl, index) {';
   end;
---------------------
   function CloseEvent return varchar2 is
   begin
      return '   return true;
}';
   end;
---------------------
   function CallEvent(p_alias in varchar2, p_event in varchar2) return varchar2 is
   begin
      return '   if (!'||p_alias||'_'||p_event||'(document.forms[0].P_'||p_alias||')) { return false; }';
   end;
---------------------
   function CallValidate(p_alias in varchar2) return varchar2 is
   begin
      return '   if (!'||p_alias||'_Validate()) { return false; }';
   end;
---------------------
   function RtnNotNull return varchar2 is
   begin
      return 'function JSLNotNull(pctl, pmsg){
   if (pctl.value == "") { alert(pmsg); pctl.focus(); return false; }
   return true;
}';
   end;
---------------------
   function RtnCheckRange return varchar2 is
   begin
      return 'function JSLCheckRange(pctl, pval, pstyle, plowval, phival, pscale, pmsg ) {
   var lval = "" + pval;
   if (lval != "") {
     if (pscale > 0) {
       var ctlval = parseFloat(lval);
     }
     else {
       var ctlval = parseInt(lval);
     }
     if (pstyle == 1) { // full range
       if ( (ctlval < plowval) || (ctlval > phival)) { alert(pmsg); pctl.focus(); return false; }
     }
     if (pstyle == 2) { // check low value
       if (ctlval < plowval) { alert(pmsg); pctl.focus(); return false; }
     }
     if (pstyle == 3) { // check high value
       if (ctlval > phival) { alert(pmsg); pctl.focus(); return false; }
     }
   }
   return true;
}';
   end;
---------------------
   function RtnCheckCharRange return varchar2 is
   begin
      return 'function JSLCheckCharRange(pctl, pstyle, plowval, phival, pmsg ) {
   var lval = pctl.value;
   if (lval != "") {
     if (pstyle == 1) { // full range
       if ( (lval < plowval) || (lval > phival)) { alert(pmsg); pctl.focus(); return false; }
     }
     if (pstyle == 2) { // check low value
       if (lval < plowval) { alert(pmsg); pctl.focus(); return false; }
     }
     if (pstyle == 3) { // check high value
       if (lval > phival) { alert(pmsg); pctl.focus(); return false; }
     }
   }
   return true;
}';
   end;
---------------------
   function RtnChkMaxLength return varchar2 is
   begin
      return 'function JSLChkMaxLength(pctl, plen, pmsg) {
   if (pctl.value.length > plen) {
     alert(pmsg);
     pctl.focus();
     return false;
   }
     return true;
}';
   end;
---------------------
   function RtnChkNumScale return varchar2 is
   begin
      return 'function JSLChkNumScale (pctl, pval, pscale, pmsg) {
  if (pval != "") {
    var PointPos = pval.indexOf(".");
    if (PointPos != -1) {
      var Scale = pval.length - PointPos - 1;
      if (Scale > pscale) {
        alert(pmsg);
        pctl.focus();
        return false;
      }
    }
  }
  return true;
}';
   end;
---------------------
   function RtnChkNumPrecision return varchar2 is
   begin
      return 'function JSLChkNumPrecision(pctl, pval, pprecision, pmsg) {
  if (pval != "") {
    var Prec = 0;
    var PointPos = pval.indexOf(".");
    // If a decimal point was not found
    // validate the number of digits in the whole string
    if (PointPos == -1) {
      Prec = pval.length;
    }
    else {  // Validate the number of digits before the decimal point
      Prec = PointPos;
    }
    if (pval.indexOf("-") == 0) {
       Prec = Prec - 1;
    };
    if (pval.indexOf("+") == 0) {
       Prec = Prec - 1;
    };

    if (Prec > pprecision) { alert(pmsg); pctl.focus(); return false; }
  }
   return true;
}';
   end;
---------------------
   function RtnStripMask return varchar2 is

      L_DECIMAL varchar2(10) := substr(to_char(1.0, '9D9'), 3, 1);
      L_GROUP_SEP varchar2(10) := substr(to_char(1000, '9G999'), 3, 1);
      L_ISO_CURR varchar2(10) := rtrim(ltrim(to_char(1, 'C9999')),'1');
      L_LOCAL_CURR varchar2(10) := rtrim(ltrim(to_char(1, 'L9999')),'1');
      L_RETURN_STRING varchar2(2000) := null;

   begin

      if L_DECIMAL = '\' then
         L_DECIMAL := '\\';
      end if;
      if L_GROUP_SEP = '\' then
         L_GROUP_SEP := '\\';
      end if;
      if L_ISO_CURR = '\' then
         L_ISO_CURR := '\\';
      end if;
      if L_LOCAL_CURR = '\' then
         L_LOCAL_CURR := '\\';
      end if;

      L_RETURN_STRING := 'function JSLStripMask(p_val) {
  if (p_val == "") { return ""; }
  var str = p_val;
  str = JSLReplace(str, " ");';

      if L_GROUP_SEP != ',' then
         L_RETURN_STRING := L_RETURN_STRING || '
  str = JSLReplace(str, "'||L_GROUP_SEP||'");';
      end if;

       if L_LOCAL_CURR != '$' then
         L_RETURN_STRING := L_RETURN_STRING || '
  str = JSLReplace(str, "'||L_LOCAL_CURR||'");';
      end if;

  -- BUG 566078 9-JAN-98 Moved Decimal handling to after group separator and currency handling

      if L_DECIMAL != '.' then
         L_RETURN_STRING := L_RETURN_STRING || '
  str = JSLReplace(str, "'||L_DECIMAL||'", ".");';
      end if;

  -- end BUG 566078 9-JAN-98

      L_RETURN_STRING := L_RETURN_STRING || '
  str = JSLReplace(str, ",");
  str = JSLReplace(str, "$");
  str = JSLReplace(str, "'||L_ISO_CURR||'");

  if ((str.substring(0, 1) == "<") && (str.substring(str.length -1, str.length) == ">")) {
      str = "-" + str.substring(1, str.length - 1);
  }
  if (str.substring(str.length -1, str.length) == "-") {
    str = "-" + str.substring(0, str.length - 1);
  }
  if (str.substring(str.length -1, str.length) == "+") {
    str = str.substring(0, str.length - 1);
  }
  return str;
}';

      return L_RETURN_STRING;

   end;
---------------------
   function RtnToNumber return varchar2 is
   begin
      return 'function JSLToNumber(p_val) {
   var lval = JSLStripMask(p_val);
   if (lval == "") { return ""; }
   else { return parseFloat(lval); }
}';
   end;
---------------------
   function RtnMakeUpper return varchar2 is
   begin
      return 'function JSLMakeUpper(pctl) {
   pctl.value = pctl.value.toUpperCase();
}';
   end;
---------------------
   function RtnChkConstraint return varchar2 is
   begin
      return 'function JSLChkConstraint(pconstraint, pmsg) {
   if (!(pconstraint)) { alert(pmsg); return false; }
     return true;
}';
   end;
---------------------
   function RtnRadioValue return varchar2 is
   begin
      return 'function JSLRadioValue(pctl) {
   var i;
   for (i=0;i<pctl.length;i++) {
      if (pctl[i].checked) {
         return pctl[i].value;
      }
   }
   return "";
}';
   end;
---------------------
   function RtnGetValue return varchar2 is
   begin
      return 'function JSLGetValue(pctl, ptype, pfalse) {
   var i = 0;
   if (ptype == null) { return pctl.value; }
   if (ptype == "CHECK") {
      if (pctl.checked) { return pctl.value; }
      else { return pfalse; }
   }
   if (ptype == "RADIO") {
      for (i=0;i<pctl.length;i++) {
         if (pctl[i].checked) { return pctl[i].value; }
      }
      return "";
   }
   if (ptype == "LIST") {
      if (pctl.selectedIndex >= 0) {
         if (pctl.options[pctl.selectedIndex].value != "") {
            return pctl.options[pctl.selectedIndex].value;
         }
         else { return pctl.options[pctl.selectedIndex].text; }
      }
      else { return ""; }
   }
}';
   end;
---------------------
   function RtnRadioChange return varchar2 is
   begin
      return '
  function JSLRadioChange ( form_name, obj_name, val, row, num, num_options, p_img_path)
  {
    // get the base field name
    var name=obj_name.substring(6);

    // Find matching form.

    var form_num = 0 ;
    for ( form_num=0 ; form_num < document.forms.length ; form_num++ )
    {
      if (document.forms[form_num].name.search(form_name) != -1)
      {
         break ;
      }
    }

    // Set the hidden field value
    document.forms[form_num].elements[name][row].value=val;

    var img_name = obj_name + row ;
    var count = 0;

    for ( i=0 ; i < document.images.length ; i++ )
    {
      if ( document.images[i].name == img_name )
      {
        count++ ;
        // Change the images on the radio buttons
        if ( num == count )
        {
          document.images[i].src = p_img_path + "'||WSGL.IMG_RADIO_SEL||'";
        }
        else
        {
          document.images[i].src = p_img_path + "'||WSGL.IMG_RADIO_UNSEL||'";
        }
      }
    }

    //Set z_modified or z_insert
    if (form_name.search(/VForm$/) == -1)
    {
       JSLFlagRow( document.forms[form_num], row, true, p_img_path );
    } else {
       document.forms[form_num].z_modified[row].value = "Y";
    }
    return false;
  }
';
  end;
---------------------
   function RtnCheckModified return varchar2 is
   begin
      return 'function JSLCheckModified( p_form, p_action, p_submit ) {
   var l_mod = false;
   for (i = 0; i < p_form.z_modified.length; i++)
   {
      if (p_form.z_modified[i].value == "Y") {
         l_mod = true;
         break;
      };
   };
   if (l_mod) {
      alert("'||WSGL.MsgGetText(233,WSGLM.MSG233_DATA_CHANGED)||'");
      return false;
   } else {
      p_form.Z_ACTION.value = p_action;
      if (p_submit) {
          p_form.submit();
          return true;
      }
   }


}';
   end;
---------------------
   function RtnRevertForm return varchar2 is
   begin
      return 'function JSLRevertForm( p_form, rows ) {
   for (i = 0; i < p_form.z_modified.length; i++)
   {
      if (p_form.z_modified[i].value == "Y") {
         p_form.z_modified[i].value = "N";
      }
   }
   ResetRadios( p_form, rows );
   return true;
}';
   end;
---------------------
   function RtnOpenLOV return varchar2 is
   begin
      return 'function JSLOpenLOV(ctl, row, mode, lov_proc, depstr, lov_frame, winparams, filterprompt) {

   var currpathname = location.pathname;
   var i            = currpathname.indexOf ("/:");
   var j            = currpathname.indexOf ("/", ++i);
   var filter       = "";
   var longlist     = "";

   if (filterprompt != "")
   {
     filter = prompt(filterprompt, "%");
     if (filter == null) { return; }
     if (filter == "") { return; }
     longlist = "Y";
   };

   if (i != -1)
   {
     //Correct URL syntax
     currpathname = currpathname.substring (j, currpathname.length);
   };

   var url_string = (lov_proc +
                     "?Z_FILTER=" + escape(filter) + "&Z_MODE=" + mode +
                     "&Z_CALLER_URL=" + escape(location.protocol + "//" + location.host + currpathname + location.search) +
                     depstr +
                     "&Z_FORMROW=" + row + "&Z_LONG_LIST=" + longlist + "&Z_ISSUE_WAIT=Y");

   // B1777722  and B1854252 for IE5
   if ( navigator.appName == "Microsoft Internet Explorer" && typeof frmLOV == "object" )
   {
     frmLOV.close();
   }

   if (winparams == "")
   {
     frmLOV = open( url_string, lov_frame );
   }
   else
   {
     frmLOV = open( url_string, lov_frame, winparams);
   }

   if (frmLOV.opener == null) {
      frmLOV.opener = self;
   }
   window.LOVForm = ctl.form;
}';
   end;

---------------------
   function RtnFindTargetFrame return varchar2 is
   begin
      return 'function JSLFindTargetFrame(p_framename){
   // Is this a standard frame name?
   if (p_framename == "_top")
   {
      return top;
   }
   else if (p_framename == "_self")
   {
      return self;
   }
   else if (p_framename == "_parent")
   {
      return parent;
   }

   // Work out how many levels there are to go through.
   var levels = 1 ;
   var curr_frame = self;
   while (curr_frame != top)
   {
     levels += 1;
     curr_frame = curr_frame.parent;
   }

   // Now find the matching frame, working up through
   // the frame hierarchy.
   var frame_num = 0 ;
   var frames_to_check = frames;

   while ( levels > 0 )
   {
     frame_num = 0;
     while (frame_num < frames_to_check.length)
     {
       if ( frames_to_check[frame_num].name == p_framename )
       {
         // Found a matching frame.
         return frames_to_check[frame_num];
       }
       frame_num += 1;
     }
     // No matching frame name at this level.
     frames_to_check = frames_to_check.parent.frames;
     levels--;
   }
   return null;
}';
   end;
---------------------
   function RtnFlagRow return varchar2 is
   begin
      return 'function JSLFlagRow(p_form, p_row, p_set, p_path) {
   var img = document.images[0];
   var i = 0;
   var search_name = p_form.name + (p_row);
   var image_found = false;

   while (i < document.images.length)
   {
     img = document.images[i];
     if (img.name == search_name)
     {
       image_found = true;
       break;
     }
     i++;
   }

   if (p_set == true)
   {
     if (image_found == true)
     {
       img.src = p_path + "'||WSGL.IMG_TICK||'";
     }
     p_form.z_modified[p_row].value = "Y";
   }
   else
   {
     if (image_found == true)
     {
       img.src = p_path + "'||WSGL.IMG_BLANK||'";
     }
     p_form.z_modified[p_row].value = "N";
   }


   return;
}';
   end;
---------------------
   function RtnConcat return varchar2 is
   begin
      return 'function JSLConcat(pstr1, pstr2) {
   if (pstr1 == null) { return ""; }
   if (pstr2 == null) { return pstr1; }
   return (pstr1 + pstr2);
}';
   end;
---------------------
   function RtnInitCap return varchar2 is
   begin
      return 'function JSLInitCap(pstr) {
   if (pstr == null) {
     return "";
   }
   var count = 0;
   var str = "";
   var prevchar = "";
   var curchar = "";
   while (count < pstr.length) {
     curchar = pstr.substring(count, count + 1);
     if (count == 0 || prevchar == " ") {
       curchar = curchar.toUpperCase();
     }
     str = str + curchar;
     prevchar = curchar;
     count++;
   }
   return str;
}';
   end;
---------------------
   function RtnInstr return varchar2 is
   begin
      return 'function JSLInstr(pstr, pfind, pstart, pnth) {
   if (pstr == null || pfind == "") { return null; }
   if (pstart != null) {
     var index = 0;
     var count = 0;
     var start = pstart - 1;
     if (pnth != null) {
       while (index != -1) {
         index = pstr.indexOf(pfind, start);
         if (index == "") { return 0; }
         start = index + 1;
         count++;
         if (count == pnth) {
           return (index + 1);
         }
       }
     }
     else {
       index = pstr.indexOf(pfind, start);
       if (index == "") { return 0; }
     }
     return (index + 1);
   }
   else {
     return (pstr.indexOf(pfind) + 1);
   }
   return 0;
}';
   end;
---------------------
   function RtnLength return varchar2 is
   begin
      return 'function JSLLength(pstr) {
   return pstr.length;
}';
   end;
---------------------
   function RtnLower return varchar2 is
   begin
      return 'function JSLLower(pstr) {
   return pstr.toLowerCase();
}';
   end;
---------------------
   function RtnLPad return varchar2 is
   begin
      return 'function JSLLPad(pstr1, pLen, pstr2) {
   var str = "";
   var pos = 0;
   if (pstr1 == null || pLen == null) { return ""; }
   var count = pLen - pstr1.length;
   if (count > 0) {
     while (count > 0) {
       if (pstr2 != null) {
         if (pos == pstr2.length) {
           pos = 0;
         }
         str = str + pstr2.substring(pos, pos + 1);
         pos++;
       }
       else {
         str = str + " ";
       }
       count--;
     }
     str = str + pstr1;
   }
   else {
     str = pstr1.substring(0, pLen);
   }
   return str;
}';
   end;
---------------------
   function RtnLTrim return varchar2 is
   begin
      return 'function JSLLTrim(pstr1, pstr2) {
   var str = "";
   var curchar = "";
   var pos = 0;
   var len = pstr1.length;
   while (pos < len) {
     curchar = pstr1.substring(pos, pos + 1);
     if (pstr2 != null) {
       if (pstr2.indexOf(curchar) == -1) {
         return (pstr1.substring(pos, pstr1.length - pos));
       }
     }
     else {
       if (curchar != " ") {
         return (pstr1.substring(pos, pstr1.length - pos));
       }
     }
     pos++;
   }
   return "";
}';
   end;
---------------------
   function RtnNVL1 return varchar2 is
   begin
      return 'function JSLNVLStr(pval1, pval2) {
   if (pval1 + "" == "") { return pval2; } else { return pval1; }
}';
   end;
---------------------
   function RtnNVL2 return varchar2 is
   begin
      return 'function JSLNVLNum(pval1, pval2) {
   if (pval1 + "" == "") { return parseFloat(pval2); } else { return parseFloat(pval1); }
}';
   end;
---------------------
   function RtnReplace return varchar2 is
   begin
      return 'function JSLReplace(pstr1, pstr2, pstr3) {
   if (pstr1 != "") {
     var rtnstr = "";
     var searchstr = pstr1;
     var addlen = pstr2.length;
     var index = pstr1.indexOf(pstr2);
     while ((index != -1) && (searchstr != "")) {
       rtnstr = rtnstr + searchstr.substring(0, index);
       if (pstr3 != null) {
         rtnstr = rtnstr + pstr3;
       }
       searchstr = searchstr.substring(index + addlen, searchstr.length);
       if (searchstr != "") {
          index = searchstr.indexOf(pstr2);
       }
       else { index = -1; }
     }
     return (rtnstr + searchstr);
   }
   else {
     return "";
   }
}';
   end;
---------------------
   function RtnRound return varchar2 is
   begin
      return 'function JSLRound(pval1, pval2) {
   return Math.round(pval1);
}';
   end;
---------------------
   function RtnRPad return varchar2 is
   begin
      return 'function JSLRPad(pstr1, plen, pstr2) {
   if (pstr1 == null || plen == null) {
     return "";
   }
   var str = "";
   var pos = 0;
   var count = plen - pstr1.length;
   if (count > 0) {
     str = pstr1;
     if (pstr2 != null) {
       while (count > 0) {
         if (pos == pstr2.length) {
           pos = 0;
         }
         str = str + pstr2.substring(pos, pos + 1);
         pos++;
         count--;
       }
     }
     else {
       while (count < plen) {
         str = str + " ";
         count++;
       }
     }
   }
   else {
     str = pstr1.substring(0, plen);
   }
   return str;
}';
   end;
---------------------
   function RtnRTrim return varchar2 is
   begin
      return 'function JSLRTrim(pstr1, pstr2) {
   var str = "";
   var curchar = "";
   var len = pstr1.length;
   var pos = len - 1;
   while (pos >= 0) {
     curchar = pstr1.substring(pos, pos + 1);
     if (pstr2 != null) {
       if (pstr2.indexOf(curchar) == -1) {
         return (pstr1.substring(0, pos + 1));
       }
     }
     else {
       if (curchar != " ") {
         return (pstr1.substring(0, pos + 1));
       }
     }
     pos--;
   }
   return "";
}';
   end;
---------------------
   function RtnSign return varchar2 is
   begin
      return 'function JSLSign(pval) {
   if (pval > 0) {
     return 1;
   }
   else if (pval < 0) {
     return -1;
   }
   return pval;
}';
   end;
---------------------
   function RtnSubstr return varchar2 is
   begin
      return 'function JSLSubstr(pstr, pstart, plen) {
   if (plen != null) {
     if (Math.round(plen) < 1) {
       return null;
     }
     return (pstr.substring(Math.round(pstart) - 1, Math.round(plen) + pstart - 1));
   }
   else {
     return (pstr.substring(Math.round(pstart) - 1, pstr.length));
   }
}';
   end;
---------------------
   function RtnTrunc return varchar2 is
   begin
      return 'function JSLTrunc(pstr, pdigits) {
   var str = "" + pstr;
   var idigits = 0;
   var retval = 0.0;
   var scale = 0;
   if (str == "") {
      return "";
   }
   else {
      if (pdigits != null) {
        idigits = parseInt(pdigits,10);
      }
      retval = parseFloat(pstr);
      scale = Math.pow(10,idigits);
      retval = Math.floor(retval*scale)/scale;
      return "" + retval;
   }
}';
   end;
---------------------
   function RtnUpper return varchar2 is
   begin
      return 'function JSLUpper(pstr) {
   return pstr.toUpperCase();
}';
   end;
---------------------
   function CallCheckRange(p_ctl in varchar2, p_val in varchar2, p_lowval in number, p_hival in number, p_msg in varchar2, p_scale in number default 0, p_row in boolean default false) return varchar2 is
      l_rowstr varchar2(30);
   begin
      if p_row then
         l_rowstr := WSGL.MsgGetText(132, WSGLM.DSP132_ROW)||' " + (index+1) + ". " + "';
      end if;
      if p_lowval is null then
         return '   if (!JSLCheckRange('||p_ctl||', '||p_val||', 3, 0, '||to_char(p_hival)||', '||to_char(p_scale)||', "'||l_rowstr||p_msg||'")) {'||p_ctl||'.focus(); return false }';
      elsif p_hival is null then
         return '   if (!JSLCheckRange('||p_ctl||', '||p_val||', 2, '||to_char(p_lowval)||', 0, '||to_char(p_scale)||', "'||l_rowstr||p_msg||'")) {'||p_ctl||'.focus(); return false }';
      else
         return '   if (!JSLCheckRange('||p_ctl||', '||p_val||', 1, '||to_char(p_lowval)||', '||to_char(p_hival)||', '||to_char(p_scale)||', "'||l_rowstr||p_msg||'")) {'||p_ctl||'.focus(); return false }';
      end if;
   end;
---------------------
   function CallCheckCharRange(p_ctl in varchar2, p_lowval in varchar2, p_hival in varchar2, p_msg in varchar2, p_row in boolean default false) return varchar2 is
      l_rowstr varchar2(30);
   begin
      if p_row then
         l_rowstr := WSGL.MsgGetText(132, WSGLM.DSP132_ROW)||' " + (index+1) + ". " + "';
      end if;
      if p_lowval is null then
         return '   if (!JSLCheckCharRange('||p_ctl||', 3, 0, "'||p_hival||'", "'||l_rowstr||p_msg||'")) {'||p_ctl||'.focus(); return false }';
      elsif p_hival is null then
         return '   if (!JSLCheckCharRange('||p_ctl||', 2, "'||p_lowval||'", 0, "'||l_rowstr||p_msg||'")) {'||p_ctl||'.focus(); return false }';
      else
         return '   if (!JSLCheckCharRange('||p_ctl||', 1, "'||p_lowval||'", "'||p_hival||'", "'||l_rowstr||p_msg||'")) {'||p_ctl||'.focus(); return false }';
      end if;
   end;
---------------------
   function CallChkMaxLength(p_ctl in varchar2, p_length in number, p_msg in varchar2, p_row in boolean default false) return varchar2 is
      l_rowstr varchar2(30);
   begin
      if p_row then
         l_rowstr := WSGL.MsgGetText(132, WSGLM.DSP132_ROW)||' " + (index+1) + ". " + "';
      end if;
      return '   if (!JSLChkMaxLength('||p_ctl||', '||to_char(p_length)||', "'||l_rowstr||p_msg||'")) {'||p_ctl||'.focus(); return false }';
   end;
---------------------
   function CallChkNumPrecision(p_ctl in varchar2, p_val in varchar2, p_precision in number, p_msg in varchar2, p_row in boolean default false) return varchar2 is
      l_rowstr varchar2(30);
   begin
      if p_row then
         l_rowstr := WSGL.MsgGetText(132, WSGLM.DSP132_ROW)||' " + (index+1) + ". " + "';
      end if;
      return '   if (!JSLChkNumPrecision('||p_ctl||', '||p_val||', '||to_char(p_precision)||', "'||l_rowstr||p_msg||'")) {'||p_ctl||'.focus(); return false }';
   end;
---------------------
   function CallChkNumScale(p_ctl in varchar2, p_val in varchar2, p_scale in number, p_msg in varchar2, p_row in boolean default false) return varchar2 is
      l_rowstr varchar2(30);
   begin
      if p_row then
         l_rowstr := WSGL.MsgGetText(132, WSGLM.DSP132_ROW)||' " + (index+1) + ". " + "';
      end if;
      return '   if (!JSLChkNumScale('||p_ctl||', '||p_val||', '||to_char(p_scale)||', "'||l_rowstr||p_msg||'")) {'||p_ctl||'.focus(); return false }';
   end;
---------------------
   function CallChkConstraint(p_constraint in varchar, p_msg in varchar, p_indent in boolean) return varchar2 is
   begin
      if p_indent then
        return '     if (!JSLChkConstraint('||p_constraint||', "'||p_msg||'")) { return false }';
      else
        return '   if (!JSLChkConstraint('||p_constraint||', "'||p_msg||'")) { return false }';
      end if;
   end;
---------------------
   function CallMakeUpper(p_ctl in varchar2) return varchar2 is
   begin
      return '   JSLMakeUpper('||p_ctl||');';
   end;
---------------------
   function CallNotNull(p_ctl in varchar2, p_msg in varchar2, p_row in boolean default false) return varchar2 is
      l_rowstr varchar2(30);
   begin
      if p_row then
         l_rowstr := WSGL.MsgGetText(132, WSGLM.DSP132_ROW)||' " + (index+1) + ". " + "';
      end if;
      return '   if (!JSLNotNull('||p_ctl||', "'||l_rowstr||p_msg||'")) {'||p_ctl||'.focus(); return false }';
   end;
---------------------
   function StandardSubmit (set_Z_ACTION boolean default true) return varchar2 is
   begin

      if set_Z_ACTION
      then

        return '   ctl.form.Z_ACTION.value = ctl.value; ctl.form.submit();';

      else

        return '   ctl.form.submit();';

      end if;

   end;
---------------------
   function VerifyDelete(p_msg in varchar2) return varchar2 is
   begin
      return '   if (!confirm("'||p_msg||'")) { return false }
   ctl.form.Z_ACTION.value = "VerifiedDelete";
   ctl.form.submit();';
   end;
---------------------
   function DerivationField(p_name in varchar2,
                            p_size in varchar2,
                            p_value in varchar2) return varchar2 is
   begin
      return '
<SCRIPT><!--
//--> '||p_value||' <!--
document.write(''<input type=text name="'||p_name||'" value="'||p_value||'" size="'||p_size||'" onFocus="this.blur()">'')
//-->
</SCRIPT>
';
   end;
---------------------
   function AddCode(p_expr in varchar2) return varchar2 is
   begin
      return p_expr;
   end;
---------------------
   function LOVButton
     (p_alias in varchar2,
     p_lovbut in varchar2,
     p_form in varchar2 default 'forms[0]',
     p_row in number default null) return varchar2 is
       l_row number;
   begin
      if p_row is null then
         return '' || OpenScript || '
document.write(''<a href="javascript:void '||p_alias||'_LOV(document.'||p_form||'.P_'||p_alias||')">'||p_lovbut||'</a>'');
'|| CloseScript;
      else
         return '' || OpenScript || '
document.write(''<a href="javascript:void '||p_alias||'_LOV(document.'||p_form||'.P_'||p_alias||', '|| + to_char(p_row)||')">'||p_lovbut||'</a>'');
'|| CloseScript;
      end if;
   end;
---------------------
function CALButton
  (field_name    in varchar2,
   p_calbut      in varchar2,
   field_format  in varchar2,
   p_form        in varchar2 default 'forms[0]',
   p_row         in number   default null,
   p_img_path    in varchar2 default '/',
   p_field_prompt in varchar2 default null) return varchar2 is

   l_format varchar2(255);
begin
  l_format := replace( field_format, '''', '\''');
  l_format := htf.escape_sc(l_format);
  if p_row is null then
     return '<a href="javascript:window.dateField = document.' ||p_form|| '.' || field_name || ';' ||
            'CAL(''' || field_name || ''',document.' ||p_form|| '.' || field_name || '.value,''' || l_format || ''', ''' || p_field_prompt || ''')">' || p_calbut || '</a>';
  else
     if instr(p_form, 'VForm') != 0 then
        return '<a href="javascript:window.dateField = document.' ||p_form|| '.' || field_name || '[' || to_char(p_row) || ']; ' ||
               'document.' ||p_form|| '.z_modified['||p_row||'].value = ''Y'';' ||
               'CAL(''' || field_name || ''',document.' ||p_form|| '.' || field_name || '[' || to_char(p_row) || '].value,''' || l_format || ''', ''' || p_field_prompt || ''')' ||
               '">' || p_calbut || '</a>';
     else
        return '<a href="javascript:window.dateField = document.' ||p_form|| '.' || field_name || '[' || to_char(p_row) || ']; ' ||
                'JSLFlagRow( document.' ||p_form|| ', '||to_char(p_row)||', true, &quot;'||p_img_path||'&quot;);'||
                'CAL(''' || field_name || ''',document.' ||p_form|| '.' || field_name || '[' || to_char(p_row) || '].value,''' || l_format || ''', ''' || p_field_prompt || ''')' ||
               '">' || p_calbut || '</a>';
     end if;
  end if;

end CALButton;
---------------------
function CALJavaScript (field_value in varchar2, field_date_format in varchar2, default_format in varchar2) return varchar2 is

  l_date              date;
  in_date             varchar2 (10);
  the_date_field      varchar2 (16);
  l_valid_date        boolean;
  l_offset_unit       varchar2(4);
  l_offset            number;
  l_sysdate           date;
  l_territory_offset  pls_integer;

begin
  l_valid_date := false;
  begin
    l_date := to_date( field_value, field_date_format );
    l_valid_date := true;
  exception when others then
    null;
  end;

  if not l_valid_date then
    begin
      l_date := to_date( field_value, default_format );
      l_valid_date := true;
    exception when others then
      null;
    end;
  end if;

  if not l_valid_date then
    begin
      l_date := to_date( field_value );
      l_valid_date := true;
    exception when others then
      null;
    end;
  end if;

  if not l_valid_date then
    if substr( field_value, 1, 1 ) in ('+',' ','-') then
      l_offset_unit := upper( substr( field_value, 2, 1 ) );
      begin
         if l_offset_unit not in ('D','M','Y') then
            l_offset := to_number( substr( field_value, 2 ) );
         else
            l_offset := to_number( substr( field_value, 3 ) );
         end if;
         if substr( field_value, 1, 1 ) = '-' then
            l_offset := -1 * l_offset;
         end if;
         if l_offset_unit = 'D' then
            l_date := sysdate + l_offset;
            l_valid_date := true;
         elsif l_offset_unit = 'M' then
            l_date :=  add_months( sysdate, l_offset );
            l_valid_date := true;
         elsif l_offset_unit = 'Y' then
            l_date := add_months( sysdate, 12 * l_offset );
            l_valid_date := true;
         else
            l_date := sysdate + l_offset;
            l_valid_date := true;
         end if;
      exception when others then
         null;
      end;
    end if;
  end if;

  if not l_valid_date then
     l_date := sysdate;
  end if;

  -- Internal date format that MUST NOT be changed - this is the same format that the JS uses to
  -- parse an incoming date from the field.
  in_date := to_char (l_date, 'MM-DD-YYYY');

  if in_date is null then
    the_date_field := 'dateField.value';
  else
    the_date_field := '''' || in_date || '''';
  end if;

  -- Calculate the offset necessary due to territorial differences in the first day of the week.
  -- We know that 31st October 1999 is a Sunday, so we can see what day of the week the database thinks this is
  select to_number(to_char(to_date('31-OCT-1999','DD-MON-YYYY'),'D'))-1 into l_territory_offset from dual;

  return '
function setDate() {
    this.dateField   = opener.dateField;
    this.inDate      = ' || the_date_field || ';

    // SET DAY MONTH AND YEAR TO TODAYS DATE
    var now   = new Date();
    var day   = now.getDate();
    var month = now.getMonth();
    var year  = now.getFullYear();

    // IF A DATE WAS PASSED IN THEN PARSE THAT DATE
    if (inDate.indexOf(''-'')) {
        var inMonth = inDate.substring(0,inDate.indexOf("-"));
            if (inMonth.substring(0,1) == "0" && inMonth.length > 1)
                inMonth = inMonth.substring(1,inMonth.length);
            inMonth = parseInt(inMonth);
        var inDay   = inDate.substring(inDate.indexOf("-") + 1, inDate.lastIndexOf("-"));
            if (inDay.substring(0,1) == "0" && inDay.length > 1)
                inDay = inDay.substring(1,inDay.length);
            inDay = parseInt(inDay);
        var inYear  = parseInt(inDate.substring(inDate.lastIndexOf("-") + 1, inDate.length));

        if (inDay) {
            day = inDay;
        }
        if (inMonth) {
            month = inMonth-1;
        }
        if (inYear) {
            year = inYear;
        }
    }
    this.focusDay                           = day;
    document.calControl.month.selectedIndex = month;
    document.calControl.year.value          = year;
    displayCalendar(day, month, year);
}


function setToday() {
    // SET DAY MONTH AND YEAR TO TODAYS DATE
    var now   = new Date();
    var day   = now.getDate();
    var month = now.getMonth();
    var year  = now.getFullYear();

    this.focusDay                           = day;
    document.calControl.month.selectedIndex = month;
    document.calControl.year.value          = year;
    displayCalendar(day, month, year);
}


function isFourDigitYear(year) {
    if (year.length != 4) {
        alert ("'||WSGL.MsgGetText(234,WSGLM.MSG234_FOUR_DIGIT_YEAR)||'");
        document.calControl.year.select();
        document.calControl.year.focus();
    }
    else {
        return true;
    }
}


function selectDate() {
    var year  = document.calControl.year.value;
    if (isFourDigitYear(year)) {
        var day   = 0;
        var month = document.calControl.month.selectedIndex;
        displayCalendar(day, month, year);
    }
}


function setPreviousYear() {
    var year  = document.calControl.year.value;
    if (isFourDigitYear(year)) {
        var day   = 0;
        var month = document.calControl.month.selectedIndex;
        year--;
        document.calControl.year.value = year;
        displayCalendar(day, month, year);
    }
}


function setPreviousMonth() {
    var year  = document.calControl.year.value;
    if (isFourDigitYear(year)) {
        var day   = 0;
        var month = document.calControl.month.selectedIndex;
        if (month == 0) {
            month = 11;
            if (year > 1000) {
                year--;
                document.calControl.year.value = year;
            }
        }
        else {
            month--;
        }
        document.calControl.month.selectedIndex = month;
        displayCalendar(day, month, year);
    }
}


function setNextMonth() {
    var year  = document.calControl.year.value;
    if (isFourDigitYear(year)) {
        var day   = 0;
        var month = document.calControl.month.selectedIndex;
        if (month == 11) {
            month = 0;
            year++;
            document.calControl.year.value = year;
        }
        else {
            month++;
        }
        document.calControl.month.selectedIndex = month;
        displayCalendar(day, month, year);
    }
}


function setNextYear() {
    var year  = document.calControl.year.value;
    if (isFourDigitYear(year)) {
        var day   = 0;
        var month = document.calControl.month.selectedIndex;
        year++;
        document.calControl.year.value = year;
        displayCalendar(day, month, year);
    }
}


function displayCalendar(day, month, year) {

    day        = parseInt(day);
    month      = parseInt(month);
    year       = parseInt(year);
    var i      = 0;
    var offset = 11;
    var now    = new Date();

    if (day == 0) {
        var nowDay = now.getDate();
    }
    else {
        var nowDay = day;
    }
    var days         = getDaysInMonth(month+1,year);
    var firstOfMonth = new Date (year, month, 1);
    var startingPos  = (firstOfMonth.getDay()+'||l_territory_offset||')%7;
    days += startingPos;

    // MAKE BEGINNING NON-DATE BUTTONS BLANK
    for (i = 0; i < startingPos; i++) {
        document.calControl.elements[i + offset].value = "__";
    }

    // SET VALUES FOR DAYS OF THE MONTH
    for (i = startingPos; i < days; i++)
    {
        var datestr = (i-startingPos+1) + "";
        if ((i-startingPos+1) < 10)
        {
         datestr = "0" + datestr;
        }
        document.calControl.elements[i + offset].value = datestr;
        document.calControl.elements[i + offset].onClick = "returnDate"
    }

    // MAKE REMAINING NON-DATE BUTTONS BLANK
    for (i=days; i<42; i++)  {
        document.calControl.elements[i + offset].value = "__";
    }

    // GIVE FOCUS TO CORRECT DAY
    document.calControl.elements[focusDay+startingPos-1 + offset].focus();
    document.calControl.day.value = day;

}


// GET NUMBER OF DAYS IN MONTH
function getDaysInMonth(month,year)  {
    var days;
    if (month==1 || month==3 || month==5 || month==7 || month==8 ||
        month==10 || month==12)  days=31;
    else if (month==4 || month==6 || month==9 || month==11) days=30;
    else if (month==2)  {
        if (isLeapYear(year)) {
            days=29;
        }
        else {
            days=28;
        }
    }
    return (days);
}


// CHECK TO SEE IF YEAR IS A LEAP YEAR
function isLeapYear (Year) {
    if (((Year % 4)==0) && ((Year % 100)!=0) || ((Year % 400)==0)) {
        return (true);
    }
    else {
        return (false);
    }
}


// SET FORM FIELD VALUE TO THE DATE SELECTED
function returnDate(inDay)
{
    var day   = inDay;
    var month = (document.calControl.month.selectedIndex)+1;
    var year  = document.calControl.year.value;



    if ((""+month).length == 1)
    {
        month="0"+month;
    }
    if ((""+day).length == 1)
    {
        day="0"+day;
    }
    if (day != "__") {
        document.calControl.day.value = day;
        document.calControl.submit();
    }
}
';

end CALJavaScript;

procedure Output_Invoke_CAL_JS (PKG_Name in varchar2, window_props in varchar2) is
begin

  htp.p ('
function CAL(the_fieldname, the_value, the_format, the_prompt) {
   var filter = "";
   var the_pathname = location.pathname;
   var i            = the_pathname.indexOf (''/:'');
   var j            = the_pathname.indexOf (''/'', ++i);
   //var frmCAL;	//B1777722	Needs to be global to remember state between calls.

   if (i != -1)
   {

     // Syntactically incorrect url so it needs to be corrected

     the_pathname = the_pathname.substring (j, the_pathname.length);

   }; // (i != -1)

   // B1777722  and B1854252 for IE5
   if ( navigator.appName == "Microsoft Internet Explorer" && typeof frmCAL == "object" )
   {
     frmCAL.close();
   }

   frmCAL = open ("' || PKG_Name || '.calendar" +
                 "?Z_FIELD_NAME=" + escape(the_fieldname) +
                 "&Z_CALLER_URL=" + escape(location.protocol + ''//'' + location.host + the_pathname + location.search) +
                 "&Z_FIELD_VALUE=" + escape(the_value) +
                 "&Z_FIELD_FORMAT=" + escape(the_format) +
                 "&Z_FIELD_PROMPT=" + escape(the_prompt),
                 "winCAL", "' || window_props || '");

   if (frmCAL.opener == null)
   {
      frmCAL.opener = self;
   }
} ');

end Output_Invoke_CAL_JS;

end;
/


