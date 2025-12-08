# Databricks notebook source
# MAGIC %md
# MAGIC # Delta to Lakebase Sync Pipeline
# MAGIC Single DLT pipeline to sync all fraud management tables from Delta to Lakebase PostgreSQL

# COMMAND ----------

import dlt
from pyspark.sql import functions as F

# Configuration
SOURCE_CATALOG = "afc-mvp"
SOURCE_SCHEMA = "fraud-investigation"
TARGET_CATALOG = "afc_lakebase_catalog"
TARGET_SCHEMA = "fraud_management"

# COMMAND ----------

# MAGIC %md
# MAGIC ## Table Syncs

# COMMAND ----------

@dlt.table(
    name=f"{TARGET_CATALOG}.{TARGET_SCHEMA}.siu_cases",
    comment="SIU Cases synced from Delta to Lakebase"
)
def siu_cases():
    return spark.read.table(f"`{SOURCE_CATALOG}`.`{SOURCE_SCHEMA}`.siu_cases")

# COMMAND ----------

@dlt.table(
    name=f"{TARGET_CATALOG}.{TARGET_SCHEMA}.transactions",
    comment="Transactions synced from Delta to Lakebase"
)
def transactions():
    return spark.read.table(f"`{SOURCE_CATALOG}`.`{SOURCE_SCHEMA}`.transactions")

# COMMAND ----------

@dlt.table(
    name=f"{TARGET_CATALOG}.{TARGET_SCHEMA}.alerts",
    comment="Alerts synced from Delta to Lakebase"
)
def alerts():
    return spark.read.table(f"`{SOURCE_CATALOG}`.`{SOURCE_SCHEMA}`.alerts")

# COMMAND ----------

@dlt.table(
    name=f"{TARGET_CATALOG}.{TARGET_SCHEMA}.claims",
    comment="Claims synced from Delta to Lakebase"
)
def claims():
    return spark.read.table(f"`{SOURCE_CATALOG}`.`{SOURCE_SCHEMA}`.claims")

# COMMAND ----------

@dlt.table(
    name=f"{TARGET_CATALOG}.{TARGET_SCHEMA}.investigation_activities",
    comment="Investigation Activities synced from Delta to Lakebase"
)
def investigation_activities():
    return spark.read.table(f"`{SOURCE_CATALOG}`.`{SOURCE_SCHEMA}`.investigation_activities")

# COMMAND ----------

@dlt.table(
    name=f"{TARGET_CATALOG}.{TARGET_SCHEMA}.fraud_indicators",
    comment="Fraud Indicators synced from Delta to Lakebase"
)
def fraud_indicators():
    return spark.read.table(f"`{SOURCE_CATALOG}`.`{SOURCE_SCHEMA}`.fraud_indicators")

