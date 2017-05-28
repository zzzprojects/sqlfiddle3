# SQL Fiddle, take 3 (or so?)

This version of the system is intended to make use of Docker for the different systems (app server, app database, fiddle databases, etc...)

It is also implemented with Vert.x in the application tier.

###Prerequisites for local build:

    Java 8+
    Maven 3.3+
    Docker 17+

To get running locally:

    $ cd appServer/ && mvn clean package && cd .. && docker-compose up -d

After you run the above command, you can open the site by visiting http://localhost:8080

If building on a Mac, be sure to prep docker first:

    $ docker-machine start
    $ eval $(docker-machine env)

Also, you'll have to access the site via the docker-machine ip address, like so:

    $ docker-machine ip
    192.168.99.101

Then you can access the site by visiting http://192.168.99.101:8080

## To do development in a local environment:

*requires local install of PostgreSQL, MySQL and Vert.x*

    $ cd appServer
    $ mvn clean package
    $ (cd target; grunt) &
    $ cd target/docker
    # next line is for connecting with a remote debugger such as IntelliJ
    $ export VERTX_OPTS='-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005'
    $ export CLASSPATH=.:lib/*
    $ vertx run sqlfiddle.groovy

## Commercial software requirements

If you want to run the commercial database software (Microsoft SQL Server 2014 Express, Oracle 11g R2 XE) you must have a Windows Server 2008 R2 (or higher) server available. The core software must be installed prior to attempting to use it with SQL Fiddle. Below are the requirements for how the commercial databases should be installed. The docker-compose file assumes this server is listening at ip address 192.168.99.101

### SQL Server 2014 Express

1) Don't use the "SQL Server Replication" Feature (leave the others checked)
2) Use the "Default instance" (leave the "Instance ID" as "MSSQLSERVER")
3) Authentication mode should be "Mixed"; "sa" password should be set to "SQLServerPassword"
4) Enable TCP/IP connections in the network configuration

### Oracle 11g R2 XE
1) "system" password should be set to "password"
2) Download ojdbc6.jar from here: http://www.oracle.com/technetwork/database/enterprise-edition/jdbc-112010-090769.html
3) Put ojdbc6.jar in appServer/src/main/verticles/lib before you run `mvn clean package`


## Setting up in Amazon Web Services

Install the AWS command line tools

Build the images if you haven't done the above:

    cd appServer/ && mvn clean package && cd .. && docker-compose build

Set your core env variables necessary for working with your AWS account:

    export REGION=your region (for example, us-west-2)
    export AWS_ACCESS_KEY_ID=your access key
    export AWS_SECRET_ACCESS_KEY=your secret key
    export KEYPAIR=your ec2 keypair name
    export PATH_TO_KEYPAIR_PEM=full path to the above $KEYPAIR pem
    export AWS_ACCOUNT_ID=`aws ec2 describe-security-groups \
        --query 'SecurityGroups[0].OwnerId' --output text`

Create a VPC to house the compute resources:

    export VPC_ID=`aws ec2 create-vpc --cidr-block 10.1.0.0/16 \
        --query Vpc.VpcId --output text`

    export IGW_ID=`aws ec2 create-internet-gateway \
        --query InternetGateway.InternetGatewayId --output text`

    aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

    export ROUTE_TABLE_ID_PUBLIC=`aws ec2 describe-route-tables \
        --filter Name=vpc-id,Values=$VPC_ID --query RouteTables[0].RouteTableId --output text`

    export SUBNET_ID_PUBLIC=`aws ec2 create-subnet --vpc-id $VPC_ID \
        --cidr-block 10.1.0.0/24 --availability-zone ${REGION}a \
        --query Subnet.SubnetId --output text`

    export SUBNET_ID_PUBLIC_ADDITIONAL=`aws ec2 create-subnet --vpc-id $VPC_ID \
        --cidr-block 10.1.2.0/24 --availability-zone ${REGION}c \
        --query Subnet.SubnetId --output text`

    aws ec2 associate-route-table --subnet-id $SUBNET_ID_PUBLIC \
        --route-table-id $ROUTE_TABLE_ID_PUBLIC

    aws ec2 associate-route-table --subnet-id $SUBNET_ID_PUBLIC_ADDITIONAL \
        --route-table-id $ROUTE_TABLE_ID_PUBLIC

    aws ec2 create-route --route-table-id $ROUTE_TABLE_ID_PUBLIC \
        --gateway-id $IGW_ID --destination-cidr-block 0.0.0.0/0

    export IP_ALLOCATION_ID=`aws ec2 allocate-address --domain vpc \
        --query AllocationId --output text`

    export ROUTE_TABLE_ID_PRIVATE=`aws ec2 create-route-table --vpc-id $VPC_ID \
        --query RouteTable.RouteTableId --output text`

    export SUBNET_ID_PRIVATE=`aws ec2 create-subnet --vpc-id $VPC_ID \
        --cidr-block 10.1.1.0/24 --availability-zone ${REGION}b \
        --query Subnet.SubnetId --output text`

    aws ec2 associate-route-table --subnet-id $SUBNET_ID_PRIVATE \
        --route-table-id $ROUTE_TABLE_ID_PRIVATE

    export NAT_GW_ID=`aws ec2 create-nat-gateway --subnet-id $SUBNET_ID_PUBLIC \
        --allocation-id $IP_ALLOCATION_ID --query NatGateway.NatGatewayId --output text`

Wait here a few moments. Creating the NAT Gateway takes some time

    aws ec2 create-route --route-table-id $ROUTE_TABLE_ID_PRIVATE \
        --gateway-id $NAT_GW_ID --destination-cidr-block 0.0.0.0/0

    export SECURITY_GROUP_ID=`aws ec2 create-security-group --vpc-id $VPC_ID \
        --group-name sqlfiddle_group --description "Rules for SQLFiddle Resources" \
        --query GroupId --output text`

    aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID \
        --protocol tcp --port 80 --cidr 0.0.0.0/0

    aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID \
        --protocol tcp --port 22 --cidr 0.0.0.0/0

    aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID \
        --cidr 10.1.0.0/16 --protocol all



Install Vagrant (https://www.vagrantup.com) and the vagrant-aws plugin. See the plugin site here for details: https://github.com/mitchellh/vagrant-aws

Use vagrant to create a dedicated EC2 instance to run the persisted PostgreSQL appDatabase:

    export APP_DATABASE_IP=10.1.0.16
    export AVAILABILITY_ZONE=${REGION}a
    (cd appDatabase; vagrant up --provider=aws)

This will also setup a daily full backup of the database to write to your S3 account (see appDatabase/vagrant_scripts/s3_backup.sh and s3cfg_template for details).

If there is already a backup of the sqlfiddle database stored in your S3 account, this will also automatically restore that backup into this new instance.

Create IAM roles for Lambda execution and ecs/ec2 scaling:

    aws iam create-instance-profile --instance-profile-name hostMaintenance

    export HOST_MAINTENANCE_ROLE_ARN=`aws iam create-role --role-name hostMaintenance \
      --assume-role-policy-document file://aws/iam_trust_policy.json \
      --query Role.Arn --output text`

    aws iam put-role-policy --role-name hostMaintenance \
      --policy-name hostMaintenance --policy-document file://aws/iam_policy.json

    aws iam add-role-to-instance-profile \
      --instance-profile-name hostMaintenance \
      --role-name hostMaintenance

Create Lambda functions which will register your host database servers and keep them fresh:

    aws lambda create-function --function-name addTask \
        --runtime nodejs6.10 --role $HOST_MAINTENANCE_ROLE_ARN \
        --handler manageECS.addTask --timeout 10 \
        --environment Variables="{CLUSTERNAME=sqlfiddle3}" \
        --zip-file fileb://appServer/target/sqlfiddle-lambda.zip

    aws lambda create-function --function-name deleteTask \
        --runtime nodejs6.10 --role $HOST_MAINTENANCE_ROLE_ARN \
        --handler manageECS.deleteTask --timeout 10 \
        --environment Variables="{CLUSTERNAME=sqlfiddle3}" \
        --zip-file fileb://appServer/target/sqlfiddle-lambda.zip

    aws lambda create-function --function-name checkForOverusedHosts \
        --runtime nodejs6.10 --role $HOST_MAINTENANCE_ROLE_ARN \
        --handler hostMaintenance.checkForOverusedHosts --timeout 10 \
        --environment Variables="{postgresHost=$APP_DATABASE_IP,postgresUser=postgres,postgresPassword=password,MAX_SCHEMAS_PER_HOST=100}" \
        --zip-file fileb://appServer/target/sqlfiddle-lambda.zip \
        --vpc-config SubnetIds=$SUBNET_ID_PRIVATE,SecurityGroupIds=$SECURITY_GROUP_ID

    aws lambda create-function --function-name syncHosts \
        --runtime nodejs6.10 --role $HOST_MAINTENANCE_ROLE_ARN \
        --handler hostMaintenance.syncHosts --timeout 10 \
        --environment Variables="{postgresHost=$APP_DATABASE_IP,postgresUser=postgres,postgresPassword=password}" \
        --zip-file fileb://appServer/target/sqlfiddle-lambda.zip \
        --vpc-config SubnetIds=$SUBNET_ID_PRIVATE,SecurityGroupIds=$SECURITY_GROUP_ID

    export LAMBDA_ARN=`aws lambda create-function --function-name updateHostRegistry \
        --runtime nodejs6.10 --role $HOST_MAINTENANCE_ROLE_ARN \
        --handler manageECS.updateHostRegistry --timeout 10 \
        --environment Variables="{CLUSTERNAME=sqlfiddle3}" \
        --zip-file fileb://appServer/target/sqlfiddle-lambda.zip \
        --query FunctionArn --output text`

Create an API Gateway interface to the above Lambda function (updateHostRegistry):

    export API_GATEWAY_ID=`aws apigateway create-rest-api --name SQLFiddleLambda \
      --query id --output text`

    export API_ROOT_RESOURCE_ID=`aws apigateway get-resources \
      --rest-api-id $API_GATEWAY_ID --query items[0].id --output text`

    export API_RESOURCE_ID=`aws apigateway create-resource \
      --rest-api-id $API_GATEWAY_ID \
      --parent-id $API_ROOT_RESOURCE_ID --path 'updateHostRegistry' \
      --query id --output text`

    aws apigateway put-method --rest-api-id $API_GATEWAY_ID \
      --resource-id $API_RESOURCE_ID \
      --http-method GET \
      --authorization-type NONE

    aws apigateway put-integration --rest-api-id $API_GATEWAY_ID \
      --resource-id $API_RESOURCE_ID \
      --http-method GET \
      --type AWS_PROXY \
      --integration-http-method POST \
      --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations

    aws apigateway put-integration-response --rest-api-id $API_GATEWAY_ID \
      --resource-id $API_RESOURCE_ID \
      --http-method GET --status-code 200 --selection-pattern ".*"

    aws apigateway create-deployment --rest-api-id $API_GATEWAY_ID --stage-name prod

    aws lambda add-permission \
        --function-name $LAMBDA_ARN \
        --statement-id updateHostRegistryPermission \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "arn:aws:execute-api:$REGION:$AWS_ACCOUNT_ID:$API_GATEWAY_ID/prod/*/updateHostRegistry"

    aws lambda add-permission \
        --function-name $LAMBDA_ARN \
        --statement-id updateHostRegistryPermissionTest \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "arn:aws:execute-api:$REGION:$AWS_ACCOUNT_ID:$API_GATEWAY_ID/*/*/updateHostRegistry"

    export LAMBDA_NOTIFICATION_URL="https://$API_GATEWAY_ID.execute-api.$REGION.amazonaws.com/prod/updateHostRegistry"

