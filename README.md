# Read Iceberg tables from Glue Data Catalog (GDC) via. Snowflake

<img width="275" alt="map-user" src="https://img.shields.io/badge/cloudformation template deployments-000-blue"> <img width="85" alt="map-user" src="https://img.shields.io/badge/views-0000-green"> <img width="125" alt="map-user" src="https://img.shields.io/badge/unique visits-000-green">

Snowflake can query (read only) Iceberg tables that are registered with the Glue Data Catalog and stored in S3 general purpose buckets. This integration works via. an external volume in Snowflake pointing to the S3 bucket with the Iceberg files and an external catalog in Snowflake pointing to Glue data catalog.

The architecture below depicts this

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_GDC/blob/main/READEME/Architecture.png">

## Example

You can test this integration. Begin by deploying the CloudFormation stack below. This will create the required AWS resources.

> [!WARNING]
> The CloudFormation stack creates IAM role(s) that have ADMIN permissions. This is not appropriate for production deployments. Scope these roles down before using this CloudFormation in production.

[![Launch CloudFormation Stack](https://sharkech-public.s3.amazonaws.com/misc-public/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=snowflake-iceberg-gdc&templateURL=https://sharkech-public.s3.amazonaws.com/misc-public/snowflake_iceberg_gdc.yaml)

### Create a sample Iceberg table in AWS via. Glue

Navigate to the Glue console ETL jobs page, select the *Create Iceberg Table* and select the *Run* button

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_GDC/blob/main/READEME/run_glue_job.png">

This will create an Iceberg table named ```sampledataicebergtable``` registered with the Glue data catalog database ```iceberg```

### Create an external volume in Snowflake

**NOTE** the values of any of the <...> place holders can be found in the output section of the CloudFormation stack

<img width="700" alt="quick_setup" src="https://github.com/ev2900/Snowflake_Iceberg_GDC/blob/main/READEME/cloudformation_outputs.png">

Update the run the following SQL in Snowflake.  

```
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
```

### Create a catalog integration in Snowflake

Update the run the following SQL in Snowflake. 

The values of any of the <...> place holders can be found in the output section of the CloudFormation stack

```
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
```

### Update IAM role allowing Snowflake to assume it



### Create external table definition in Snowflake
