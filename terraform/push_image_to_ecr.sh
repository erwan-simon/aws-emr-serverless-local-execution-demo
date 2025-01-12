#!/bin/bash

aws_account_id=$1
aws_region_name=$2
ecr_name=$3
target_image_tag=$4

if ! aws ecr get-login-password --region $aws_region_name | docker login -u AWS ${aws_account_id}.dkr.ecr.${aws_region_name}.amazonaws.com --password-stdin 2> login_error_message.txt;
then
  if grep -q "The specified item already exists in the keychain." login_error_message.txt
  then
    # https://github.com/hashicorp/terraform-provider-helm/issues/989
    echo "Cannot login to ECR due to known bug, trying to push image anyway"
  else
    cat login_error_message.txt
    echo "Cannot login to ECR for unmanaged reason ('$(cat login_error_message.txt)'), Exiting..."
    exit 1;
  fi
fi

if ! docker push ${aws_account_id}.dkr.ecr.${aws_region_name}.amazonaws.com/${ecr_name}:${target_image_tag};
then
  echo "Cannot push built docker image to ECR"
  exit 1
fi
