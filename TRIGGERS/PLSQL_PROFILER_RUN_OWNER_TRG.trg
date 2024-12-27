CREATE OR REPLACE TRIGGER VMSCMS.plsql_profiler_run_owner_trg BEFORE INSERT OR UPDATE OF run_owner ON plsql_profiler_runs FOR EACH ROW
WHEN (
new.run_owner IS NULL
      )
BEGIN :new.run_owner := user; END;
/


