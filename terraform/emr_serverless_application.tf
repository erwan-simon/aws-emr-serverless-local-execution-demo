resource "aws_emrserverless_application" "main" {
  name          = local.resources_name
  release_label = "emr-7.1.0"
  type          = "spark"
  auto_start_configuration {
    enabled = true
  }
  auto_stop_configuration {
    enabled              = true
    idle_timeout_minutes = 5
  }

  maximum_capacity {
    cpu    = "60 vCPU"
    memory = "120 GB"
    disk   = "800 GB"
  }
  network_configuration {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = [aws_security_group.main.id]
  }
  image_configuration {
    image_uri = "${aws_ecr_repository.main.repository_url}:${var.docker_image_tag}"
  }
  interactive_configuration {
    studio_enabled = true
  }

  tags       = { Name = local.resources_name }
  depends_on = [time_sleep.wait_for_image_to_appear_in_ecr]
}

resource "aws_s3_object" "emr_serverless_task_code_entrypoint" {
  bucket = aws_s3_bucket.main.id
  key    = "/scripts/main.py"
  source = "${local.task_code_path}/code/main.py"
  etag   = filemd5("${local.task_code_path}/code/main.py")
}
