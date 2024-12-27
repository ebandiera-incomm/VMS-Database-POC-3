CREATE OR REPLACE PACKAGE VMSCMS.wsglm is

/************************************************************************
** Caption:  The text forms the caption/prompt for an item
** (1-100)
************************************************************************/

  -- The text displayed in radio groups and lists which represents a null value
  -- in an optional column based on a domain.
  CAP001_UNKNOWN constant varchar2(100) := 'Unknown';

  -- The text used in link to an insert form.  <p> is replaced by the zone
  -- caption
  CAP002_ADD_LINK constant varchar2(100) := 'Add new <p> record';

  -- Query Form: Default Caption for Find Button
  CAP003_QF_FIND constant varchar2(100) := 'Find';

  -- Query Form: Default Caption for Clear Button
  CAP004_QF_CLEAR constant varchar2(100) := 'Clear';

  -- View Form: Default Caption for ReQuery Button
  CAP005_VF_REQUERY constant varchar2(100) := 'ReQuery';

  -- View Form: Default Caption for Update Button
  CAP006_VF_UPDATE constant varchar2(100) := 'Update';

  -- View Form: Default Caption for Delete Button
  CAP007_VF_DELETE constant varchar2(100) := 'Delete';

  -- View Form: Default Caption for Revert Button
  CAP008_VF_REVERT constant varchar2(100) := 'Revert';

  -- Insert Form: Default Caption for Insert Button
  CAP009_IF_INSERT constant varchar2(100) := 'Insert';

  -- Insert Form: Default Caption for Clear Button
  CAP010_IF_CLEAR constant varchar2(100) := 'Clear';

  -- Record List: Default Caption for Next Button
  CAP011_RL_NEXT constant varchar2(100) := 'Next';

  -- Record List: Default Caption for Previous Button
  CAP012_RL_PREVIOUS constant varchar2(100) := 'Previous';

  -- Record List: Default Caption for First Button
  CAP013_RL_FIRST constant varchar2(100) := 'First';

  -- Record List: Default Caption for Last Button
  CAP014_RL_LAST constant varchar2(100) := 'Last';

  -- Record List: Default Caption for Count Button
  CAP015_RL_COUNT constant varchar2(100) := 'Count';

  -- Record List: Default Caption for ReQuery Button
  CAP016_RL_REQUERY constant varchar2(100) := 'ReQuery';

  -- List Of Values: Default Caption for Find Button
  CAP017_LOV_FIND constant varchar2(100) := 'Find';

  -- List Of Values: Default Caption for Close Button
  CAP018_LOV_CLOSE constant varchar2(100) := 'Close';

  -- List Of Values: Caption for search criterion field in LOV. <p1> is the caption
  -- of the data field
  CAP019_LOV_FILTER_CAPTION constant varchar2(100) := 'Search criterion for <p1>:';

  -- Caption used for Return Links menu caption.
  CAP020_RETURN_LINKS constant varchar2(100) := 'Return Links';

  -- Caption used for Return Link to module startup.
  CAP021_TOP_LEVEL constant varchar2(100) := 'Top Level';

  -- Caption used for Return Link to untitled module component startup.
  CAP022_UNTITLED constant varchar2(100) := 'Untitled';

  -- Record List/Query Form/View Form: Default Caption for New Button
  CAP023_NEW constant varchar2(100) := 'New';

  -- Record List: Default Caption for Query Button
  CAP024_RL_QUERY constant varchar2(100) := 'Query';

  -- Caption for close button on popup calendar
  CAP025_CAL_CLOSE constant varchar2(100) := CAP018_LOV_CLOSE;

  -- Caption for poplist to mark row for update
  CAP026_DO_UPDATE constant varchar2(100) := 'Update';

  CAP027_DONT_UPDATE constant varchar2(100) := 'Do not update';

  -- Caption to display if valid value is invalid
  CAP028_INVALID_VAL constant varchar2(100) := '#INVALID!#';

  -- Caption for poplist to mark row for insert
  CAP029_DO_INSERT constant varchar2(100) := 'Insert';

  CAP030_DONT_INSERT constant varchar2(100) := 'Do not insert';

