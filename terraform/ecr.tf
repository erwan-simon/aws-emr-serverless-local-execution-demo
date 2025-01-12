resource "aws_ecr_repository" "main" {
  name = var.ecr_name

  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = data.aws_iam_policy_document.allow_emr_serverless_to_pull_ecr_image.json
}

data "aws_iam_policy_document" "allow_emr_serverless_to_pull_ecr_image" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["emr-serverless.amazonaws.com"]
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        aws_emrserverless_application.main.arn
      ]
    }
  }
}
