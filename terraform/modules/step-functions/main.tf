###############################################################################
# InsuranceLake - Step Functions State Machine
# Orquestra: Collect→Cleanse → Cleanse→Consume → Audit → Notify
###############################################################################

resource "aws_sfn_state_machine" "etl_pipeline" {
  name     = "${var.environment}-insurancelake-etl-state-machine"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "InsuranceLake ETL Pipeline - Orchestrates Collect→Cleanse→Consume"
    StartAt = "CollectToCleanse"
    States = {
      CollectToCleanse = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.collect_to_cleanse_job_name
          Arguments = {
            "--source_bucket.$"    = "$.source_bucket"
            "--source_key.$"       = "$.source_key"
            "--database_name.$"    = "$.database_name"
            "--table_name.$"       = "$.table_name"
            "--year.$"             = "$.year"
            "--month.$"            = "$.month"
            "--day.$"              = "$.day"
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
            "--database_name.$" = "$.database_name"
            "--table_name.$"    = "$.table_name"
            "--year.$"          = "$.year"
            "--month.$"         = "$.month"
            "--day.$"           = "$.day"
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
        Type = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = var.sns_topic_arn
          Subject  = "InsuranceLake ETL Pipeline Succeeded"
          "Message.$" = "States.Format('Pipeline completed for {}/{}', $.database_name, $.table_name)"
        }
        End = true
      }

      PipelineFailed = {
        Type = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = var.sns_topic_arn
          Subject  = "InsuranceLake ETL Pipeline FAILED"
          "Message.$" = "States.Format('Pipeline FAILED for {}/{}. Error: {}', $.database_name, $.table_name, $.error)"
        }
        Next = "FailState"
      }

      FailState = {
        Type  = "Fail"
        Error = "PipelineExecutionFailed"
        Cause = "One or more ETL steps failed. Check CloudWatch logs."
      }
    }
  })

  tags = merge(var.tags, {
    Purpose = "ETL pipeline orchestration"
  })
}

# ------------------------------------------------------------------------------
# IAM Role for Step Functions
# ------------------------------------------------------------------------------
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

  tags = var.tags
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
