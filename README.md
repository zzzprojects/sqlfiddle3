# SQL Fiddle, version 3

**A tool for easy online testing and sharing of database problems and their solutions.**

This is the complete source code and management configuration for the site running at http://sqlfiddle.com

This is an open source project made available via the MIT license. Every dependency (except for the commercial databases, which are optional) is also open source.

Contributions are welcome!

## Running SQL Fiddle

This version of the site is built using Docker, designed to run within Kubernetes.

The application server is implemented with Vert.x.

### Software required to build SQL Fiddle

You will need these installed locally to build the project:

    Java 8+
    Maven 3.3+
    Docker 17+

### Preparing a local Kubernetes environment

The project is designed to run within any Kubernetes environment. One such environment is Minikube, which is useful for doing local development and evaluation. Review the Minikube installation instructions here if this is your chosen Kubernetes environment:

    https://kubernetes.io/docs/tasks/tools/install-minikube/

If you want to run all of the database services, you will probably need at least 8GB of memory for Kubernetes. Here's how you would configure Minikube with 8GB of memory:

    minikube start --insecure-registry 10.0.0.0/24 --memory 8192

If you are using Minikube, it is convenient to use the docker daemon which comes with it for publishing the container images. Setup your docker environment to do so with this command:

    eval $(minikube docker-env)

### Building Docker images

#### Preliminary steps for Oracle 11g XE
If you want to include Oracle 11g XE in your environment, you have to do some manual steps first (*thanks Oracle!*):

1. Download ojdbc6.jar from http://www.oracle.com/technetwork/database/enterprise-edition/jdbc-112010-090769.html
2. `mkdir appServer/src/main/verticles/lib/ && cp ojdbc6.jar appServer/src/main/verticles/lib/`
3. Download oracle-xe-11.2.0-1.0.x86_64.rpm.zip from http://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html
4. `cp oracle-xe-11.2.0-1.0.x86_64.rpm.zip oracle11gHost`

Finally you can issue the Docker build command necessary to create the image:

    docker build -t sqlfiddle:oracle11gHost oracle11gHost

#### Docker build commands

You can build the remaining container images with these commands:

    (cd appServer/; mvn clean package)
    docker build -t sqlfiddle:varnish varnish
    docker build -t sqlfiddle:appDatabase appDatabase
    docker build -t sqlfiddle:hostMonitor hostMonitor
    docker build -t sqlfiddle:mysql56Host mysql56Host
    docker build -t sqlfiddle:postgresql96Host postgresql96Host
    docker build -t sqlfiddle:postgresql93Host postgresql93Host
    docker build -t sqlfiddle:mssql2017Host mssql2017Host

If you are using Minikube and have setup the docker environment as mentioned above, you don't need to take any more steps to make these images available to your Kubernetes environment. If you are using some other Kubernetes service, then you will need to publish those images to whichever container registry necessary for your Kubernetes service to read them.

### Starting Kubernetes services

You will need to have `kubectl` installed before running these commands. If you installed Minikube then it should already be available. Otherwise just make sure you have it installed and configured to refer to your Kubernetes environment.

Once the container images are available to Kubernetes (from the above steps), run these commands to start up the SQL Fiddle services:

    kubectl create namespace sqlfiddle
    kubectl --namespace sqlfiddle apply -f kubernetes/appdatabase.yml
    kubectl --namespace sqlfiddle apply -f kubernetes/appservers.yml
    kubectl --namespace sqlfiddle apply -f kubernetes/hostmonitor.yml

You can then choose which host databases you would like to work with, using any of these commands:

    kubectl --namespace sqlfiddle apply -f kubernetes/mysql56.yml

    kubectl --namespace sqlfiddle apply -f kubernetes/postgresql96.yml

    kubectl --namespace sqlfiddle apply -f kubernetes/postgresql93.yml

    kubectl --namespace sqlfiddle apply -f kubernetes/mssql2017.yml

    kubectl --namespace sqlfiddle apply -f kubernetes/oracle11g.yml

### Accessing your running instance

Use a browser to access the site via the Kubernetes ingress service. You can find the IP address necessary to access the site using this command:

    kubectl --namespace sqlfiddle describe ing

You can expect output like so:

    Name:             ingress
    Namespace:        sqlfiddle
    Address:          192.168.99.100
    Default backend:  appserver-service:80 (172.17.0.11:8080,172.17.0.2:8080)
    Rules:
      Host  Path  Backends
      ----  ----  --------
      *     *     appserver-service:80 (172.17.0.11:8080,172.17.0.2:8080)
    ....    

Use the value for "Address" as the host name for your URL. For example, based on the above sample output you could access the running instance at http://192.168.99.100/
