# Athena WorkGroup
resource "aws_athena_workgroup" "data_report_athena" {
  name = "drathena"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results_bucket.bucket}/output/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = aws_kms_key.main_kms_key.arn
      }
    }
  }
}

# Athena database
resource "aws_athena_database" "athena_database" {
  name   = "athenadb"
  bucket = aws_s3_bucket.athena_results_bucket.id
}


# Glue DataBase
resource "aws_glue_catalog_database" "glue" {
  name = "my_report_db"
}

# Glue DB Encryption
resource "aws_glue_data_catalog_encryption_settings" "glue_encryption" {
  data_catalog_encryption_settings {
    connection_password_encryption {
      return_connection_password_encrypted = false
    }

    # Activates the KMS encryption 
    encryption_at_rest {
      catalog_encryption_mode = "SSE-KMS"
      sse_aws_kms_key_id      = aws_kms_key.main_kms_key.arn
    }
  }
}

# Glue Table
resource "aws_glue_catalog_table" "glue_table" {
  name          = "mygluetable"
  database_name = aws_glue_catalog_database.glue.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data_report_bucket.bucket}/breach-data/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "my-stream"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "name"
      type = "string"
    }

    columns {
      name = "title"
      type = "string"
    }

    columns {
      name = "domain"
      type = "string"
    }

    columns {
      name = "breach_date"
      type = "string"
    }

    columns {
      name = "added_date"
      type = "string"
    }

    columns {
      name = "pwn_count"
      type = "bigint"
    }

    columns {
      name = "description"
      type = "string"
    }

    columns {
      name = "data_classes"
      type = "string"
    }

    columns {
      name = "is_verified"
      type = "boolean"
    }

    columns {
      name = "is_sensitive"
      type = "boolean"
    }

    columns {
      name = "is_retired"
      type = "boolean"
    }

    columns {
      name = "email"
      type = "string"
    }

    columns {
      name = "scan_id"
      type = "string"
    }
  }
}