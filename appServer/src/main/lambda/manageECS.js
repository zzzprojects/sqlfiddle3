var Promise = require('q');

exports.addTask = (event, context, callback) => {
    var AWS = require('aws-sdk'),
        ecs = new AWS.ECS({"apiVersion": '2014-11-13'}),
        cluster = process.env.CLUSTERNAME,
        serviceName = process.env.SERVICE;

    ecs.listTasks({ cluster, serviceName }, (err, data) => {
        ecs.updateService({
            desiredCount: data.taskArns.length+1,
            service: serviceName,
            cluster
        }, callback);
    });
};

/**
 * This lambda function is expected to be called from API Gateway
 * event is expected to have this structure:
 {
   "queryStringParameters": {
   "containerType": "mysql56Host"
   }
 }

environment variable "CLUSTERNAME" is expected to be set (e.g. sqlfiddle3)

Expected to be called when a new container is brought online or one is taken offline.
 */
exports.updateHostRegistry = (event, context, callback) => {
    var AWS = require('aws-sdk'),
        lambda = new AWS.Lambda({"apiVersion": '2015-03-31'}),
        cluster = process.env.CLUSTERNAME,
        containerType = event.queryStringParameters.containerType;

    this.getAllHostsForContainerType(cluster, containerType).then((hostConnections) => {
        lambda.invoke({
            FunctionName: "syncHosts",
            Payload: JSON.stringify({
                hostConnections,
                hostType: containerType
            })
        }, (err, data) => {
            callback(null, {
                "statusCode": 200,
                "headers": {},
                "body": data.Payload
            });
        });

    });
};


/**
 * @param {String} - cluster - name of the cluster to query, e.g. "sqlfiddle3"
 * @param {String} - containerType - name of the container to search for within the cluster
 * @returns {Promise} - promise resolved with a list of ip/port combinations found for this container name, like so:
    [
      {
        "port": 32769,
        "ip": "10.0.1.49"
      }
    ]
 *
 */
exports.getAllHostsForContainerType = (cluster, containerType) => {
    var AWS = require('aws-sdk'),
        ecs = new AWS.ECS({"apiVersion": '2014-11-13'}),
        ec2 = new AWS.EC2({"apiVersion": '2016-11-15'});

    return ecs.listTasks({ cluster }).promise()
    .then((taskList) => ecs.describeTasks({ cluster, tasks: taskList.taskArns }).promise())
    .then((taskDetails) => {
        var containersForName = taskDetails.tasks
            .filter((taskDetail) =>
                taskDetail.containers.filter(
                    (container) => container.name === containerType
                ).length > 0
            )
            .map((taskDetail) =>
                taskDetail.containers.map((container) => {
                    container.containerInstanceArn = taskDetail.containerInstanceArn;
                    return container;
                })
            )
            .reduce((final, containers) =>
                final.concat(containers)
            , []);

        return containersForName.length ? (ecs.describeContainerInstances({ cluster,
            containerInstances: containersForName.map(
                (containerDetails) => containerDetails.containerInstanceArn
            )
        }).promise()
        .then((containerInstanceList) => {

            containersForName.forEach((containerDetails) => {
                containerDetails.containerInstanceDetails = containerInstanceList.containerInstances.filter((instance) =>
                    instance.containerInstanceArn === containerDetails.containerInstanceArn
                )[0];
            });

            return ec2.describeInstances({
                InstanceIds: containerInstanceList.containerInstances.map((instance) =>
                    instance.ec2InstanceId
                )
            }).promise();
        })
        .then((instanceDetails) => {
            var instanceList = instanceDetails.Reservations.reduce(
                (final, res) => final.concat(res.Instances), []
            );

            containersForName.forEach((containerDetails) => {
                if (containerDetails.containerInstanceDetails) {
                    containerDetails.containerInstanceDetails.ec2Instance = instanceList.filter(
                        (instance) => instance.InstanceId === containerDetails.containerInstanceDetails.ec2InstanceId
                    )[0];
                }
            });
            return containersForName;
        })) : [];
    })
    .then(
        (containersForName) => containersForName.map(
            (container) => ({
                // assumes that this container has exactly one network binding
                port: container.networkBindings[0].hostPort,
                ip: container.containerInstanceDetails.ec2Instance.PrivateIpAddress
            })
        )
    );
};
