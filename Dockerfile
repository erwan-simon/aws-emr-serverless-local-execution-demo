# syntax=docker/dockerfile:1
FROM --platform=linux/amd64 public.ecr.aws/emr-serverless/spark/emr-7.1.0:20240823

# https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/application-custom-image.html

USER root
# MODIFICATIONS GO HERE

# install python 3.10 as the default python version in the base image is a bit outdated
RUN yum install -y gcc openssl-devel bzip2-devel sqlite-devel libffi-devel tar gzip wget make zlib-static && \
	yum clean all && \
  wget https://www.python.org/ftp/python/3.10.15/Python-3.10.15.tgz && \
	tar xzf Python-3.10.15.tgz && cd Python-3.10.15 && \
	./configure --enable-optimizations --enable-loadable-sqlite-extensions && \
	make altinstall && \
	ln -sf /usr/local/bin/python3.10 /usr/bin/python3 && \
	ln -sf /usr/bin/pip3 /usr/bin/pip

# setting custom work path in the system
# If you don't do that you will have a Java AccessDeniedException when trying to copy the iceberg jar file to the /usr/app/src directory in the spark executors instances
ENV HOME="/usr/app/src"
RUN mkdir -p $HOME/task_code && chown -R hadoop:hadoop $HOME
WORKDIR $HOME

ENV PYTHONPATH="${PYTHONPATH}:$HOME"

# setup jupyter notebook for local execution
RUN pip install jupyter notebook
# the following line is to setup files required by the source docker image which are mounted directly by EMR Serverless service when executing in AWS. We create empty file because we want to be able to run this image locally, and the scripts do not really need to do anything in this context
RUN mkdir -p /var/loggingConfiguration/spark/ && touch /var/loggingConfiguration/spark/run-fluentd-spark.sh && touch /var/loggingConfiguration/spark/run-adot-collector.sh

# copy demo notebook
COPY python/local_test.ipynb .

# install custom dependencies
COPY python/requirements.txt .
RUN pip install -r requirements.txt

# Copy task code
COPY python/code/. task_code/

# end of modifications
# EMRS will run the image as hadoop