/************************************************************************
** Display:  Text is displayed as information on a page
** (101-200)
************************************************************************/

  -- The title/header displayed by the WSGL.Info() procedure
  DSP101_WSGL_INFO constant varchar2(100) := 'WSGL Information';

  -- The name of the WebServer Generator Library, used in WSGL.Info()
  DSP102_WSGL constant varchar2(100) := 'WebServer Generator Library';

  -- The prompt for the current user, used in WSGL.Info()
  DSP103_USER constant varchar2(100) := 'Current User';

  -- The prompt for the Environment variable information, used in WSGL.Info()
  DSP104_ENVIRONMENT constant varchar2(100) := 'Environment';

  -- The prompt for the version of WebServer in use, used in WSGL.Info()
  DSP105_WEB_SERVER constant varchar2(100) := 'Oracle WebServer';

  -- The prompt for the Web Browser in use, used in WSGL.Info()
  DSP106_WEB_BROWSER constant varchar2(100) := 'Web Browser';

  -- Used as part of the window title and page header for an 'About' box,
  -- and also as the default link text (preference MODAPL)
  DSP107_ABOUT constant varchar2(100) := 'About';

  -- Text which describes the name/version of the generator used to create
  -- the application, used in 'About' box.
  -- Note: <p1> is substituted with the name of the generator, and <p2> with
  --       the version
  DSP108_GENERATED_BY constant varchar2(100) :=
       'This application was generated by <p1> Version <p2>';

  -- Text displayed when one row is in record list.  <p> is replaced with the
  -- number of the record
  DSP109_RECORD constant varchar2(100) := 'Record <p>';

  -- Text displayed when more than one row is in record list.  <p1> is replaced
  -- with the number of the first record, and <p2> with the last.
  DSP110_RECORDS_N_M constant varchar2(100) := 'Records <p1> to <p2>';

  -- Text displayed after the "Records a to b" text, which contains the total
  -- number of records.  <p> is replaced with the total
  DSP111_OF_TOTAL constant varchar2(100) := 'of <p>';

  -- Text displayed when no row is in record list.
  DSP112_NO_RECORDS constant varchar2(100) := 'No Records returned';

  -- Text used in link to a detail if the number of rows are to be displayed.
  -- <p> is replaced with the number of rows
  DSP113_DETAIL_ROWS constant varchar2(100) := '(<p> Rows)';

  -- Text displayed at start of a Query Form, where there is no module
  -- component caption
  DSP115_ENTER_QRY constant varchar2(100) := 'Enter query criteria';

  -- Text displayed at start of a Query Form, where there is a module
  -- component caption. <p> is replaced with that caption.
  DSP116_ENTER_QRY_CAPTION constant varchar2(100) := 'Enter query criteria for <p>';

  -- Text displayed at start of a Inset Form. <p> is replaced with module
  -- component caption.  Note, the module component caption could be null.
  DSP117_ENTER_NEW_ROW constant varchar2(100) := 'Enter values for new <p> record';

  -- Text displayed at start of a Delete Form.
  DSP118_CONFIRM_DELETE constant varchar2(100) := 'Please confirm the Delete';

  -- Text displayed between two range controls in a Query Form
  DSP119_RANGE_TO constant varchar2(100) := 'to';

  -- Date prompt in standard footer
  DSP120_DATE constant varchar2(100) := 'Date:';

  -- Text displayed at top of form after a successful insert/update
  DSP121_SUCCESS constant varchar2(100) := 'Success!';

  -- Text displayed at top of form after an unsuccessful insert/update
  DSP122_ERROR constant varchar2(100) := 'Error!';

  -- Caption for a list of values form
  DSP123_LOV_CAPTION constant varchar2(100) := 'List Of Values: <p1>';

  -- Text displayed when a search criterion is required for a List Of Values.  <p1> is the
  -- caption of the field to which the search is applied
  DSP124_LOV_ENTER_SEARCH constant varchar2(100) := 'Please enter a search criterion for <p1>';

  -- The prompt for the Repository Application System, used in WSGL.Info()
  DSP125_REPOS_APPSYS constant varchar2(100) := 'Repository Container';

  -- The prompt for the Repository Module, used in WSGL.Info()
  DSP126_REPOS_MODULE constant varchar2(100) := 'Repository Module';

  -- Text displayed whilst waiting for List of Values to load
  DSP127_LOV_PLEASE_WAIT constant varchar2(100) := 'Please wait...';

  -- Heading for a popup calendar form
  DSP128_CAL_CAPTION        constant varchar2(100) := 'Calendar: <p1>';

  -- Caption for button that returns to today on the popup calendar
  DSP129_CAL_TODAY          constant varchar2(100) := 'Today';

  -- Caption to prefix the number of rows succesfully inserted
  DSP130_ROWS_INSERTED      constant varchar2(100) := 'Rows inserted successfully:';

  -- Caption to prefix the number of rows not inserted
  DSP131_ROWS_NOT_INSERTED  constant varchar2(100) := 'Rows not inserted:';

  -- Caption to prefix row number in error messages
  DSP132_ROW                constant varchar2(100) := 'Row';

  -- Heading for insert checkbox column
  DSP133_INSERT             constant varchar2(100) := 'Insert?';

  -- Heading for delete checkbox column
  DSP134_DELETE             constant varchar2(100) := 'Delete?';

  -- Caption to prefix information about deleted rows
  DSP135_DELETED_ROW_INFO       constant varchar2(100) := 'Deleted row information:-';

  -- Text displayed to indicate that no row has been updated
  DSP136_NO_ROW_UPDATED     constant varchar2(100) := 'No rows updated';

  -- Caption to indicate number of rows successfully updated
  DSP137_ROWS_UPDATED       constant varchar2(100) := 'Rows updated:';

  -- Caption to indicate number of errors
  DSP138_ERRORS             constant varchar2(100) := 'Errors:';

  -- Caption to indicate number of rows deleted
  DSP139_ROWS_DELETED       constant varchar2(100) := 'Rows deleted:';


