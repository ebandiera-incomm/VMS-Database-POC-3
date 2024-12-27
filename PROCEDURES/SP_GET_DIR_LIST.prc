create or replace
    procedure VMSCMS.sp_get_dir_list( p_directory in varchar2 )
    as language java
    name 'DirList.getList( java.lang.String )';
    /

	SHOW ERRORS;