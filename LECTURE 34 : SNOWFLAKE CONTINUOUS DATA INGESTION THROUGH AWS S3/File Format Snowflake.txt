create or replace file format sky.sky.customer_csv_ff 
    type = 'csv' 
    compression = 'none' 
    field_delimiter = ','
    field_optionally_enclosed_by = 'none'
    skip_header = 1 ;  


--creating psv ff
create or replace file format sky.sky.customer_psv_ff
type='csv'
compression ='none'
field_delimiter='|'
field_optionally_enclosed_by ='\042'
skip_header=1;

--creating tsv ff
create or replace file format sky.sky.customer_tsv_ff
type='csv'
compression='none'
field_delimiter='\t'
field_optionally_enclosed_by='\042'
skip_header=1;


file format options :

1. type = 'csv' / 'json'
2. compression = AUTO | GZIP | BZ2 | BROTLI | ZSTD | DEFLATE | RAW_DEFLATE | NONE
      Use --> Data loading, data unloading, and external tables
      Default --> AUTO 
3. Record Delimiter= '\n' '\r'
4. Field Delimiter = ',' '|' , '\t'
5. Field Extension = '.csv'
6. skip_header = '1' | 'none'
7. SKIP_BLANK_LINES = TRUE | FALSE  -- Boolean that specifies to skip any blank lines encountered in the data files;
                                       otherwise, blank lines produce an end-of-record error (default behavior).
8. FIELD_OPTIONALLY_ENCLOSED_BY ='none' | '\042' 
9. ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE | FALSE

--------------------------------------------------------------------------------------------

-- FF with some more properties
create or replace file format sky.sky.customer_csv_ff
type= 'csv'
field_delimiter =','
skip_header=1
field_optionally_enclosed_by="none"
null_if = ('null','NULL')
empty_field_as_null = true
compression = gzip


----------- All data is not loading because of double quotes error so changing the enclosed by value --------------

truncate customer_csv;
-- field optionally enclosed
create or replace file format sky.sky.customer_csv_ff2
    type = 'csv' 
    compression = 'none' 
    field_delimiter = ','
    field_optionally_enclosed_by = '\042' -- because I'm facing double quotes error as this data is not loading 
    skip_header = 1 ;
