###############################################################################
# InsuranceLake - Amazon QuickSight
# Data Source (Athena) + Datasets (Policy, Claims) + Calculated Fields
#
# PRÉ-REQUISITO: QuickSight deve estar ativado manualmente no Console
###############################################################################

data "aws_caller_identity" "current" {}

locals {
  account_id    = data.aws_caller_identity.current.account_id
  principal_arn = "arn:aws:quicksight:${var.region}:${local.account_id}:user/default/${var.quicksight_username}"
}

# ------------------------------------------------------------------------------
# Data Source: Conexão com Athena
# ------------------------------------------------------------------------------
resource "aws_quicksight_data_source" "athena" {
  aws_account_id = local.account_id
  data_source_id = "${var.environment}-insurancelake-athena"
  name           = "InsuranceLake Athena - ${var.environment}"
  type           = "ATHENA"

  parameters {
    athena {
      work_group = var.athena_workgroup
    }
  }

  permission {
    principal = local.principal_arn
    actions = [
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource",
      "quicksight:UpdateDataSource",
      "quicksight:DeleteDataSource",
      "quicksight:UpdateDataSourcePermissions"
    ]
  }
}

# ------------------------------------------------------------------------------
# Dataset: Policy Data (Consume layer)
# ------------------------------------------------------------------------------
resource "aws_quicksight_data_set" "policy_data" {
  aws_account_id = local.account_id
  data_set_id    = "${var.environment}-insurancelake-policydata"
  name           = "InsuranceLake - Policy Data"
  import_mode    = "SPICE"

  physical_table_map {
    physical_table_map_id = "policy-table"

    relational_table {
      data_source_arn = aws_quicksight_data_source.athena.arn
      catalog         = "AwsDataCatalog"
      schema          = "${var.database_name}_consume"
      name            = "policydata"

      input_columns {
        name = "policynumber"
        type = "STRING"
      }
      input_columns {
        name = "effectivedate"
        type = "DATETIME"
      }
      input_columns {
        name = "expirationdate"
        type = "DATETIME"
      }
      input_columns {
        name = "writtenpremiumamount"
        type = "DECIMAL"
      }
      input_columns {
        name = "earnedpremium"
        type = "DECIMAL"
      }
      input_columns {
        name = "neworenewal"
        type = "STRING"
      }
      input_columns {
        name = "lineofbusiness"
        type = "STRING"
      }
      input_columns {
        name = "state"
        type = "STRING"
      }
      input_columns {
        name = "insuredname"
        type = "STRING"
      }
    }
  }

  logical_table_map {
    logical_table_map_id = "policy-logical"

    alias = "PolicyData"

    source {
      physical_table_id = "policy-table"
    }
  }

  permissions {
    principal = local.principal_arn
    actions = [
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:ListIngestions",
      "quicksight:UpdateDataSet",
      "quicksight:DeleteDataSet",
      "quicksight:CreateIngestion",
      "quicksight:CancelIngestion",
      "quicksight:UpdateDataSetPermissions"
    ]
  }
}

# ------------------------------------------------------------------------------
# Dataset: Claims Data (Consume layer)
# ------------------------------------------------------------------------------
resource "aws_quicksight_data_set" "claim_data" {
  aws_account_id = local.account_id
  data_set_id    = "${var.environment}-insurancelake-claimdata"
  name           = "InsuranceLake - Claims Data"
  import_mode    = "SPICE"

  physical_table_map {
    physical_table_map_id = "claims-table"

    relational_table {
      data_source_arn = aws_quicksight_data_source.athena.arn
      catalog         = "AwsDataCatalog"
      schema          = "${var.database_name}_consume"
      name            = "claimdata"

      input_columns {
        name = "claimid"
        type = "STRING"
      }
      input_columns {
        name = "policynumber"
        type = "STRING"
      }
      input_columns {
        name = "accidentdate"
        type = "DATETIME"
      }
      input_columns {
        name = "accidentyeartotalincurredamount"
        type = "DECIMAL"
      }
      input_columns {
        name = "claimstatus"
        type = "STRING"
      }
      input_columns {
        name = "claimtype"
        type = "STRING"
      }
    }
  }

  logical_table_map {
    logical_table_map_id = "claims-logical"

    alias = "ClaimsData"

    source {
      physical_table_id = "claims-table"
    }
  }

  permissions {
    principal = local.principal_arn
    actions = [
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:ListIngestions",
      "quicksight:UpdateDataSet",
      "quicksight:DeleteDataSet",
      "quicksight:CreateIngestion",
      "quicksight:CancelIngestion",
      "quicksight:UpdateDataSetPermissions"
    ]
  }
}
