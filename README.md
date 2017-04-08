# SQL Fiddle, take 3 (or so?)

This version of the system is intended to make use of Docker for the different systems (app server, app database, fiddle databases, etc...)

It is also implemented with Vert.x in the application tier.

To get running:

    cd appServer/ && mvn clean package && cd .. && docker-compose up -d

If building on a Mac, be sure to prep docker first:

    docker-machine start
    eval $(docker-machine env)


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


## Setting up in Amazon ECS

Build the images if you haven't done the above:

    cd appServer/ && mvn clean package && cd .. && docker-compose build

Create a new ECR repository ('sqlfiddle') at https://console.aws.amazon.com/ecs/home#/repositories

Set your env variables:

    export REGION=us-west-2
    export AWS_ACCESS_KEY_ID=your access key
    export AWS_SECRET_ACCESS_KEY=your secret key
    export ECR_URI=URI for the repository you just created, above
    export KEYPAIR=your ec2 keypair

Upload the images to ECR)

    eval $(aws ecr get-login --region $REGION)
    docker tag sqlfiddle:appDatabase $ECR_URI:appDatabase && docker push $ECR_URI:appDatabase
    docker tag sqlfiddle:appServer $ECR_URI:appServer && docker push $ECR_URI:appServer
    docker tag sqlfiddle:mysql56Host $ECR_URI:mysql56Host && docker push $ECR_URI:mysql56Host
    docker tag sqlfiddle:postgresql93Host $ECR_URI:postgresql93Host && docker push $ECR_URI:postgresql93Host

Pushing may take a long time. If it gets stalled out, use `docker-machine restart` between attempts

Install the ECS CLI: http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html

    ecs-cli configure --region $REGION --access-key $AWS_ACCESS_KEY_ID --secret-key $AWS_SECRET_ACCESS_KEY --cluster sqlfiddle3
    ecs-cli up --keypair $KEYPAIR -capability-iam --size 1 --instance-type t2.medium
    ecs-cli compose --file docker-compose-ecs.yml up
    ecs-cli ps

Make note of the output from the last command. One line will be for "appServer". The ip address shown in the "ports" column is the address you can use to access this instance of the service. Open it in your browser and you should see it running.

To remove the service, run this command:

    ecs-cli down --force

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
