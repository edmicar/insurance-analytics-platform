###############################################################################
# InsuranceLake - Step Functions State Machine
# Orquestra: Collect→Cleanse → Cleanse→Consume → Notify
###############################################################################

resource "aws_iam_role" "step_functions_role" {
  name = "${var.environment}-insurancelake-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${var.environment}-insurancelake-sfn-policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["glue:StartJobRun", "glue:GetJobRun", "glue:GetJobRuns", "glue:BatchStopJobRun"]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [var.sns_topic_arn]
      }
    ]
  })
}

resource "aws_sfn_state_machine" "etl_pipeline" {
  name     = "${var.environment}-insurancelake-etl-state-machine"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "InsuranceLake ETL Pipeline"
    StartAt = "CollectToCleanse"
    States = {
      CollectToCleanse = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.collect_to_cleanse_job_name
          Arguments = {
            "--source_key.$"            = "$.source_key"
            "--source_path.$"           = "$.source_path"
            "--target_database_name.$"  = "$.database_name"
            "--table_name.$"            = "$.table_name"
            "--base_file_name.$"        = "$.base_file_name"
            "--p_year.$"                = "$.year"
            "--p_month.$"               = "$.month"
            "--p_day.$"                 = "$.day"
            "--execution_id.$"          = "$$.Execution.Name"
            "--source_bucket"           = var.collect_bucket_name
            "--target_bucket"           = var.cleanse_bucket_name
          }
        }
        ResultPath = "$.collect_to_cleanse_result"
        Next       = "CleanseToConsume"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "PipelineFailed"
          ResultPath  = "$.error"
        }]
      }

      CleanseToConsume = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.cleanse_to_consume_job_name
          Arguments = {
            "--source_key.$"            = "$.source_key"
            "--source_path.$"           = "$.source_path"
            "--target_database_name.$"  = "$.database_name"
            "--table_name.$"            = "$.table_name"
            "--base_file_name.$"        = "$.base_file_name"
            "--p_year.$"                = "$.year"
            "--p_month.$"               = "$.month"
            "--p_day.$"                 = "$.day"
            "--execution_id.$"          = "$$.Execution.Name"
            "--source_bucket"           = var.cleanse_bucket_name
            "--target_bucket"           = var.consume_bucket_name
          }
        }
        ResultPath = "$.cleanse_to_consume_result"
        Next       = "PipelineSucceeded"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "PipelineFailed"
          ResultPath  = "$.error"
        }]
      }

      PipelineSucceeded = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn    = var.sns_topic_arn
          Subject     = "InsuranceLake ETL Succeeded"
          "Message.$" = "States.Format('Pipeline completed for {}/{}', $.database_name, $.table_name)"
        }
        End = true
      }

      PipelineFailed = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn    = var.sns_topic_arn
          Subject     = "InsuranceLake ETL FAILED"
          "Message.$" = "States.Format('FAILED for {}/{}', $.database_name, $.table_name)"
        }
        Next = "FailState"
      }

      FailState = {
        Type  = "Fail"
        Error = "PipelineExecutionFailed"
        Cause = "ETL step failed. Check CloudWatch logs."
      }
    }
  })
}