Create a new ECR repository ('sqlfiddle'):

    eval $(aws ecr get-login --region $REGION)
    export ECR_URI=`aws ecr create-repository --repository-name sqlfiddle \
      --query repository.repositoryUri --output text`

Upload the docker images to ECR:

    docker tag sqlfiddle:appServer $ECR_URI:appServer && docker push $ECR_URI:appServer
    docker tag sqlfiddle:mysql56Host $ECR_URI:mysql56Host && docker push $ECR_URI:mysql56Host
    docker tag sqlfiddle:postgresql93Host $ECR_URI:postgresql93Host && docker push $ECR_URI:postgresql93Host

Pushing may take a long time. If it gets stalled out, use `docker-machine restart` between attempts

Install the ECS CLI: http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html

Configure your ecs-cli environment to work with this cluster:

    ecs-cli configure --region $REGION --access-key $AWS_ACCESS_KEY_ID \
      --secret-key $AWS_SECRET_ACCESS_KEY --cluster sqlfiddle3

Start the cluster with two t2.medium container instances, spread between the subnets:

    ecs-cli up --keypair $KEYPAIR -capability-iam --size 2 \
      --instance-type t2.medium --security-group $SECURITY_GROUP_ID \
      --vpc $VPC_ID --subnets $SUBNET_ID_PUBLIC,$SUBNET_ID_PUBLIC_ADDITIONAL --force

