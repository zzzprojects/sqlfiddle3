# SQL Fiddle, version 3

This version of the system is intended to make use of Docker for the different systems (app server, app database, fiddle databases, etc...)

It is also implemented with Vert.x in the application tier.

### Prerequisites for local build:

    Java 8+
    Maven 3.3+
    Docker 17+
    Minikube 0.24.1+ (Minikube requires several dependencies; see https://kubernetes.io/docs/tasks/tools/install-minikube/)

To get running locally, first start minikube with a 4GB VM and configure docker to use it:

    minikube start --insecure-registry 10.0.0.0/24 --memory 4096
    eval $(minikube docker-env)

Once your minikube environment is prepared, you can build SQL Fiddle within it using these commands:

    (cd appServer/; mvn clean package)
    docker build -t sqlfiddle:varnish varnish
    docker build -t sqlfiddle:appDatabase appDatabase
    docker build -t sqlfiddle:hostMonitor hostMonitor
    docker build -t sqlfiddle:postgresql96Host postgresql96Host
    docker build -t sqlfiddle:postgresql93Host postgresql93Host
    docker build -t sqlfiddle:mysql56Host mysql56Host
    docker build -t sqlfiddle:mssql2017Host mssql2017Host
    docker build -t sqlfiddle:oracle11gHost oracle11gHost --shm-size 1G
    kubectl create namespace sqlfiddle
    kubectl --namespace sqlfiddle apply -f kubernetes

After you run the above command, you can open the site by visiting http://localhost:8080 . This port exposes the app via the varnish cache server.

### Optional: Oracle 11g R2 XE

If you want to include Oracle in your environment, you have to do some manual steps before you run the above commands (thanks Oracle!):

1) Download ojdbc6.jar from http://www.oracle.com/technetwork/database/enterprise-edition/jdbc-112010-090769.html
2) mkdir appServer/src/main/verticles/lib/ && cp ojdbc6.jar appServer/src/main/verticles/lib/
3) Download oracle-xe-11.2.0-1.0.x86_64.rpm.zip from http://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html
4) cp oracle-xe-11.2.0-1.0.x86_64.rpm.zip oracle11gHost


## To do development in a local environment, start with above and then:

*requires local install of Grunt*

    (cd appServer/target; grunt) &

You can directly access the app server by visiting http://localhost:8081 . This port bypasses the varnish cache server, which is necessary to see live changes made to the app server.

You can attach a debugger (for example, using IntelliJ) using port 5005.

Edits made to your webroot files will be redeployed to your docker container and visible immediately. Changes to verticles will require restarting the docker container to be seen.

Restart the app server docker container with this command:

    docker-compose restart appServer

## Setting up in Amazon Web Services

### Pre-installation software requirements specific to AWS

1) AWS command line tools

2) Vagrant (https://www.vagrantup.com) and the vagrant-aws plugin. See the plugin site here for details: https://github.com/mitchellh/vagrant-aws

3) ECS CLI: http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html

### Local setup

Build the application if you haven't done so already. This will prepare the docker images and the lambda package.

    (cd appServer/; mvn clean package)
    docker-compose build

Set your core env variables necessary for working with your AWS account:

    export REGION=your region (for example, us-west-2)
    export AVAILABILITY_ZONE=${REGION}a
    export AWS_ACCESS_KEY_ID=your access key
    export AWS_SECRET_ACCESS_KEY=your secret key
    export S3_BUCKET=globally-unique S3 bucket name
    export KEYPAIR=your ec2 keypair name
    export PATH_TO_KEYPAIR_PEM=full path to the above $KEYPAIR pem
    export APP_DATABASE_IP=10.1.0.16

### Commercial databases within AWS

If you are going to run Oracle, MS SQL Server, etc... you will have to have created pre-installed AMI images which have those installed and configured properly. First, follow the general instructions above for setting up each type, but do so within a Windows EC2 instance.

