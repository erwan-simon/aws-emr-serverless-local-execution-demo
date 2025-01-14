AWS_REGION := eu-west-1
ECR_NAME = emr_serverless_local_execution_demo
AWS_ACCOUNT_ID = $(shell aws sts get-caller-identity --query Account --output text)
DOCKER_IMAGE_NAME = $(AWS_ACCOUNT_ID).dkr.ecr.${AWS_REGION}.amazonaws.com/$(ECR_NAME)
DOCKER_IMAGE_TAG := latest

.PHONY: build_docker_image
build_docker_image:
	docker buildx build . -t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) --provenance=false

CREDENTIALS = $(shell aws configure export-credentials)
ACCESS_KEY = $(shell echo '$(CREDENTIALS)' | jq -r '.AccessKeyId')
SECRET_KEY = $(shell echo '$(CREDENTIALS)' | jq -r '.SecretAccessKey')
SESSION_TOKEN = $(shell echo '$(CREDENTIALS)' | jq -r '.SessionToken // ""')

SPARK_SUBMIT_PARAMETERS = \
		--conf spark.hadoop.fs.s3a.endpoint=s3.$(AWS_REGION).amazonaws.com \
		--conf spark.hadoop.hive.metastore.client.factory.class=com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory

.PHONY: run_docker_container
run_docker_container:
	@mkdir -p logs
	docker run \
		-e AWS_ACCESS_KEY_ID=$(ACCESS_KEY) \
		-e AWS_SECRET_ACCESS_KEY=$(SECRET_KEY) \
		-e AWS_SESSION_TOKEN=$(SESSION_TOKEN) \
		-v $$(pwd)/python/code/:/usr/app/src/task_code/ \
		-p 8888:8888 \
		-e AWS_DEFAULT_REGION=$(AWS_REGION) \
		-e AWS_REGION=$(AWS_REGION) \
		--mount type=bind,source=$$(pwd)/logs,target=/var/log/spark/user/ \
		-e PYSPARK_DRIVER_PYTHON=jupyter \
		-e PYSPARK_DRIVER_PYTHON_OPTS='notebook --ip="0.0.0.0" --no-browser --allow-root' \
		$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) \
		pyspark \
		--master local \
		$(SPARK_SUBMIT_PARAMETERS)

check_vpc_name:
ifndef VPC_NAME
	$(error "VPC_NAME is undefined")
endif

TERRAFORM_COMMAND_ARGUMENTS= -var="ecr_name=$(ECR_NAME)" -var="docker_image_tag=$(DOCKER_IMAGE_TAG)" -var="vpc_name=$(VPC_NAME)"

.PHONY: build_emr_serverless_application
build_emr_serverless_application: check_vpc_name
	cd terraform && terraform init && terraform apply $(TERRAFORM_COMMAND_ARGUMENTS)

.PHONY: destroy_emr_serverless_application
destroy_emr_serverless_application: check_vpc_name
	cd terraform && terraform init && terraform destroy $(TERRAFORM_COMMAND_ARGUMENTS)

get_emr_serverless_application_id = $(shell \
		aws emr-serverless list-applications \
		--query "applications[?name == 'emr_serverless_local_execution_demo'].id" \
		--output text)

get_emr_studio_url = $(shell \
	aws emr list-studios \
		--query "Studios[?Name == 'emr_serverless_local_execution_demo'].Url" \
		--output text)

start_job_run_and_get_id = $(shell \
	aws emr-serverless start-job-run \
		--application-id $(get_emr_serverless_application_id) \
		--execution-role-arn arn:aws:iam::$(AWS_ACCOUNT_ID):role/emr_serverless_local_execution_demo_task \
		--job-driver '{"sparkSubmit": {"entryPoint": "s3://emr-serverless-local-execution-demo-$(AWS_ACCOUNT_ID)/scripts/main.py", "sparkSubmitParameters": "$(SPARK_SUBMIT_PARAMETERS)"}}' \
		--query jobRunId \
		--output text)

.PHONY: run_emr_serverless_job
run_emr_serverless_job:
	@echo $(get_emr_studio_url)/#/serverless-applications/$(get_emr_serverless_application_id)/$(start_job_run_and_get_id)