Bring the database services up:

    ecs-cli compose --file aws/docker-compose-mysql56.yml \
      --project-name mysql56 service up
    ecs-cli compose --file aws/docker-compose-postgresql93.yml \
      --project-name postgresql93 service up

When these come online, they will issue a request to the above Lambda function (updateHostRegistry), registering themselves within the "hosts" table running on the appDatabase server. Once registered there, they will be usable to the appServer instances which will be created next.

Create an Application Load Balancer to access the appServer services:

    export ELB_ARN=`aws elbv2 create-load-balancer --name sqlfiddle3ELB \
      --subnets $SUBNET_ID_PUBLIC $SUBNET_ID_PUBLIC_ADDITIONAL \
      --security-groups $SECURITY_GROUP_ID \
      --query LoadBalancers[0].LoadBalancerArn --output text`

    export TARGET_GROUP_ARN=`aws elbv2 create-target-group \
      --name appServerGroup --protocol HTTP --port 80 --vpc-id $VPC_ID \
      --query TargetGroups[0].TargetGroupArn --output text`

    aws elbv2 create-listener --load-balancer-arn $ELB_ARN \
      --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
      --protocol HTTP --port 80

Bring the appServer instances up:

    ecs-cli compose --file aws/docker-compose-appServer.yml \
      --project-name appServer service up \
      --target-group-arn $TARGET_GROUP_ARN \
      --role ecsServiceRole --container-name appServer --container-port 8080

    ecs-cli compose --file aws/docker-compose-appServer.yml \
      --project-name appServer service scale 2

Get the DNS entry needed to access the cluster:

    aws elbv2 describe-load-balancers --load-balancer-arns $ELB_ARN \
       --query LoadBalancers[0].DNSName --output text

Use the output from that command to view the running application in your browser. For example,
 http://sqlfiddle3ELB-987654321.us-west-2.elb.amazonaws.com/

If you want a more friendly DNS entry, use Route 53 to host your domain and set the A record to have an alias target which points to the ELB DNSName returned above, or use a CNAME alias on a non-TLD record.
