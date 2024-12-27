/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_glossaries (glossary_id,
                                                     glossary_ovid,
                                                     glossary_name,
                                                     file_name,
                                                     description,
                                                     incomplete_modifiers,
                                                     case_sensitive,
                                                     unique_abbrevs,
                                                     separator_type,
                                                     separator_char,
                                                     date_published,
                                                     published_by,
                                                     persistence_version,
                                                     version_comments
                                                    )
AS
   SELECT glossary_id, glossary_ovid, glossary_name, file_name, description,
          incomplete_modifiers, case_sensitive, unique_abbrevs,
          separator_type, separator_char, date_published, published_by,
          persistence_version, version_comments
     FROM dmrs_glossaries;


