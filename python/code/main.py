import boto3
from pyspark.sql import SparkSession
from pyspark.sql.types import *
# test custom dependency with c compiled library import
import pandas


def main():
    spark_session = (
    SparkSession.builder.enableHiveSupport()
        .config("spark.sql.catalogImplementation", "hive") # setup hive catalog implementation to work with AWS Glue data catalog
        .getOrCreate()
    )

    # create dummy Spark dataframe
    data = [("Alice", 34), ("Bob", 45), ("Cathy", 29)]
    columns = ["Name", "Age"]
    df = spark_session.createDataFrame(data, columns)
    database_name = "test_database"
    spark_session.sql(f"CREATE DATABASE IF NOT EXISTS {database_name}")
    s3_bucket_name = f"emr-serverless-local-execution-demo-{boto3.client('sts').get_caller_identity()['Account']}"

    # write dataframe in AWS
    df.write.mode("overwrite").option("path", f"s3a://{s3_bucket_name}/{database_name}/my_table/").saveAsTable(f"{database_name}.my_table")

    # try to request dataframe
    spark_session.sql(f"SELECT * FROM {database_name}.my_table").show()


# setup script entrypoint
if __name__ == "__main__":
    main()
