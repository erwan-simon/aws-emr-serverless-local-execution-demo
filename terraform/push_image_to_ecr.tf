locals {
  image_repush_trigger = {
    dockerfile_hash = filemd5("../Dockerfile")
    # compute a map composed of the relative file path as key and the file hash as value, for every files of your processing jobs, recursively. Ignoring some irrelevant path patterns
    task_code_hashes = jsonencode({
      for file_path in fileset(local.task_code_path, "**") :
      file_path => filemd5("${path.root}/${local.task_code_path}/${file_path}")
      if alltrue([
        for directory_pattern_to_ignore in [
          ".mypy_cache/", ".ipynb_checkpoints/", "__pycache__/"
        ] :
        !strcontains(file_path, directory_pattern_to_ignore)
      ]) # ignoring path if it contains any of the irrelevant directory
    })
  }
}

resource "null_resource" "push_image_to_ecr" {
  provisioner "local-exec" {
    command = join(" ", [
      "/bin/bash",
      "push_image_to_ecr.sh",
      data.aws_caller_identity.current.account_id,
      data.aws_region.current.name,
      aws_ecr_repository.main.name,
      var.docker_image_tag,
    ])
    working_dir = path.module
  }
  triggers   = local.image_repush_trigger
  depends_on = [aws_ecr_repository.main]
}

resource "time_sleep" "wait_for_image_to_appear_in_ecr" {
  # docker image takes a little while to effectively appear in the ECR after being pushed
  triggers = local.image_repush_trigger

  create_duration = "60s"
  depends_on      = [null_resource.push_image_to_ecr]
}
