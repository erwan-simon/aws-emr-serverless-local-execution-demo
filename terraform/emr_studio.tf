resource "aws_emr_studio" "main" {
  auth_mode                   = "IAM"
  default_s3_location         = "s3://${aws_s3_bucket.main.id}/emr_studio/"
  engine_security_group_id    = aws_security_group.main.id
  name                        = local.resources_name
  service_role                = aws_iam_role.emr_studio.arn
  subnet_ids                  = data.aws_subnets.private.ids
  vpc_id                      = data.aws_vpc.main.id
  workspace_security_group_id = aws_security_group.main.id
  depends_on                  = [aws_iam_policy_attachment.emr_studio]
}

resource "aws_iam_role" "emr_studio" {
  name = "${local.resources_name}_emr_studio"

  assume_role_policy = data.aws_iam_policy_document.emr_studio_assume.json
}

data "aws_iam_policy_document" "emr_studio_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = ["elasticmapreduce.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "emr_studio" {
  name   = "${local.resources_name}_emr_studio"
  policy = data.aws_iam_policy_document.emr_studio.json
}

resource "aws_iam_policy_attachment" "emr_studio" {
  name       = "${local.resources_name}_emr_studio"
  roles      = [aws_iam_role.emr_studio.name]
  policy_arn = aws_iam_policy.emr_studio.arn
}

data "aws_iam_policy_document" "emr_studio" {
  statement {
    actions = [
      "ec2:Describe*",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListInstanceProfiles",
      "iam:ListRolePolicies",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeImages"
    ]
    resources = ["*"]

  }
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject*",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/emr_studio/*"
    ]
  }
}
