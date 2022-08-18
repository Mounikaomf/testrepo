resource "aws_cloudwatch_event_rule" "batch-failure-rule" {
  name        = "${var.account_code}-${var.env}-batch-failure-rule-${var.region_code}"
  description = "Capture failures in batch jobs"

  event_pattern = <<EVENT
{
  "detail-type": ["Batch Job State Change"],
  "source": ["aws.batch"],
  "detail": {
    "status": ["FAILED"],
    "jobQueue": [{
      "prefix": "arn:aws:batch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job-queue/oedsd-qa1-batch-queue-"
    }]
  }
}
EVENT
}

resource "aws_cloudwatch_event_target" "batch-failure-tosns" {
  rule      = aws_cloudwatch_event_rule.batch-failure-rule.name
  target_id = "SendToSNS"
  arn       = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"
}

resource "aws_cloudwatch_event_rule" "glue-failure-rule" {
  name        = "${var.account_code}-${var.env}-glue-failure-rule-${var.region_code}"
  description = "Capture failures in glue jobs"

  event_pattern = <<EVENT
{
  "source": ["aws.glue"],
  "detail-type": ["Glue Job State Change"],
  "detail": {
    "state": ["FAILED", "TIMEOUT"],
    "jobName": [{
      "anything-but": {
        "prefix": "${var.account_code}-${var.env}-gluejob-dl"
      }
    }]
  }
}
EVENT
}

resource "aws_cloudwatch_event_target" "glue-failure-tosns" {
  rule      = aws_cloudwatch_event_rule.glue-failure-rule.name
  target_id = "SendToSNS"
  arn       = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"
}