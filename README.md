# SQL Fiddle, version 3

**A tool for easy online testing and sharing of database problems and their solutions.**

This is the complete source code and management configuration for the site running at http://sqlfiddle.com

This is an open source project made available via the MIT license. Every dependency (except for the commercial databases, which are optional) is also open source.

Contributions are welcome!

## Running SQL Fiddle

This version of the site is built using Docker, designed to run within Kubernetes using Helm.

The application server is implemented with Vert.x.

If you have installed Helm and Kubernetes is setup properly, you can launch the core system without even having to clone this project. Just run these commands:

    helm repo add sqlfiddle https://jakefeasel.github.io/sqlfiddle3/charts/
    kubectl create namespace sqlfiddle
    helm install sqlfiddle/sqlfiddleOpenCore

After running this command, your copy of the site will be running in your kubernetes environment.

### Software required for building

You will need Docker installed to build the project. You need kubectl and helm if you want to run it. If you want to run it locally, you need Minikube.

### Preparing a local Kubernetes environment

The project is designed to run within any Kubernetes environment. One such environment is Minikube, which is useful for doing local development and evaluation. Review the Minikube installation instructions here if this is your chosen Kubernetes environment:   

    https://kubernetes.io/docs/tasks/tools/install-minikube/

You will probably need at least 8GB of memory for Kubernetes. Here's how you would configure Minikube with 8GB of memory:

    minikube start --insecure-registry 10.0.0.0/24 --memory 8192

If you are using Minikube, it is convenient to use the docker daemon which comes with it for publishing the container images. Setup your docker environment to do so with this command:

    eval $(minikube docker-env)

You also need to enable the "ingress" addon, like so:

    minikube addons enable ingress

Finally, initialize helm:

    helm init

### Building Docker images

You can build the container images with these commands:

    docker build -t sqlfiddle/appservercore:latest appServerCore
    docker build -t sqlfiddle/varnish:latest varnish
    docker build -t sqlfiddle/appdatabase:latest appDatabase
    docker build -t sqlfiddle/hostmonitor:latest hostMonitor
    docker build -t sqlfiddle/mysql56host:latest mysql56Host
    docker build -t sqlfiddle/postgresql96host:latest postgresql96Host
    docker build -t sqlfiddle/postgresql93host:latest postgresql93Host
    docker build -t sqlfiddle/mssql2017host:latest mssql2017Host

#### Extra steps necessary for Oracle 11g XE
If you want to include Oracle 11g XE in your environment, you have to do some manual steps first (*thanks Oracle!*):

1. Download ojdbc6.jar from http://www.oracle.com/technetwork/database/enterprise-edition/jdbc-112010-090769.html
2. `cp ojdbc6.jar appServerExtended/`
3. Download oracle-xe-11.2.0-1.0.x86_64.rpm.zip from http://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html
4. `cp oracle-xe-11.2.0-1.0.x86_64.rpm.zip oracle11gHost`

Finally you can issue these Docker build commands to make the Oracle-extended versions:

    docker build -t sqlfiddle/appserverextended:latest appServerExtended
    docker build -t sqlfiddle/oracle11ghost:latest oracle11gHost

If you are using Minikube and have setup the docker environment as mentioned above, you don't need to take any more steps to make these images available to your Kubernetes environment. If you are using some other Kubernetes service, then you will need to publish those images to whichever container registry necessary for your Kubernetes service to read them.

### Publishing to a custom docker registry

Use these commands to publish the local builds of your containers to a remote registry. This is necessary when you are using something other than Minikube as your Kubernetes host. Be sure that the registry you are pushing into is available to your Kubernetes instance. Also be sure not to redistribute commercial software to a public location, as you will probably be violating copyright terms.

    docker tag sqlfiddle/appserverextended:latest $EXTERNAL_REGISTRY/appserverextended:latest
    docker push $EXTERNAL_REGISTRY/appserverextended:latest
    docker tag sqlfiddle/oracle11ghost:latest $EXTERNAL_REGISTRY/oracle11ghost:latest
    docker push $EXTERNAL_REGISTRY/oracle11ghost:latest
    docker tag sqlfiddle/mssql2017host:latest $EXTERNAL_REGISTRY/mssql2017host:latest
    docker push $EXTERNAL_REGISTRY/mssql2017host:latest

Be sure to configure your sqlfiddleCommercialExtension helm chart to use $EXTERNAL_REGISTRY as the value for registryPrefix.

### Starting Kubernetes services

Note that it is expected that in production, you would use an external PostgreSQL service (such as AWS RDS) to run the appDatabase. The "isLocal" switch in the helm charts is used to switch between an externally-hosted appDatabase and one running in a container.

You will need to have `helm` and `kubectl` installed before running these commands. If you installed Minikube then kubectl should already be available. Otherwise just make sure you have it installed and configured to refer to your Kubernetes environment.

Once the container images are available to Kubernetes (from the above steps), run these commands to start up the SQL Fiddle services:

    kubectl create namespace sqlfiddle
    helm install sqlfiddleOpenCore

To run the commercial software, use these commands instead:

    kubectl create namespace sqlfiddle
    helm install sqlfiddleCommercialExtension

This will bring the site up with SQL Server and Oracle running too.

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

### Development tips

When doing development locally in Minikube, you can make changes faster by providing a local NFS server on your host machine (the environment in which you are making changes). Change your helm chart values to specify your NFS server IP (by default, 192.168.99.1) and filesystem path. When the NFS server is specified, the helm chart will include a volume mount to your NFS path and will launch "grunt" within the container to watch for changes. This allows you to make changes to the appserver without having to rebuild / redeploy the container.
