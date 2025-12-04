-- Optional create a new database
CREATE DATABASE IF NOT EXISTS ICEBERG;

-- Step 1 | Create external volume to link S3 bucket with Snowflake
CREATE OR REPLACE EXTERNAL VOLUME EXT_VOL_GDC_S3
   STORAGE_LOCATIONS =
      (
         (
            NAME = 's3-iceberg-external-volume'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = '<s3_uri>' -- ex. s3://snowflake-iceberg-gdc-s3-h76rxnfdokx7/iceberg/
            STORAGE_AWS_ROLE_ARN = '<arn_snowflake_IAM_role>' -- ex. arn:aws:iam::535002871755:role/snowflake-iceberg-gdc-SnowflakeIAMRole-DyzKjswvzs7H
         )
      );

SHOW EXTERNAL VOLUMES;

-- Step 2 | Create catalog intergration to link GDC with Snowflake horizon
CREATE or REPLACE CATALOG INTEGRATION CAT_INT_GDC
  CATALOG_SOURCE=GLUE
  CATALOG_NAMESPACE='iceberg'
  TABLE_FORMAT=ICEBERG
  GLUE_AWS_ROLE_ARN='<arn_snowflake_IAM_role>' -- ex. arn:aws:iam::535002871755:role/snowflake-iceberg-gdc-SnowflakeIAMRole-DyzKjswvzs7H
  GLUE_CATALOG_ID='<aws_account_id>' -- ex. 535002871755
  GLUE_REGION='<aws_region>' -- ex. us-east-1
  ENABLED=TRUE; 

SHOW CATALOG INTEGRATIONS;

-- Step 3 | Get STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID to update IAM role
DESC EXTERNAL VOLUME EXT_VOL_GDC_S3;

SELECT
	parse_json("property_value"):STORAGE_AWS_IAM_USER_ARN::string AS storage_aws_iam_user_arn,
    parse_json("property_value"):STORAGE_AWS_EXTERNAL_ID::string AS storage_aws_external_id
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "property" = 'STORAGE_LOCATION_1';

-- Step 4 | Get GLUE_AWS_IAM_USER_ARN to update IAM role
DESC CATALOG INTEGRATION CAT_INT_GDC;

SELECT 
    "property",
    "property_value" as glue_aws_iam_user_arn
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "property" = 'GLUE_AWS_IAM_USER_ARN'

-- Step 5 | Get GLUE_AWS_EXTERNAL_ID to update IAM role
DESC CATALOG INTEGRATION CAT_INT_GDC;

SELECT
    "property",
    "property_value" as glue_aws_external_id
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "property" = 'GLUE_AWS_EXTERNAL_ID'

-- Step 6 | Create the table in Snowflake
CREATE OR REPLACE ICEBERG TABLE SAMPLEDATAICEBERGTABLE
  EXTERNAL_VOLUME='EXT_VOL_GDC_S3'
  CATALOG='CAT_INT_GDC'
  CATALOG_TABLE_NAME='sampledataicebergtable';

-- Optional query the table
SELECT * FROM SAMPLEDATAICEBERGTABLE LIMIT 10;