These AMIs need to be configured to call the "registerInstance" Lambda function when their database service is started. The best way to do that is to install the AWS command line tools (or PowerShell tools) and configure them with your account information. When the services start, schedule a task that will execute this lambda function. For example, in Windows PowerShell you could run a script like this:

    Invoke-LMFunction -FunctionName registerInstance -Payload '{ "type": "sqlserver2014" }'

And have that script get triggered when MSSQLSERVER produces an event like "SQL Server is now ready for client connections." See aws/registerSQLServer_on_startup.xml for full details on setting up this task in windows.

Save each instance as a distinct AMI after you have set it up properly.

If and when you have set up the commercial servers, specify the AMIs you created:

    export SQLSERVER2014_AMI=your sql server 2014 ami
    export ORACLE11G_AMI=your oracle11g ami

### Environment creation

Create your unique S3 bucket. This is used to store CloudFormation configuration, lambda function packages, and database backups.

    aws s3 mb s3://$S3_BUCKET

Upload Lambda function package to your S3 bucket:

    aws s3 cp appServer/target/sqlfiddle-lambda.zip \
        s3://$S3_BUCKET/sqlfiddle-lambda.zip

Start the CloudFormation stack to prepare the environment within which the servers will run:

![CloudFormation diagram](aws/cloudformation.png?raw=true)

    aws s3 cp aws/sqlfiddle.template s3://$S3_BUCKET/sqlfiddle.template
    aws cloudformation create-stack --stack-name sqlfiddle3 \
        --template-url "https://s3.amazonaws.com/${S3_BUCKET}/sqlfiddle.template" \
        --parameters \
            ParameterKey=SQLSERVER2014AMI,ParameterValue=$SQLSERVER2014_AMI \
            ParameterKey=ORACLE11GAMI,ParameterValue=$ORACLE11G_AMI \
            ParameterKey=APPDATABASEIP,ParameterValue=$APP_DATABASE_IP \
        --capabilities CAPABILITY_IAM

Monitor the status of the stack creation by using this command:

    aws cloudformation describe-stacks --stack-name sqlfiddle3

When this returns "StackStatus": "CREATE_COMPLETE", run these commands to get important details about your environment needed for later commands:

    export VPC_ID=`aws cloudformation describe-stack-resources \
        --stack-name sqlfiddle3 --logical-resource-id SQLFIDDLE \
        --query StackResources[0].PhysicalResourceId --output text`

    export SUBNET_ID_PUBLIC=`aws cloudformation describe-stack-resources \
        --stack-name sqlfiddle3 --logical-resource-id PUBLICPRIMARY \
        --query StackResources[0].PhysicalResourceId --output text`

    export SUBNET_ID_PUBLIC_ADDITIONAL=`aws cloudformation describe-stack-resources \
        --stack-name sqlfiddle3 --logical-resource-id PUBLICADDITIONAL \
        --query StackResources[0].PhysicalResourceId --output text`

    export SECURITY_GROUP_ID=`aws cloudformation describe-stack-resources \
        --stack-name sqlfiddle3 --logical-resource-id SECGROUP \
        --query StackResources[0].PhysicalResourceId --output text`

    export TARGET_GROUP_ARN=`aws cloudformation describe-stack-resources \
        --stack-name sqlfiddle3 --logical-resource-id TARGETGROUP \
        --query StackResources[0].PhysicalResourceId --output text`

Use vagrant to create a dedicated EC2 instance to run the persisted PostgreSQL appDatabase:

    (cd appDatabase; vagrant up --provider=aws)

This will also setup a daily full backup of the database to write to your S3 account (see appDatabase/vagrant_scripts/s3_backup.sh and s3cfg_template for details).

Create a new ECR repository to house your docker images ('sqlfiddle'):

    eval $(aws ecr get-login --region $REGION --no-include-email)
    export ECR_URI=`aws ecr create-repository --repository-name sqlfiddle \
        --query repository.repositoryUri --output text`