/************************************************************************
** Message:  The text forms whole or part of a message issued to the user
** (201-300)
************************************************************************/

  -- WSGL Internal error issued in Domain Validation.
  MSG201_DV_INIT_ERR constant varchar2(100) := 'Uninitialised Domain Record accessed';

  -- WSGL Internal error issued in Domain Validation.
  MSG202_DV_CTL_ERR constant varchar2(100) := 'Unknown Control type accessed';

  -- Message issued when the maximum number of rows (identified by WSGL.MAX_ROWS)
  -- have been fetched.  <p> is replaced by WSGL.MAX_ROWS.
  MSG203_MAX_ROWS constant varchar2(100) := 'Maximimum number of records (<p>) returned';

  -- Message issued when an attempt is made to access a row which has been deleted
  -- (presumably by another user)
  MSG204_ROW_DELETED constant varchar2(100) := 'Row deleted by another user';

  -- Message issued after a successful row update
  MSG207_ROW_UPDATED constant varchar2(100) := 'Row updated';

  -- Message issued after a successful row insert
  MSG208_ROW_INSERTED constant varchar2(100) := 'Row inserted';

  -- Message issued when an invalid value has been entered in a domain
  MSG209_INVALID_DV constant varchar2(100) := 'Invalid value';

  -- Message issued when an invalid value has been entered in a query field.
  -- The <p> is replaced by the field caption.
  MSG210_INVALID_QRY constant varchar2(100) := 'Invalid value in <p> field(s)';

  -- Action text issued when an invalid value has been entered in a date
  -- query field. The <p> is replaced by the current date in the required format.
  MSG211_EXAMPLE_TODAY constant varchar2(100) := 'Enter in the following format: <p>';

  -- Part of the message issued when a column which has a format mask fails
  -- some basic validation.  <p> is replaced by the format mask.
  MSG212_FOMAT_MASK constant varchar2(100) := '(Format Mask is ''<p>'')';

  -- Message issued when attempting to navigate beyond the first record set
  MSG213_AT_FIRST constant varchar2(100) := 'At first row';

  -- Message issued when attempting to navigate beyond the last record set
  MSG214_AT_LAST constant varchar2(100) := 'At last row';

  -- Message issued if browser does not support multiple submit buttons.
  MSG215_NO_MULTIPLE_SUBMITS constant varchar2(200) :=
    'The browser in use does not support multiple form submit buttons, and is '||
    'therefore unable to run this application.';

  -- Message issued after a successful row delete
  MSG216_ROW_DELETED constant varchar2(100) := 'Row deleted';

  -- Message issued if an unhandled exception occurs. <p> is replaced by the name of the
  -- routine.
  MSG217_EXCEPTION constant varchar2(200) :=
     'The following unhandled error has occurred in the routine <p>:';

  -- Message issued as suggested action following an unhandled exception.
  MSG218_CONTACT_SUPPORT constant varchar2(100) := 'Please contact your support representative.';

  -- Message issued if mandatory field is missing.  <p> is the field caption.
  MSG219_MISSING_MANDATORY constant varchar2(100) := '<p> A value must be entered';

  -- Message issued if numeric precision is wrong.  <p1> is the field caption, <p2> is the precision.
  MSG220_PRECISION_ERROR constant varchar2(100) := '<p1> Value cannot have more than <p2> digits before the decimal point';

  -- Message issued if numeric scale is wrong.  <p1> is the field caption, <p2> is the scale.
  MSG221_SCALE_ERROR1 constant varchar2(100) := '<p> Value cannot have more than <p2> decimal places';

  -- Message issued if no scale defined.        <p> is the field caption.
  MSG222_SCALE_ERROR2 constant varchar2(100) := '<p> Value cannot contain decimal places';

  -- Message issued if value is not in range.  <p1> is the field caption, <p2> is low value,
  -- <p3> is high value.
  MSG223_RANGE_ERROR constant varchar2(100) := '<p1> Value outside of allowed range (<p2> to <p3>)';

  -- Message issued if a List Of values contains no rows.
  MSG224_LOV_NO_ROWS constant varchar2(100) := 'No rows match the search criterion';

  -- Message issued when "ORA-06502: PL/SQL: numeric or value error" occurs
  MSG225_ORA_6502 constant varchar2(100) := 'Incorrect datatype';

  -- Message issued when an invalid value has been entered in a Foreign Key control
  MSG226_INVALID_FK constant varchar2(100) := 'Invalid value';

  -- Message issued when a lookup value does no uniquely identify a Foreign Key control
  MSG227_TOO_MANY_FKS constant varchar2(100) := 'Value entered does not uniquely identify a row';

  -- Message issued when a LOV no longer in context of the current page
  MSG228_LOV_NOT_IN_CONTEXT constant varchar2(100) := 'The List of Values is no longer in context';

  -- Message displayed when the current Browser does not support Frames
  MSG229_NO_FRAME_SUPPORT constant varchar2(200) :=
      'This application uses HTML Frames.  Your browser does not support this functionality.
