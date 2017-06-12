var Q = require('q');

exports.addTask = (event, context, callback) => {
    var AWS = require('aws-sdk'),
        ecs = new AWS.ECS({"apiVersion": '2014-11-13'}),
        cluster = process.env.CLUSTERNAME,
        serviceName = event.serviceName;

    ecs.listTasks({ cluster, serviceName }, (err, data) => {
        ecs.updateService({
            desiredCount: data.taskArns.length+1,
            service: serviceName,
            cluster
        }, callback);
    });
};


/*
  Deletes a particular task and adjusts the service so that
  it won't create a new one in its place.
*/
exports.deleteTask = (event, context, callback) => {
    var AWS = require('aws-sdk'),
        ecs = new AWS.ECS({"apiVersion": '2014-11-13'}),
        cluster = process.env.CLUSTERNAME,
        task = event.taskArn;

    /*
     Terrible, but the only way to find the service associated with
     the given taskArn is to list all services and then issue
     separate "listTasks" commands for each of them, only to filter
     them down to the one which actually has the given taskArn.
    */
    ecs.listServices({cluster}).promise()
    .then((services) =>
        Q.all(services.serviceArns.map((serviceName) =>
            ecs.listTasks({ cluster, serviceName }).promise()
            .then((data) => ({ serviceName, taskArns: data.taskArns }))
        ))
    )
    .then((serviceTasks) => serviceTasks.filter(
        (st) => st.taskArns.filter(
            (taskArn) => taskArn === task
        ).length
    ))
    .then((serviceTasks) =>
        serviceTasks.length === 1 ?
            Q.all([
                ecs.stopTask({ cluster, task }).promise(),
                ecs.updateService({
                    cluster,
                    service: serviceTasks[0].serviceName,
                    desiredCount: serviceTasks[0].taskArns.length-1,
                }).promise()
            ]) : null
    )
    .then((result) => callback(null, result));
};

/**
 * This lambda function is expected to be called from API Gateway
 * event is expected to have the value of a taskDefinitionArn, like so:

"arn:aws:ecs:us-west-2:321080263678:task-definition/ecscompose-mysql56:6"

environment variable "CLUSTERNAME" is expected to be set (e.g. sqlfiddle3)

Expected to be called when a new task is brought online or one is taken offline.
 */
exports.updateHostRegistry = (event, context, callback) => {
    var AWS = require('aws-sdk'),
        lambda = new AWS.Lambda({"apiVersion": '2015-03-31'}),
        cluster = process.env.CLUSTERNAME,
        taskDefinitionArn = event,
        serviceName = taskDefinitionArn.split('/').slice(-1)[0].split(":")[0];

    this.getAllHostsForContainerType(cluster, taskDefinitionArn)
    .then((hostConnections) =>
        lambda.invoke({
            FunctionName: "syncHosts",
            Payload: JSON.stringify({
                hostConnections,
                hostType: serviceName
            })
        }).promise()
    )
    .then((data) =>
        callback(null, data)
    );
};


/**
 * @param {String} - cluster - name of the cluster to query, e.g. "sqlfiddle3"
 * @param {String} - taskDefinitionArn - arn of the taskDefinition to search for within the cluster
 * @returns {Promise} - promise resolved with a list of ip/port combinations found for this container name, like so:
    [
      {
        "connection_meta": "{\"type\":\"ecs\",\"taskArn\":\"arn:aws:ecs:u..\"}",
        "port": 32769,
        "ip": "10.0.1.49"
      }
    ]
 *
 */
exports.getAllHostsForContainerType = (cluster, taskDefinitionArn) => {
    var AWS = require('aws-sdk'),
        ecs = new AWS.ECS({"apiVersion": '2014-11-13'}),
        ec2 = new AWS.EC2({"apiVersion": '2016-11-15'});

    return ecs.listTasks({ cluster }).promise()
    .then((taskList) => ecs.describeTasks({ cluster, tasks: taskList.taskArns }).promise())
    .then((taskDetails) => {
        var containersForName = taskDetails.tasks
            .filter((taskDetail) =>
                taskDetail.taskDefinitionArn === taskDefinitionArn
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
                connection_meta: JSON.stringify({
                    type: "ecs",
                    taskArn: container.taskArn
                }),
                // assumes that this container has exactly one network binding
                port: container.networkBindings[0].hostPort,
                ip: container.containerInstanceDetails.ec2Instance.PrivateIpAddress
            })
        )
    );
};
