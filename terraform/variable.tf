variable "ecr_name" {
  type        = string
  description = "Name of the ECR"
}

variable "docker_image_tag" {
  type        = string
  description = "Tag of the built docker image"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC of the AWS Account"
}