You will need to upgrade your browser if you want to use this application.';

  -- Message issued if is value > max length.  <p1> is the field caption, <p2> is the max length.
  MSG230_MAXLEN_ERROR constant varchar2(100) := '<p1> Value exceeds the maximum column length (<p2>)';

  -- Message issued when access to a package procedure is denied
  MSG231_ACCESS_DENIED constant varchar2(100) := 'Access Denied';

  -- Message issued when dependant LOV field is not filled in.  <p1> is the captin of the missing field
  MSG232_LOV_MISSING_DEPENDANT constant varchar2(100) := 'Please enter a value for <p1>';

  -- Message issued when user attempts to leave page without saving changes
  MSG233_DATA_CHANGED constant varchar2(200) := 'Data on this page has been modified. Please submit changes or revert before continuing.';

  -- Message issued if invalid year entered into calendar window
  MSG234_FOUR_DIGIT_YEAR constant varchar2(200) := 'Please enter year using four digits';

  -- Message issued if invalid year entered into calendar window
  MSG235_ROW_REQUERY_FAILURE constant varchar2(200) := 'Failed to requery row. Row does not meet query restrictions.';

  -- Message issued when a generated Portlet package requires a default description
  MSG236_PORTLET_DESCRIPTION constant varchar2(200) := '<p1> portlet generated by Web Server Generator.';

