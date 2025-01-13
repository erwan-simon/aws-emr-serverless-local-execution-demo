# EMR Serverless local execution

This repository aims to demonstrate the usage of an EMR Serverless Docker image locally.

## Prerequisites

* Docker (tested with version `27.4.0`)
* Terraform (tested with version `v1.5.7`)
* AWS CLI (tested with version `2.22.23`)
* an AWS account with working credentials and relevant permissions
* A deployed network stack on an AWS account (a VPC with at least one private subnet with access to internet, or with relevant VPC endpoints set up). You will find an example [in this github repository](https://github.com/erwan-simon/aws-network-stack)

## Repository content

* [python/](./python)
    * [python/code/](./python/code/) : directory with the PySpark code of the processing task
    * [python/local_test.ipynb](./python/local_test.ipynb) : jupyter notebook to use to test your code locally
    * [python/requirements.txt](./python/requirements.txt) : file containing your processing task's dependencies
* [Dockerfile](./Dockerfile) : Dockerfile containing the image definition to use in local and in your AWS EMR Serverless Application
* [terraform/](./terraform/) : terraform stack allowing to create the ECR, push the docker image in ECR and link it to your EMR Serverless Application
* [Makefile](./Makefile) : Makefile which contains every useful commands for this demo (do not hesitate to go see for yourself the commands launched by the Makefile)

## Repository usage

First ensure that you have your AWS credentials correctly set up :
```bash
aws sts get-caller-identity
```

Then you need to build the docker image:
```bash
make build_docker_image
```

Then you can build the AWS resources and push the Docker image in the created ECR:
```bash
make build_emr_serverless_application VPC_NAME=${NAME_OF_YOUR_EXISTING_VPC}
```

Then you can test the local execution of your code:
```bash
make run_docker_container
```

In another terminal, fetch the token from the logs:
```bash
cat logs/stderr | grep token
```
You should see something like `http://127.0.0.1:8888/tree?token=4b59bd747747b234ab93eb9788ada5f91a73e`. Paste this link (with the token) in your browser.

Launch the `local_test.ipynb` notebook in your Docker container from the jupyter interface and run the first cell, which will execute your task code.

After executing the code, you can check in AWS Athena in your AWS console that the table `test_database.my_table` exists and contains 3 rows:

| name | age |
| --- | --- |
| Alice | 34 |
| Bob | 45 |
| Cathy | 29 |

If needed, you can directly modify your code in the Docker container **OR** directly using your IDE in your [python/code/](python/code/) directory, changes will be automatically synchronized both ways, allowing faster local development iterations.

Finally when you are satisfied with your code you can rebuild your final Docker image (using `make build_docker_image`), repush it (using `make build_emr_serverless_application VPC_NAME=${NAME_OF_YOUR_EXISTING_VPC}`) and run your EMR Serverless job in AWS:
```bash
make run_emr_serverless_job
```
This command will also print the url of your job run in your EMR studio, which you can paste in your browser to go directly in your AWS console to watch the execution of your job.

## Clean up

You can delete created AWS resources with the following commands :
```bash
make destroy_emr_serverless_application VPC_NAME=${NAME_OF_YOUR_EXISTING_VPC}
```

**Do not forget to stop your EMR Serverless application and to empty your S3 bucket BEFORE executing this command, else it will NOT work.**
