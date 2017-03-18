# SQL Fiddle, take 3 (or so?)

This version of the system is intended to make use of Docker for the different systems (app server, app database, fiddle databases, etc...)

It is also implemented with Vert.x in the application tier.

To get running:

    cd appServer/ && mvn clean package && cd .. && docker-compose up -d

If building on a Mac, be sure to prep docker first:

    docker-machine start
    eval $(docker-machine env)

## Setting up in Amazon ECS

Build the images if you haven't done the above:

    cd appServer/ && mvn clean package && cd .. && docker-compose build

Create a new ECR repository ('sqlfiddle') at https://console.aws.amazon.com/ecs/home#/repositories

Set your env variables:

    export REGION=us-west-2
    export AWS_ACCESS_KEY_ID=your access key
    export AWS_SECRET_ACCESS_KEY=your secret key
    export ECR_URI=URI for the repository you just created, above

Upload the images to ECR)

    eval $(aws ecr get-login --region $REGION)
    docker tag sqlfiddle:appDatabase $ECR_URI:appDatabase && docker push $ECR_URI:appDatabase
    docker tag sqlfiddle:appServer $ECR_URI:appServer && docker push $ECR_URI:appServer
    docker tag sqlfiddle:mysql56Host $ECR_URI:mysql56Host && docker push $ECR_URI:mysql56Host
    docker tag sqlfiddle:postgresql93Host $ECR_URI:postgresql93Host && docker push $ECR_URI:postgresql93Host

Pushing may take a long time. If it gets stalled out, use `docker-machine restart` between attempts

Install the ECS CLI: http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html

    ecs-cli configure --region $REGION --access-key $AWS_ACCESS_KEY_ID --secret-key $AWS_SECRET_ACCESS_KEY --cluster sqlfiddle3
    ecs-cli up --keypair $KEYPAIR -capability-iam --size 2 --instance-type t2.medium
    ecs-cli compose --file docker-compose-ecs.yml up
    ecs-cli ps

Make note of the output from the last command. One line will be for "appServer". The ip address shown in the "ports" column is the address you can use to access this instance of the service. Open it in your browser and you should see it running.

To remove the service, run this command:

    ecs-cli down --force

## To do development in a local environment:

*requires local install of PostgreSQL, MySQL and Vert.x*

    cd appServer/
    mvn clean package
    grunt &
    cd target/docker
    # next line is for connecting with a remote debugger such as IntelliJ
    export VERTX_OPTS='-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005'
    CLASSPATH=".:lib/*" vertx run sqlfiddle.groovy
