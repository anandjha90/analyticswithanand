CREATE OR REPLACE PROCEDURE SNOWFLAKE_CORTEX_BASED_QUERY_OPTIMIZER.APP_SCHEMA.REGISTER_CB("REF_NAME" VARCHAR, "OPERATION" VARCHAR, "REF_OR_ALIAS" VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
    begin
        case (operation)
            when ''ADD'' then
                select system$set_reference(:ref_name, :ref_or_alias);
            when ''REMOVE'' then
                select system$remove_reference(:ref_name);
            when ''CLEAR'' then
                select system$remove_reference(:ref_name);
            else
                return ''Unknown operation: '' || operation;
        end case;
        system$log(''debug'', ''register_single_callback: '' || operation || '' succeeded'');
        return ''Operation '' || operation || '' succeeded'';
    end;
';
