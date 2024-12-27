/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_glossary_terms (term_id,
                                                         term_ovid,
                                                         term_name,
                                                         short_description,
                                                         abbrev,
                                                         alt_abbrev,
                                                         prime_word,
                                                         class_word,
                                                         modifier,
                                                         qualifier,
                                                         glossary_id,
                                                         glossary_ovid,
                                                         glossary_name
                                                        )
AS
   SELECT term_id, term_ovid, term_name, short_description, abbrev,
          alt_abbrev, prime_word, class_word, modifier, qualifier,
          glossary_id, glossary_ovid, glossary_name
     FROM dmrs_glossary_terms;


