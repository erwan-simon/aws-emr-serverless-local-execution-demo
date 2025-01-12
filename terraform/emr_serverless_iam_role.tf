resource "aws_iam_role" "emr_serverless_task" {
  name = "${local.resources_name}_task"

  assume_role_policy = data.aws_iam_policy_document.emr_serverless_task_assume.json
}

data "aws_iam_policy_document" "emr_serverless_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = ["emr-serverless.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "emr_serverless_task" {
  name   = "${local.resources_name}_task"
  policy = data.aws_iam_policy_document.emr_serverless_task.json
}

resource "aws_iam_role_policy_attachment" "emr_serverless_task" {
  role       = aws_iam_role.emr_serverless_task.name
  policy_arn = aws_iam_policy.emr_serverless_task.arn
}

data "aws_iam_policy_document" "emr_serverless_task" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*",
    ]
  }
  statement {
    actions = [
      "ecr:GetRepositoryPolicy",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRegistry",
      "ecr:DescribeImages",
      "ecr:BatchGetImage"
    ]
    resources = [
      aws_ecr_repository.main.arn
    ]
  }
  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:GetLogGroupFieldsi",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "glue:UpdateTable",
      "glue:CreateTable",
      "glue:CreateDatabase",
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:DeleteTable"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/default",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/test_database",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/test_database/my_table",
    ]
  }
}