Upload the docker images to ECR:

    docker tag sqlfiddle:appServer $ECR_URI:appServer
    docker push $ECR_URI:appServer
    docker tag sqlfiddle:varnish $ECR_URI:varnish
    docker push $ECR_URI:varnish
    docker tag sqlfiddle:mysql56Host $ECR_URI:mysql56Host
    docker push $ECR_URI:mysql56Host
    docker tag sqlfiddle:postgresql93Host $ECR_URI:postgresql93Host
    docker push $ECR_URI:postgresql93Host
    docker tag sqlfiddle:postgresql96Host $ECR_URI:postgresql96Host
    docker push $ECR_URI:postgresql96Host
    docker tag sqlfiddle:mssql2017Host $ECR_URI:mssql2017Host
    docker push $ECR_URI:mssql2017Host

Pushing may take a long time. If it gets stalled out, use `docker-machine restart` between attempts

Configure your ecs-cli environment to work with this cluster:

    ecs-cli configure --region $REGION --access-key $AWS_ACCESS_KEY_ID \
        --secret-key $AWS_SECRET_ACCESS_KEY --cluster sqlfiddle3

Start the cluster with two t2.medium container instances, spread between the subnets:

    ecs-cli up --keypair $KEYPAIR -capability-iam --size 2 \
        --instance-type t2.medium --security-group $SECURITY_GROUP_ID \
        --vpc $VPC_ID --subnets $SUBNET_ID_PUBLIC,$SUBNET_ID_PUBLIC_ADDITIONAL --force

Bring the appServer instances up:

    ecs-cli compose --file aws/docker-compose-appServer.yml \
        --project-name appServer service up \
        --target-group-arn $TARGET_GROUP_ARN \
        --role ecsServiceRole --container-name varnish --container-port 8080

    ecs-cli compose --file aws/docker-compose-appServer.yml \
        --project-name appServer service scale 2

Get the DNS entry needed to access the cluster:

    export ELB_ARN=`aws cloudformation describe-stack-resources \
        --stack-name sqlfiddle3 --logical-resource-id ELB \
        --query StackResources[0].PhysicalResourceId --output text`

    aws elbv2 describe-load-balancers --load-balancer-arns $ELB_ARN \
        --query LoadBalancers[0].DNSName --output text

Use the output from that command to view the running application in your browser. For example,
    http://sqlfiddle3ELB-987654321.us-west-2.elb.amazonaws.com/

If you want a more friendly DNS entry, use Route 53 to host your domain and set the A record to have an alias target which points to the ELB DNSName returned above, or use a CNAME alias on a non-TLD record.

The site is now usable, but has no backend hosts available to execute queries (only SQLite will be available, since that runs in the browser). To get the backend hosts running, follow the next steps to start them up and register them within the "hosts" table of the appDatabase.

Bring the docker-based database services up:

    ecs-cli compose --file aws/docker-compose-mysql56.yml \
        --project-name mysql56 service up
    ecs-cli compose --file aws/docker-compose-postgresql93.yml \
        --project-name postgresql93 service up
    ecs-cli compose --file aws/docker-compose-postgresql96.yml \
        --project-name postgresql96 service up
    ecs-cli compose --file aws/docker-compose-mssql2017.yml \
        --project-name mssql2017 service up

Bring any commercial database servers that are running on EC2 hosts (not docker containers):

    aws lambda invoke --function-name 'runInstanceType' \
        --payload '{"type": "oracle11g"}' lambdaResults.json

    aws lambda invoke --function-name 'runInstanceType' \
        --payload '{"type": "sqlserver2014"}' lambdaResults.json

The various invocations of Lambda functions (either from EC2 or ECS) will result in the registration of each server within the "hosts" table running on the appDatabase server. Once registered there, they will be usable to the appServer instances which will be created next.

### Environment destruction

If you have created any EC2 instances for Oracle or SQL Server, terminate them manually.

To undo all of the above, run these commands:

    ecs-cli down --force
    (cd appDatabase; vagrant destroy)
    aws cloudformation delete-stack --stack-name sqlfiddle3
