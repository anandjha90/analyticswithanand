import snowflake.connector
from snowflake.snowpark.functions import upper
from snowflake.connector import DictCursor
import json

connection_params = {
      "user" : 'ANALYTICSWITHANAND'
    , "password" : 'A6jhamintu@1990'
    , "account" : "PPSYLQC-HWB60503"
    , "warehouse" : "DEMOWAREHOUSE"
    , "role" : "ACCOUNTADMIN"
}

with snowflake.connector.connect(**connection_params) as conn:
    with conn.cursor(DictCursor) as cur:
        db_name = 'DEMODATABASE'
        sch_name = 'DEMOSCHEMA'
        table_name = 'CREDIT_CARD_CUSTOMERS' 
        # 1) row count
        cur.execute("SELECT COUNT(*) AS row_count FROM DEMODATABASE.DEMOSCHEMA.CREDIT_CARD_CUSTOMERS;")
        for row in cur:
            print("row_count")
            row_count = row['ROW_COUNT']
            print(row_count)

        # 2) last DML timestamp on this table
        cur.execute(f"""
            SELECT 
                start_time 
            FROM snowflake.account_usage.query_history
            WHERE query_text ILIKE '%%CREDIT_CARD_CUSTOMERS%%'
            AND query_type IN ('INSERT','UPDATE','DELETE','MERGE')
            AND database_name ilike 'DEMODATABASE'
            AND schema_name ilike 'DEMOSCHEMA'
            order by start_time desc
            limit 1;
            """)   
        for row in cur:
            print("last_dml_ts")
            last_dml_ts = row['START_TIME']
            dml_type = row['QUERY_TYPE']
            print(last_dml_ts)

        # 3) last time this table was queried
        cur.execute(f"""
            SELECT 
                MAX(start_time) query_start_ts
            FROM snowflake.account_usage.query_history
            WHERE DATABASE_NAME ILIKE 'DEMODATABASE'
            AND SCHEMA_NAME ILIKE 'DEMOSCHEMA'
            AND query_text ILIKE '%%CRECREDIT_CARD_CUSTOMERS%%'
            AND query_text NOT ILIKE '%snowflake.account_usage.query_history%';
        """)

        for row in cur:
            print("last_query_ts")
            last_query_ts = row['QUERY_START_TS']
            print(last_query_ts)

        # 4) clone lineage
        cur.execute(f"""
                    select
                        ARRAY_AGG(CONCAT(TABLE_CATALOG, '.', TABLE_SCHEMA, '.',TABLE_NAME)) WITHIN GROUP (ORDER BY TABLE_CREATED DESC) AS CLONE_LINEAGE
                    from SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
                    where clone_group_id IN (
                        select 
                            id
                        from SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
                        where table_name ILIKE 'CREDIT_CARD_CUSTOMERS'
                        AND TABLE_CATALOG ILIKE 'DEMODATABASE'
                    );
                   """)
        for row in cur:
            print("clustering")
            clone_lineage = row['CLONE_LINEAGE']

        # 6) clustering information
        cur.execute(f"""
                    with cte as (
                        SELECT parse_json(SYSTEM$CLUSTERING_INFORMATION('DEMODATABASE.DEMOSCHEMA.CREDIT_CARD_CUSTOMERS', '(DATE_OF_TXN,CUST_ID)')) as cluster_stats
                    )
                    select
                        cluster_stats:cluster_by_keys::string as cluster_by_keys
                        , cluster_stats:average_overlaps::float as average_overlaps
                        , cluster_stats:average_depth::float as average_depth
                        , cluster_stats:clustering_errors::array as clustering_errors
                        , cluster_stats:partition_depth_histogram::object as partition_depth_histogram
                        , cluster_stats:total_partition_count::int as total_partition_count
                        , cluster_stats:total_constant_partition_count::int as total_constant_partition_count
                    from cte;
                """)
        for row in cur:
            print("clustering")
            cluster_by_keys = row['CLUSTER_BY_KEYS']
            average_overlaps = row['AVERAGE_OVERLAPS']
            average_depth = row['AVERAGE_DEPTH']
            clustering_errors = row['CLUSTERING_ERRORS']
            partition_depth_histogram = row['PARTITION_DEPTH_HISTOGRAM']
            total_partition_count = row['TOTAL_PARTITION_COUNT']
            total_constant_partition_count = row['TOTAL_CONSTANT_PARTITION_COUNT']
        print(cluster_by_keys)

        # 7) materialized views that reference this table
        cur.execute(f"""
            SHOW MATERIALIZED VIEWS;
        """)
        print("mviews")
        mv_list = []
        for mview in cur:
            if (mview['source_database_name'] == 'DEMODATABASE') & (mview['source_schema_name'] == 'DEMOSCHEMA') & (mview['source_table_name'] == 'CREDIT_CARD_CUSTOMERS'):
                mv_definition = mview['text']
                mv_list.append(mv_definition)
        print(mv_list)
        mv_list = json.dumps(mv_list, separators=(',',':')).replace("'", "''")
        
        print("mv_list")
        print(mv_list)
        print(type(mv_list))
        
        target_db = 'DEMODATABASE'
        target_schema = 'DEMOSCHEMA'
        target_table = 'INVENTORY_METRICS_COLLECTION'
        insert_string = f"""
                    INSERT INTO {target_db}.{target_schema}.{target_table} (
                        database_name,
                        schema_name,
                        table_name,
                        row_count,
                        last_dml_ts,
                        last_query_ts,
                        clone_lineage,
                        cluster_by_keys,
                        average_overlaps,
                        average_depth,
                        clustering_errors,
                        partition_depth_histogram,
                        total_partition_count,
                        total_constant_partition_count,
                        mv_definitions
                        )
                    SELECT 
                        '{db_name}' as database_name,
                        '{sch_name}' as schema_name,
                        '{table_name}' as table_name,
                        {row_count} AS row_count,
                        TRY_TO_TIMESTAMP('{last_dml_ts}') as last_dml_ts,
                        TRY_TO_TIMESTAMP('{last_query_ts}') as last_query_ts,
                        NULL as clone_lineage,
                        '{cluster_by_keys}' as cluster_by_keys,
                        {average_overlaps} as average_overlaps,
                        {average_depth} as average_depth,
                        parse_json('{clustering_errors}') as clustering_errors,
                        parse_json('{partition_depth_histogram}') as partition_depth_histogram,
                        {total_partition_count} as total_partition_count,
                        {total_constant_partition_count} as total_constant_partition_count,
                        parse_json($${mv_list}$$) as mv_definitions;
                    """
        print(insert_string)
        cur.execute(insert_string)