/***************************************************************************
** OCO Text: The text is used in defining a Oracle Context Option Query Form
** (501-600)
***************************************************************************/

  -- Caption of button to add more terms to search criteria
  OCO501_MORE_TERMS constant varchar2(100) := 'More Terms';

  -- Caption of button to extend search criteria
  OCO502_EXTEND constant varchar2(100) := 'Extend Search Capability';

  -- Caption of button to simplify search criteria
  OCO503_SIMPLIFY constant varchar2(100) := 'Simplify Search Capability';

  -- Text to describe how to combine terms in query
  OCO504_AND constant varchar2(100) := 'and';
  OCO505_OR constant varchar2(100) := 'or';
  OCO506_NOT constant varchar2(100) := 'not';
  OCO507_NEAR constant varchar2(100) := 'near';
  OCO508_MINUS constant varchar2(100) := 'minus';
  OCO509_ACCUMULATE constant varchar2(100) := 'accumulate';

  -- Text to describe how to compare query fields
  OCO510_MATCH constant varchar2(100) := 'Match';
  OCO511_STARTS_WITH constant varchar2(100) := 'Starts with';
  OCO512_FUZZY constant varchar2(100) := 'Fuzzy';
  OCO513_STEM constant varchar2(100) := 'Stem';
  OCO514_SOUNDEX constant varchar2(100) := 'Soundex';
  OCO515_RESULTS_OF constant varchar2(100) := 'Results of';

  -- Text to describe weighting factors
  OCO516_HIGH constant varchar2(100) := 'High';
  OCO517_MEDIUM constant varchar2(100) := 'Medium';
  OCO518_LOW constant varchar2(100) := 'Low';

  -- Text to describe rows returned
  OCO519_RETURN_CAPTION constant varchar2(100) := 'Return';
  OCO520_RETURN_ALL constant varchar2(100) := 'All hits';
  OCO521_RETURN_10 constant varchar2(100) := 'First 10 hits';
  OCO522_RETURN_100 constant varchar2(100) := 'First 100 hits';
  OCO523_RETURN_GT30 constant varchar2(100) := 'Hits with score > 30';
  OCO524_RETURN_GT70 constant varchar2(100) := 'Hits with score > 70';

/***************************************************************************
** WSGSEC Default security implementation text (601-700)
***************************************************************************/

  -- Message to indicate user has to log on
  SEC601_LOGON_REQUIRED constant varchar2(100) := 'Logon Required';

  -- Ask user for user name and password
  SEC602_USERNAME_PASSWORD constant varchar2(100) := 'Please enter your username and password to log on';

  -- Prompt for user name
  SEC603_USERNAME_PROMPT constant varchar2(100) := 'Username:';

  -- Prompt for password
  SEC604_PASSWORD_PROMPT constant varchar2(100) := 'Password:';

  -- Caption for 'Log On' button
  SEC605_LOGON_CAPTION constant varchar2(100) := 'Log on';

  -- Message to indicate logon was successful
  SEC606_LOGON_SUCCESS constant varchar2(100) := 'Logon Successful';

  -- Message to ask user to go back to start of application
  SEC607_NAVIGATE_BACK constant varchar2(100) := 'Please navigate back to the application';

  -- Message to indicate that logon was not successful
  SEC608_INVALID_LOGON constant varchar2(100) := 'Invalid Logon';

  -- Message to indicate user does not have access to the application
  SEC609_ACCESS_DENIED constant varchar2(100) := 'Access Denied';
  SEC610_NO_PERMISSION constant varchar2(100) := 'You do not have permission to use this application';

  SEC611_LOGGING_OFF constant varchar2(100) := 'Logging Off';
  SEC612_LOGGED_OFF constant varchar2(100) := 'Logged Off';

  SEC613_HOME constant varchar2(100) := 'Home';

  SEC614_NO_USER constant varchar2(100) := 'There is no user on this application that corresponds to your Single Sign-On user.';

  pragma restrict_references(wsglm, WNDS, WNPS, RNDS, RNPS);
end;
/


SHOW ERRORS